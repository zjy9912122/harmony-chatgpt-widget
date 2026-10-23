import { AppUsageInfo } from '../model/AppUsageInfo';
import { DateUtil } from '../utils/DateUtil';

@Component
export struct AppCard {
  @Prop app: AppUsageInfo;
  @Prop index: number;

  build() {
    Row({ space: 12 }) {
      // 排名序号
      Text(`${this.index + 1}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#999999')
        .width(28)
        .textAlign(TextAlign.Center)

      // 应用图标（优先使用系统图标，否则使用首字母色块）
      this.AppIcon()

      // 应用信息
      Column({ space: 4 }) {
        Text(this.app.appName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row({ space: 8 }) {
          Text(DateUtil.formatDuration(this.app.totalTimeInForeground))
            .fontSize(12)
            .fontColor('#666666')

          Text(`启动${this.app.launchCount}次`)
            .fontSize(12)
            .fontColor('#666666')

          Text(DateUtil.getRelativeTime(this.app.lastTimeUsed))
            .fontSize(12)
            .fontColor('#999999')
        }

        // 得分进度条
        Row() {
          Row()
            .width(`${Math.min(this.app.activityScore, 100)}%`)
            .height(4)
            .backgroundColor(this.getScoreColor(this.app.activityScore))
            .borderRadius(2)
        }
        .width('100%')
        .height(4)
        .backgroundColor('#EEEEEE')
        .borderRadius(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 得分
      Column({ space: 2 }) {
        Text(`${this.app.activityScore}`)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getScoreColor(this.app.activityScore))
        Text('分')
          .fontSize(10)
          .fontColor('#999999')
      }
      .width(48)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height(84)
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  AppIcon() {
    if (this.app.icon) {
      // 使用系统返回的图标资源
      Image(this.app.icon)
        .width(48)
        .height(48)
        .borderRadius(12)
        .objectFit(ImageFit.Cover)
    } else {
      // fallback：首字母色块
      Column() {
        Text(this.app.appName.charAt(0))
          .fontSize(20)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
      }
      .width(48)
      .height(48)
      .backgroundColor(this.getIconColor(this.index))
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
    }
  }

  private getScoreColor(score: number): ResourceColor {
    if (score >= 60) return '#FF6B6B';
    if (score >= 25) return '#4ECDC4';
    return '#95A5A6';
  }

  private getIconColor(index: number): ResourceColor {
    const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F'];
    return colors[index % colors.length];
  }
}
