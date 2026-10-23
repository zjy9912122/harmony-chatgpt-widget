import { AppUsageInfo, UsageCategory, TimeGranularity } from '../model/AppUsageInfo';
import { SortResult } from '../model/SortResult';
import { AppMeta, UsageStat, TimeRange, WeightConfig, ThresholdConfig } from '../model/Types';
import { DateUtil } from '../utils/DateUtil';
import { PreferenceService } from '../service/PreferenceService';
import { common } from '@kit.AbilityKit';

const TAG = 'UsageAnalyzer';

/**
 * 应用使用分析引擎
 *
 * 核心算法（时长 / 启动次数 / 最近使用 / 一致性 四维加权评分）是真实的，
 * 仅数据源为模拟。
 *
 * 为什么用模拟数据：HarmonyOS 公开 SDK 不提供这两项能力
 *   1. @ohos.resourceschedule.usageStatistics 的 namespace 是空的（无任何成员）
 *   2. bundleManager 没有 getAllApplicationInfo / getAllBundleInfo，无法枚举已装应用
 * 二者均属 system_basic 级能力，需要系统签名，第三方应用拿不到。
 * 若将来拿到系统权限，只需替换 fetchInstalledApps() 和 fetchUsageStats() 两个方法，
 * 它们的返回类型 AppMeta[] / UsageStat[] 已对齐系统 API 的字段。
 */
export class UsageAnalyzer {
  private static instance: UsageAnalyzer;

  // 权重配置
  private timeWeight: number = 0.5;
  private countWeight: number = 0.25;
  private recencyWeight: number = 0.15;
  private consistencyWeight: number = 0.1;

  // 分类阈值
  private highThreshold: number = 60;
  private mediumThreshold: number = 25;

  // 持久化服务
  private prefService: PreferenceService = PreferenceService.getInstance();
  private prefLoaded: boolean = false;

  private constructor() {}

  public static getInstance(): UsageAnalyzer {
    if (!UsageAnalyzer.instance) {
      UsageAnalyzer.instance = new UsageAnalyzer();
    }
    return UsageAnalyzer.instance;
  }

  /**
   * 初始化：从持久化存储加载配置
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.prefLoaded) {
      return;
    }

    try {
      await this.prefService.init(context);
      const weights: WeightConfig = await this.prefService.loadWeights();
      const thresholds: ThresholdConfig = await this.prefService.loadThresholds();

      await this.setWeights(weights.time, weights.count, weights.recency, weights.consistency);
      await this.setThresholds(thresholds.high, thresholds.medium);

      this.prefLoaded = true;
      console.info(TAG, '配置已从持久化加载');
    } catch (error) {
      console.error(TAG, `加载持久化配置失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 设置权重（同时保存到持久化）
   */
  async setWeights(time: number, count: number, recency: number, consistency: number): Promise<void> {
    const total: number = time + count + recency + consistency;
    if (total > 0) {
      this.timeWeight = time / total;
      this.countWeight = count / total;
      this.recencyWeight = recency / total;
      this.consistencyWeight = consistency / total;
    }
    await this.prefService.saveWeights(time, count, recency, consistency);
  }

  /**
   * 设置阈值（同时保存到持久化）
   */
  async setThresholds(high: number, medium: number): Promise<void> {
    this.highThreshold = high;
    this.mediumThreshold = medium;
    await this.prefService.saveThresholds(high, medium);
  }

  getWeights(): WeightConfig {
    const w: WeightConfig = {
      time: this.timeWeight,
      count: this.countWeight,
      recency: this.recencyWeight,
      consistency: this.consistencyWeight
    };
    return w;
  }

  getThresholds(): ThresholdConfig {
    const t: ThresholdConfig = {
      high: this.highThreshold,
      medium: this.mediumThreshold
    };
    return t;
  }

