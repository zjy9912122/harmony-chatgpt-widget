/**
 * 日期工具类
 */
export class DateUtil {
  /**
   * 格式化时间戳为可读字符串
   */
  static formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${month}月${day}日 ${hour}:${minute}`;
  }

  /**
   * 格式化使用时长（毫秒 → 小时/分钟）
   */
  static formatDuration(ms: number): string {
    if (ms <= 0) return '0分钟';
    const hours = Math.floor(ms / (60 * 60 * 1000));
    const minutes = Math.floor((ms % (60 * 60 * 1000)) / (60 * 1000));
    if (hours > 0) {
      return `${hours}小时${minutes}分钟`;
    }
    return `${minutes}分钟`;
  }

  /**
   * 获取相对时间描述
   */
  static getRelativeTime(timestamp: number): string {
    const now = Date.now();
    const diff = now - timestamp;
    const minutes = Math.floor(diff / (60 * 1000));
    const hours = Math.floor(diff / (60 * 60 * 1000));
    const days = Math.floor(diff / (24 * 60 * 60 * 1000));

    if (minutes < 1) return '刚刚';
    if (minutes < 60) return `${minutes}分钟前`;
    if (hours < 24) return `${hours}小时前`;
    if (days < 7) return `${days}天前`;
    return DateUtil.formatDate(timestamp);
  }

  /**
   * 获取时间段内的天数
   */
  static getDaySpan(beginTime: number, endTime: number): number {
    return Math.max(1, Math.floor((endTime - beginTime) / (24 * 60 * 60 * 1000)));
  }
}
