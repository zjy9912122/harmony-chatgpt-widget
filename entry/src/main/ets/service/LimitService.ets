import { PreferenceService } from './PreferenceService';
import common from '@ohos.app.ability.common';

const TAG = 'LimitService';
const LIMITS_KEY = 'app_limits';

/**
 * 应用使用限额配置
 */
export interface AppLimit {
  bundleName: string;
  appName: string;
  dailyLimitMinutes: number; // 每日限额（分钟）
  enabled: boolean;
}

/**
 * 限额检查状态
 */
export interface LimitStatus {
  bundleName: string;
  appName: string;
  dailyLimitMinutes: number;
  todayUsageMs: number;
  remainingMs: number;
  exceeded: boolean;
  usagePercent: number; // 0-100
}

/**
 * 使用限额服务
 * 管理应用每日使用时长限额与超限提醒
 */
export class LimitService {
  private static instance: LimitService;
  private prefService: PreferenceService;
  private inited: boolean = false;

  private constructor() {
    this.prefService = PreferenceService.getInstance();
  }

  public static getInstance(): LimitService {
    if (!LimitService.instance) {
      LimitService.instance = new LimitService();
    }
    return LimitService.instance;
  }

  /**
   * 初始化
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.inited) return;
    await this.prefService.init(context);
    this.inited = true;
  }

  /**
   * 加载所有限额配置
   */
  async loadLimits(): Promise<AppLimit[]> {
    try {
      const raw: string = await this.prefService.getString(LIMITS_KEY, '[]');
      const parsed: AppLimit[] = JSON.parse(raw) as AppLimit[];
      if (Array.isArray(parsed)) {
        return parsed;
      }
      return [];
    } catch (error) {
      console.error(TAG, `加载限额失败: ${JSON.stringify(error)}`);
      return [];
    }
  }

  /**
   * 保存所有限额配置
   */
  async saveLimits(limits: AppLimit[]): Promise<void> {
    try {
      await this.prefService.setString(LIMITS_KEY, JSON.stringify(limits));
      console.info(TAG, `已保存 ${limits.length} 条限额配置`);
    } catch (error) {
      console.error(TAG, `保存限额失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 添加或更新限额
   */
  async upsertLimit(limit: AppLimit): Promise<void> {
    const limits = await this.loadLimits();
    const idx = limits.findIndex(l => l.bundleName === limit.bundleName);
    if (idx >= 0) {
      limits[idx] = limit;
    } else {
      limits.push(limit);
    }
    await this.saveLimits(limits);
  }

  /**
   * 删除限额
   */
  async removeLimit(bundleName: string): Promise<void> {
    const limits = await this.loadLimits();
    const filtered = limits.filter(l => l.bundleName !== bundleName);
    await this.saveLimits(filtered);
  }

  /**
   * 获取单个限额
   */
  async getLimit(bundleName: string): Promise<AppLimit | null> {
    const limits = await this.loadLimits();
    return limits.find(l => l.bundleName === bundleName) || null;
  }

  /**
   * 检查指定应用是否超限
   * 需要传入今日使用时长（毫秒）
   */
  async checkLimit(bundleName: string, todayUsageMs: number): Promise<LimitStatus | null> {
    const limit = await this.getLimit(bundleName);
    if (!limit || !limit.enabled) return null;

    const limitMs = limit.dailyLimitMinutes * 60 * 1000;
    const remainingMs = Math.max(0, limitMs - todayUsageMs);
    const exceeded = todayUsageMs > limitMs;
    const usagePercent = Math.min(100, Math.round((todayUsageMs / limitMs) * 100));

    return {
      bundleName,
      appName: limit.appName,
      dailyLimitMinutes: limit.dailyLimitMinutes,
      todayUsageMs,
      remainingMs,
      exceeded,
      usagePercent
    };
  }

  /**
   * 获取所有超限的应用
   */
  async getExceededLimits(usageMap: Map<string, number>): Promise<LimitStatus[]> {
    const limits = await this.loadLimits();
    const exceeded: LimitStatus[] = [];

    for (const limit of limits) {
      if (!limit.enabled) continue;
      const usage = usageMap.get(limit.bundleName) || 0;
      const status = await this.checkLimit(limit.bundleName, usage);
      if (status && status.exceeded) {
        exceeded.push(status);
      }
    }

    return exceeded;
  }

  /**
   * 获取预警应用（使用超过80%但未超限）
   */
  async getWarningLimits(usageMap: Map<string, number>): Promise<LimitStatus[]> {
    const limits = await this.loadLimits();
    const warnings: LimitStatus[] = [];

    for (const limit of limits) {
      if (!limit.enabled) continue;
      const usage = usageMap.get(limit.bundleName) || 0;
      const status = await this.checkLimit(limit.bundleName, usage);
      if (status && !status.exceeded && status.usagePercent >= 80) {
        warnings.push(status);
      }
    }

    return warnings;
  }
}
