import { AppUsageInfo } from '../model/AppUsageInfo';
import { TimeGranularity } from '../model/AppUsageInfo';
import { SortResult } from '../model/SortResult';
import { TrendPoint, DailyAgg } from '../model/Types';
import { UsageAnalyzer } from './UsageAnalyzer';

const TAG = 'AppDataService';

/** 报告里的单个应用条目 */
interface ReportApp {
  name: string;
  bundleName: string;
  score: number;
  totalTime: number;
  launchCount: number;
}

/** 报告摘要 */
interface ReportSummary {
  totalApps: number;
  highFrequency: number;
  mediumFrequency: number;
  lowFrequency: number;
}

/** JSON 报告整体结构 */
interface UsageReport {
  generatedAt: string;
  summary: ReportSummary;
  highFrequencyApps: ReportApp[];
  mediumFrequencyApps: ReportApp[];
  lowFrequencyApps: ReportApp[];
}

/**
 * 应用数据服务
 * 负责数据的缓存、趋势分析和报告生成
 */
export class AppDataService {
  private static instance: AppDataService;

  // 内存缓存
  private cache: Map<string, SortResult> = new Map();
  private cacheTime: Map<string, number> = new Map();
  private readonly CACHE_TTL: number = 5 * 60 * 1000; // 缓存5分钟

  private constructor() {}

  public static getInstance(): AppDataService {
    if (!AppDataService.instance) {
      AppDataService.instance = new AppDataService();
    }
    return AppDataService.instance;
  }

  /**
   * 获取分析结果（带缓存）
   */
  async getAnalysisResult(analyzer: UsageAnalyzer, granularity: TimeGranularity): Promise<SortResult> {
    const cacheKey: string = granularity.toString();
    const cached: SortResult | undefined = this.cache.get(cacheKey);
    const cachedTime: number = this.cacheTime.get(cacheKey) ?? 0;

    if (cached !== undefined && (Date.now() - cachedTime) < this.CACHE_TTL) {
      console.info(TAG, `命中缓存: ${cacheKey}`);
      return cached;
    }

    const result: SortResult = await analyzer.analyze(granularity);
    this.cache.set(cacheKey, result);
    this.cacheTime.set(cacheKey, Date.now());
    return result;
  }

  /**
   * 清除缓存
   */
  clearCache(): void {
    this.cache.clear();
    this.cacheTime.clear();
    console.info(TAG, '缓存已清除');
  }

  /**
   * 【模拟数据】获取单条应用的使用趋势
   *
   * 真实实现需要 usageStatistics.queryBundleStatsInfos 按天查询，公开 SDK 不可用。
   * 用包名做种子生成确定性曲线，保证同一应用每次进详情页看到的趋势一致。
   */
  async getAppTrend(bundleName: string, days: number = 7): Promise<TrendPoint[]> {
    const dayMs: number = 24 * 60 * 60 * 1000;
    const endTime: number = Date.now();

    // 用包名字符和累加做一个简单散列，作为伪随机种子
    let seed: number = 0;
    for (let i = 0; i < bundleName.length; i++) {
      seed = (seed * 31 + bundleName.charCodeAt(i)) % 100000;
    }

    const points: TrendPoint[] = [];
    for (let i = days - 1; i >= 0; i--) {
      const d: Date = new Date(endTime - i * dayMs);
      const key: string = `${d.getMonth() + 1}/${d.getDate()}`;

      const mix: number = (seed + i * 7919) % 97;
      const agg: DailyAgg = {
        time: Math.round((mix / 97) * 90 * 60 * 1000),  // 0 ~ 90 分钟
        count: Math.round((mix % 13) + 1)
      };

      const p: TrendPoint = { date: key, time: agg.time, count: agg.count };
      points.push(p);
    }
    return points;
  }

  /**
   * 生成桌面整理建议文本
   */
  generateSuggestionText(result: SortResult): string {
    let text: string = '📱 桌面整理建议\n\n';

    text += '🔥 高频应用（建议放首页）\n';
    const high: AppUsageInfo[] = result.highFrequencyApps.slice(0, 10);
    for (let i = 0; i < high.length; i++) {
      text += `${i + 1}. ${high[i].appName} (${high[i].activityScore}分)\n`;
    }

    text += '\n📁 中频应用（建议放文件夹）\n';
    const medium: AppUsageInfo[] = result.mediumFrequencyApps.slice(0, 10);
    for (let i = 0; i < medium.length; i++) {
      text += `${i + 1}. ${medium[i].appName} (${medium[i].activityScore}分)\n`;
    }

    text += '\n💤 低频应用（可考虑隐藏）\n';
    const low: AppUsageInfo[] = result.lowFrequencyApps.slice(0, 5);
    for (let i = 0; i < low.length; i++) {
      text += `${i + 1}. ${low[i].appName} (${low[i].activityScore}分)\n`;
    }

    return text;
  }

  /**
   * 生成 JSON 格式的分析报告
   */
  generateJSONReport(result: SortResult): string {
    const summary: ReportSummary = {
      totalApps: result.totalApps,
      highFrequency: result.highFrequencyApps.length,
      mediumFrequency: result.mediumFrequencyApps.length,
      lowFrequency: result.lowFrequencyApps.length
    };

    const report: UsageReport = {
      generatedAt: new Date().toISOString(),
      summary: summary,
      highFrequencyApps: AppDataService.toReportApps(result.highFrequencyApps),
      mediumFrequencyApps: AppDataService.toReportApps(result.mediumFrequencyApps),
      lowFrequencyApps: AppDataService.toReportApps(result.lowFrequencyApps)
    };
    return JSON.stringify(report);
  }

  /**
   * AppUsageInfo[] -> ReportApp[]
   */
  private static toReportApps(apps: AppUsageInfo[]): ReportApp[] {
    const out: ReportApp[] = [];
    for (let i = 0; i < apps.length; i++) {
      const a: AppUsageInfo = apps[i];
      const item: ReportApp = {
        name: a.appName,
        bundleName: a.bundleName,
        score: a.activityScore,
        totalTime: a.totalTimeInForeground,
        launchCount: a.launchCount
      };
      out.push(item);
    }
    return out;
  }
}