  /**
   * 主分析入口
   */
  async analyze(granularity: TimeGranularity = TimeGranularity.WEEKLY): Promise<SortResult> {
    console.info(TAG, `开始分析，时间粒度: ${granularity}`);

    const range: TimeRange = UsageAnalyzer.getTimeRange(granularity);

    try {
      const apps: AppMeta[] = await this.fetchInstalledApps();
      const stats: UsageStat[] = await this.fetchUsageStats(apps, range, granularity);
      console.info(TAG, `获取到 ${stats.length} 条使用记录`);

      const appUsageInfos: AppUsageInfo[] = this.mergeAndScore(apps, stats, range);
      const result: SortResult = this.categorize(appUsageInfos);

      console.info(TAG, `分析完成：高频${result.highFrequencyApps.length}，中频${result.mediumFrequencyApps.length}，低频${result.lowFrequencyApps.length}`);
      return result;
    } catch (error) {
      console.error(TAG, `分析失败: ${JSON.stringify(error)}`);
      // ArkTS 的 arkts-limited-throw 只允许抛 Error 及其子类
      throw new Error(`分析失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 根据时间粒度获取查询范围
   */
  private static getTimeRange(granularity: TimeGranularity): TimeRange {
    const endTime: number = Date.now();
    const dayMs: number = 24 * 60 * 60 * 1000;
    let days: number;

    switch (granularity) {
      case TimeGranularity.DAILY:
        days = 1;
        break;
      case TimeGranularity.WEEKLY:
        days = 7;
        break;
      case TimeGranularity.MONTHLY:
        days = 30;
        break;
      default:
        days = 7;
    }

    const range: TimeRange = { beginTime: endTime - days * dayMs, endTime: endTime };
    return range;
  }

  /**
   * 【模拟数据源】获取已安装应用列表
   *
   * 真实实现需要 bundleManager.getAllApplicationInfo（系统级，公开 SDK 无此函数）。
   * icon 留空，AppCard 会降级为首字母色块。
   */
  private async fetchInstalledApps(): Promise<AppMeta[]> {
    const names: string[] = [
      '微信', '支付宝', '抖音', '小红书', '哔哩哔哩', '淘宝',
      '高德地图', '网易云音乐', '知乎', '美团', '京东', '钉钉',
      '相机', '设置', '图库', '日历', '计算器', '时钟',
      '浏览器', '应用市场'
    ];

    const apps: AppMeta[] = [];
    for (let i = 0; i < names.length; i++) {
      const meta: AppMeta = {
        bundleName: `com.demo.app${i}`,
        appName: names[i],
        icon: null
      };
      apps.push(meta);
    }
    return apps;
  }

  /**
   * 【模拟数据源】获取使用统计
   *
   * 真实实现需要 usageStatistics.queryBundleStatsInfos（公开 SDK 的 namespace 为空）。
   * 这里用确定性伪随机（种子 = 下标）生成，保证同一粒度下多次刷新结果稳定，
   * 不同粒度下数值随天数缩放，便于观察界面变化。
   */
  private async fetchUsageStats(apps: AppMeta[], range: TimeRange, granularity: TimeGranularity): Promise<UsageStat[]> {
    const dayMs: number = 24 * 60 * 60 * 1000;
    const days: number = Math.max(1, Math.round((range.endTime - range.beginTime) / dayMs));
    const stats: UsageStat[] = [];

    for (let i = 0; i < apps.length; i++) {
      // 确定性伪随机：靠下标做简单散列，避免用 Math.random 导致每次刷新数据乱跳
      const seed: number = (i * 2654435761) % 1000;
      const factor: number = (seed % 97) / 97;          // 0 ~ 1
      const decay: number = 1 / (1 + i * 0.35);          // 排名越后活跃度越低

      // 单日前台时长 0 ~ 约 100 分钟，再按天数放大
      const perDayMinutes: number = Math.round(factor * 100 * decay);
      const totalMs: number = perDayMinutes * 60 * 1000 * days;
      const launches: number = Math.round((1 + factor * 12) * decay * days);

      // 最后使用时间：越靠后的应用越久没用
      const idleDays: number = Math.round(i * 0.6 * factor);
      const lastUsed: number = range.endTime - idleDays * dayMs;

      const stat: UsageStat = {
        bundleName: apps[i].bundleName,
        totalTimeInForeground: totalMs,
        totalTimeVisible: Math.round(totalMs * 1.15),
        launchCount: launches,
        lastTimeUsed: lastUsed,
        firstTimeStamp: range.beginTime
      };
      stats.push(stat);
    }
    return stats;
  }

  /**
   * 合并应用信息和使用统计，计算得分
   */
  private mergeAndScore(apps: AppMeta[], stats: UsageStat[], range: TimeRange): AppUsageInfo[] {
    const daySpan: number = DateUtil.getDaySpan(range.beginTime, range.endTime);

    // ArkTS 对展开运算符 + Math.max(...arr) 支持受限，改用显式循环求最大值
    let maxTime: number = 1;
    let maxCount: number = 1;
    for (let i = 0; i < stats.length; i++) {
      if (stats[i].totalTimeInForeground > maxTime) {
        maxTime = stats[i].totalTimeInForeground;
      }
      if (stats[i].launchCount > maxCount) {
        maxCount = stats[i].launchCount;
      }
    }

    const result: AppUsageInfo[] = [];
    const now: number = Date.now();

    for (let i = 0; i < apps.length; i++) {
      const app: AppMeta = apps[i];
      const info: AppUsageInfo = new AppUsageInfo(app.bundleName, app.appName);
      info.icon = app.icon;

      const stat: UsageStat | undefined = stats.find((s: UsageStat): boolean => s.bundleName === app.bundleName);

      if (stat !== undefined) {
        info.totalTimeInForeground = stat.totalTimeInForeground;
        info.totalTimeVisible = stat.totalTimeVisible;
        info.launchCount = stat.launchCount;
        info.lastTimeUsed = stat.lastTimeUsed;
        info.firstTimeStamp = stat.firstTimeStamp;

        const timeScore: number = Math.min((stat.totalTimeInForeground / maxTime) * 100, 100);
        const countScore: number = Math.min((stat.launchCount / maxCount) * 100, 100);

        const daysSinceLastUse: number = (now - stat.lastTimeUsed) / (24 * 60 * 60 * 1000);
        const recencyScore: number = Math.max(0, 100 - (daysSinceLastUse * 14));

        const consistencyScore: number = this.calculateConsistency(stat, daySpan);

        info.activityScore = Math.round(
          timeScore * this.timeWeight +
          countScore * this.countWeight +
          recencyScore * this.recencyWeight +
          consistencyScore * this.consistencyWeight
        );
      } else {
        info.activityScore = 0;
      }

      result.push(info);
    }

    return result.sort((a: AppUsageInfo, b: AppUsageInfo): number => b.activityScore - a.activityScore);
  }

  /**
   * 计算使用一致性得分
   */
  private calculateConsistency(stat: UsageStat, daySpan: number): number {
    if (stat.launchCount === 0 || daySpan <= 0) {
      return 0;
    }

    const avgDailyLaunches: number = stat.launchCount / daySpan;
    if (avgDailyLaunches >= 2) {
      return 100;
    }
    if (avgDailyLaunches >= 1) {
      return 70;
    }
    if (avgDailyLaunches >= 0.5) {
      return 40;
    }
    return 20;
  }

  /**
   * 根据得分分类应用
   */
  private categorize(apps: AppUsageInfo[]): SortResult {
    const result: SortResult = new SortResult();
    result.totalApps = apps.length;

    for (let i = 0; i < apps.length; i++) {
      const app: AppUsageInfo = apps[i];
      if (app.activityScore >= this.highThreshold) {
        app.category = UsageCategory.HIGH;
        result.highFrequencyApps.push(app);
      } else if (app.activityScore >= this.mediumThreshold) {
        app.category = UsageCategory.MEDIUM;
        result.mediumFrequencyApps.push(app);
      } else {
        app.category = UsageCategory.LOW;
        result.lowFrequencyApps.push(app);
      }
    }

    return result;
  }
}
