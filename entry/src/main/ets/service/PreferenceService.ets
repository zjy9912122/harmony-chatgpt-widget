import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { WeightConfig, ThresholdConfig } from '../model/Types';

const TAG = 'PreferenceService';
const PREF_NAME = 'app_usage_prefs';

/** 配置键名。ArkTS 不允许匿名对象字面量，故显式声明结构 */
interface PrefKeyMap {
  TIME_WEIGHT: string;
  COUNT_WEIGHT: string;
  RECENCY_WEIGHT: string;
  CONSISTENCY_WEIGHT: string;
  HIGH_THRESHOLD: string;
  MEDIUM_THRESHOLD: string;
  FIRST_LAUNCH: string;
  HISTORY_ENABLED: string;
  LIMITS_DATA: string;
}

/** 默认值 */
interface PrefDefaultMap {
  TIME_WEIGHT: number;
  COUNT_WEIGHT: number;
  RECENCY_WEIGHT: number;
  CONSISTENCY_WEIGHT: number;
  HIGH_THRESHOLD: number;
  MEDIUM_THRESHOLD: number;
}

/**
 * 偏好设置服务
 * 封装 @ohos.data.preferences 实现配置持久化
 */
export class PreferenceService {
  private static instance: PreferenceService;
  private preferences: dataPreferences.Preferences | null = null;
  private initialized: boolean = false;

  // 配置键名
  static readonly KEYS: PrefKeyMap = {
    TIME_WEIGHT: 'time_weight',
    COUNT_WEIGHT: 'count_weight',
    RECENCY_WEIGHT: 'recency_weight',
    CONSISTENCY_WEIGHT: 'consistency_weight',
    HIGH_THRESHOLD: 'high_threshold',
    MEDIUM_THRESHOLD: 'medium_threshold',
    FIRST_LAUNCH: 'first_launch',
    HISTORY_ENABLED: 'history_enabled',
    LIMITS_DATA: 'limits_data'
  };

  // 默认值
  static readonly DEFAULTS: PrefDefaultMap = {
    TIME_WEIGHT: 50,
    COUNT_WEIGHT: 25,
    RECENCY_WEIGHT: 15,
    CONSISTENCY_WEIGHT: 10,
    HIGH_THRESHOLD: 60,
    MEDIUM_THRESHOLD: 25
  };

  private constructor() {}

  public static getInstance(): PreferenceService {
    if (!PreferenceService.instance) {
      PreferenceService.instance = new PreferenceService();
    }
    return PreferenceService.instance;
  }

  /**
   * 初始化 Preferences（在 Ability 或页面中调用）
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.initialized) return;
    try {
      this.preferences = await dataPreferences.getPreferences(context, PREF_NAME);
      this.initialized = true;
      console.info(TAG, 'Preferences 初始化成功');
    } catch (error) {
      console.error(TAG, `Preferences 初始化失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 确保已初始化
   */
  private ensureInit(): boolean {
    if (!this.preferences) {
      console.warn(TAG, 'Preferences 未初始化，尝试使用页面Context');
      return false;
    }
    return true;
  }

