/**
 * 共享类型声明
 *
 * ArkTS 禁止匿名对象字面量（arkts-no-untyped-obj-literals）和把对象字面量当类型用
 * （arkts-no-obj-literals-as-types），凡是要传/返回结构化数据，都必须先在这里声明。
 */

/** 活跃度评分的四项权重 */
export interface WeightConfig {
  time: number;
  count: number;
  recency: number;
  consistency: number;
}

/** 高频 / 中频分类阈值 */
export interface ThresholdConfig {
  high: number;
  medium: number;
}

/** 应用元信息（包名 + 显示名 + 图标） */
export interface AppMeta {
  bundleName: string;
  appName: string;
  icon: Resource | null;
}

/** 单个应用的使用统计。字段对齐系统 BundleStatsInfo，便于将来接真实数据源 */
export interface UsageStat {
  bundleName: string;
  totalTimeInForeground: number;
  totalTimeVisible: number;
  launchCount: number;
  lastTimeUsed: number;
  firstTimeStamp: number;
}

/** 查询时间范围 */
export interface TimeRange {
  beginTime: number;
  endTime: number;
}

/** 趋势图上的一个数据点 */
export interface TrendPoint {
  date: string;
  time: number;
  count: number;
}

/** 按天聚合的中间结果 */
export interface DailyAgg {
  time: number;
  count: number;
}

/** 与上次快照的对比结果 */
export interface ComparisonResult {
  highChange: number;
  mediumChange: number;
  lowChange: number;
  totalChange: number;
  hasHistory: boolean;
}
