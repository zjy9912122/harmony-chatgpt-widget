import { SortResult } from '../model/SortResult';
import { ComparisonResult } from '../model/Types';
import { PreferenceService } from './PreferenceService';
import common from '@ohos.app.ability.common';

const TAG = 'HistoryService';
const HISTORY_KEY = 'analysis_history';
const MAX_HISTORY = 30; // 最多保留30条历史

/**
 * 历史分析记录
 */
export interface HistoryRecord {
  id: string;
  timestamp: number;
  granularity: string;
  totalApps: number;
  highCount: number;
  mediumCount: number;
  lowCount: number;
  topAppName: string;
  topAppScore: number;
}

/**
 * 历史记录服务
 * 保存每次分析的快照，支持趋势对比
 */
export class HistoryService {
  private static instance: HistoryService;
  private prefService: PreferenceService;
  private inited: boolean = false;

  private constructor() {
    this.prefService = PreferenceService.getInstance();
  }

  public static getInstance(): HistoryService {
    if (!HistoryService.instance) {
      HistoryService.instance = new HistoryService();
    }
    return HistoryService.instance;
  }

  /**
   * 初始化（需要在页面中传入Context）
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.inited) return;
    await this.prefService.init(context);
    this.inited = true;
  }

  /**
   * 保存分析快照
   */
  async saveSnapshot(result: SortResult, granularity: string): Promise<void> {
    try {
      const history = await this.loadHistory();

      const topApp = result.highFrequencyApps[0];
      const record: HistoryRecord = {
        id: `${Date.now()}`,
        timestamp: Date.now(),
        granularity,
        totalApps: result.totalApps,
        highCount: result.highFrequencyApps.length,
        mediumCount: result.mediumFrequencyApps.length,
        lowCount: result.lowFrequencyApps.length,
        topAppName: topApp ? topApp.appName : '无',
        topAppScore: topApp ? topApp.activityScore : 0
      };

      // 检查是否已有相同粒度的最近记录（5分钟内不重复保存）
      const recentSame = history.find(h =>
        h.granularity === granularity &&
        (Date.now() - h.timestamp) < 5 * 60 * 1000
      );
      if (recentSame) {
        // 替换最近记录
        const idx = history.indexOf(recentSame);
        history[idx] = record;
      } else {
        history.unshift(record);
      }

      // 限制数量
      if (history.length > MAX_HISTORY) {
        history.splice(MAX_HISTORY);
      }

      await this.prefService.setString(HISTORY_KEY, JSON.stringify(history));
      console.info(TAG, `历史记录已保存，当前共 ${history.length} 条`);
    } catch (error) {
      console.error(TAG, `保存快照失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 加载历史记录
   */
  async loadHistory(): Promise<HistoryRecord[]> {
    try {
      const raw: string = await this.prefService.getString(HISTORY_KEY, '[]');
      const parsed: HistoryRecord[] = JSON.parse(raw) as HistoryRecord[];
      if (Array.isArray(parsed)) {
        return parsed;
      }
      return [];
    } catch (error) {
      console.error(TAG, `加载历史失败: ${JSON.stringify(error)}`);
      return [];
    }
  }

  /**
   * 获取指定粒度的最近记录
   */
  async getLatestByGranularity(granularity: string): Promise<HistoryRecord | null> {
    const history: HistoryRecord[] = await this.loadHistory();
    const found: HistoryRecord | undefined =
      history.find((h: HistoryRecord): boolean => h.granularity === granularity);
    return found ?? null;
  }

  /**
   * 计算与上次分析的对比变化
   */
  async getComparison(current: SortResult, granularity: string): Promise<ComparisonResult> {
    const latest: HistoryRecord | null = await this.getLatestByGranularity(granularity);
    if (latest === null) {
      const empty: ComparisonResult = {
        highChange: 0, mediumChange: 0, lowChange: 0, totalChange: 0, hasHistory: false
      };
      return empty;
    }

    const diff: ComparisonResult = {
      highChange: current.highFrequencyApps.length - latest.highCount,
      mediumChange: current.mediumFrequencyApps.length - latest.mediumCount,
      lowChange: current.lowFrequencyApps.length - latest.lowCount,
      totalChange: current.totalApps - latest.totalApps,
      hasHistory: true
    };
    return diff;
  }

  /**
   * 清除所有历史
   */
  async clearHistory(): Promise<void> {
    await this.prefService.setString(HISTORY_KEY, '[]');
    console.info(TAG, '历史记录已清除');
  }
}