  /**
   * 设置数值
   */
  async setNumber(key: string, value: number): Promise<void> {
    if (!this.ensureInit()) return;
    try {
      await this.preferences!.put(key, value);
      await this.preferences!.flush();
    } catch (error) {
      console.error(TAG, `保存 ${key} 失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 获取数值
   */
  async getNumber(key: string, defaultValue: number): Promise<number> {
    if (!this.ensureInit()) return defaultValue;
    try {
      const value = await this.preferences!.get(key, defaultValue);
      return typeof value === 'number' ? value : defaultValue;
    } catch (error) {
      console.error(TAG, `读取 ${key} 失败: ${JSON.stringify(error)}`);
      return defaultValue;
    }
  }

  /**
   * 设置字符串
   */
  async setString(key: string, value: string): Promise<void> {
    if (!this.ensureInit()) return;
    try {
      await this.preferences!.put(key, value);
      await this.preferences!.flush();
    } catch (error) {
      console.error(TAG, `保存 ${key} 失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 获取字符串
   */
  async getString(key: string, defaultValue: string): Promise<string> {
    if (!this.ensureInit()) return defaultValue;
    try {
      const value = await this.preferences!.get(key, defaultValue);
      return typeof value === 'string' ? value : defaultValue;
    } catch (error) {
      console.error(TAG, `读取 ${key} 失败: ${JSON.stringify(error)}`);
      return defaultValue;
    }
  }

  /**
   * 设置布尔值
   */
  async setBoolean(key: string, value: boolean): Promise<void> {
    if (!this.ensureInit()) return;
    try {
      await this.preferences!.put(key, value);
      await this.preferences!.flush();
    } catch (error) {
      console.error(TAG, `保存 ${key} 失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 获取布尔值
   */
  async getBoolean(key: string, defaultValue: boolean): Promise<boolean> {
    if (!this.ensureInit()) return defaultValue;
    try {
      const value = await this.preferences!.get(key, defaultValue);
      return typeof value === 'boolean' ? value : defaultValue;
    } catch (error) {
      console.error(TAG, `读取 ${key} 失败: ${JSON.stringify(error)}`);
      return defaultValue;
    }
  }

  /**
   * 删除键
   */
  async delete(key: string): Promise<void> {
    if (!this.ensureInit()) return;
    try {
      await this.preferences!.delete(key);
      await this.preferences!.flush();
    } catch (error) {
      console.error(TAG, `删除 ${key} 失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 批量保存权重配置
   */
  async saveWeights(time: number, count: number, recency: number, consistency: number): Promise<void> {
    if (!this.ensureInit()) return;
    try {
      await this.preferences!.put(PreferenceService.KEYS.TIME_WEIGHT, time);
      await this.preferences!.put(PreferenceService.KEYS.COUNT_WEIGHT, count);
      await this.preferences!.put(PreferenceService.KEYS.RECENCY_WEIGHT, recency);
      await this.preferences!.put(PreferenceService.KEYS.CONSISTENCY_WEIGHT, consistency);
      await this.preferences!.flush();
      console.info(TAG, '权重配置已保存');
    } catch (error) {
      console.error(TAG, `保存权重失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 批量读取权重配置
   */
  async loadWeights(): Promise<WeightConfig> {
    const defaults: PrefDefaultMap = PreferenceService.DEFAULTS;
    const cfg: WeightConfig = {
      time: await this.getNumber(PreferenceService.KEYS.TIME_WEIGHT, defaults.TIME_WEIGHT),
      count: await this.getNumber(PreferenceService.KEYS.COUNT_WEIGHT, defaults.COUNT_WEIGHT),
      recency: await this.getNumber(PreferenceService.KEYS.RECENCY_WEIGHT, defaults.RECENCY_WEIGHT),
      consistency: await this.getNumber(PreferenceService.KEYS.CONSISTENCY_WEIGHT, defaults.CONSISTENCY_WEIGHT)
    };
    return cfg;
  }

  /**
   * 批量保存阈值配置
   */
  async saveThresholds(high: number, medium: number): Promise<void> {
    if (!this.ensureInit()) return;
    try {
      await this.preferences!.put(PreferenceService.KEYS.HIGH_THRESHOLD, high);
      await this.preferences!.put(PreferenceService.KEYS.MEDIUM_THRESHOLD, medium);
      await this.preferences!.flush();
      console.info(TAG, '阈值配置已保存');
    } catch (error) {
      console.error(TAG, `保存阈值失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 批量读取阈值配置
   */
  async loadThresholds(): Promise<ThresholdConfig> {
    const cfg: ThresholdConfig = {
      high: await this.getNumber(PreferenceService.KEYS.HIGH_THRESHOLD, PreferenceService.DEFAULTS.HIGH_THRESHOLD),
      medium: await this.getNumber(PreferenceService.KEYS.MEDIUM_THRESHOLD, PreferenceService.DEFAULTS.MEDIUM_THRESHOLD)
    };
    return cfg;
  }

  /**
   * 重置所有配置为默认值
   */
  async resetAll(): Promise<void> {
    if (!this.ensureInit()) return;
    try {
      const d: PrefDefaultMap = PreferenceService.DEFAULTS;
      await this.saveWeights(d.TIME_WEIGHT, d.COUNT_WEIGHT, d.RECENCY_WEIGHT, d.CONSISTENCY_WEIGHT);
      await this.saveThresholds(d.HIGH_THRESHOLD, d.MEDIUM_THRESHOLD);
      console.info(TAG, '配置已重置为默认值');
    } catch (error) {
      console.error(TAG, `重置配置失败: ${JSON.stringify(error)}`);
    }
  }
}
