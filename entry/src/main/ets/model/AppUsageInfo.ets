/**
 * 应用使用信息数据模型
 */
export class AppUsageInfo {
  // 应用基本信息
  bundleName: string = '';
  appName: string = '';
  icon: Resource | null = null;

  // 使用统计数据
  totalTimeInForeground: number = 0;
  totalTimeVisible: number = 0;
  launchCount: number = 0;
  lastTimeUsed: number = 0;
  firstTimeStamp: number = 0;

  // 计算得分
  activityScore: number = 0;
  category: UsageCategory = UsageCategory.LOW;

  constructor(bundleName: string = '', appName: string = '') {
    this.bundleName = bundleName;
    this.appName = appName;
  }
}

/**
 * 使用频率分类
 */
export enum UsageCategory {
  HIGH = 'high',
  MEDIUM = 'medium',
  LOW = 'low'
}

/**
 * 时间粒度
 */
export enum TimeGranularity {
  DAILY = 'daily',
  WEEKLY = 'weekly',
  MONTHLY = 'monthly'
}
