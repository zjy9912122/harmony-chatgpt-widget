import { AppUsageInfo } from './AppUsageInfo';

/**
 * 排序结果
 */
export class SortResult {
  highFrequencyApps: AppUsageInfo[] = [];
  mediumFrequencyApps: AppUsageInfo[] = [];
  lowFrequencyApps: AppUsageInfo[] = [];
  totalApps: number = 0;
  lastUpdateTime: number = Date.now();
}
