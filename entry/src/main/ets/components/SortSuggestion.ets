import { SortResult } from '../model/SortResult';
import { AppUsageInfo } from '../model/AppUsageInfo';
import { AppDataService } from '../service/AppDataService';

@CustomDialog
export struct SortSuggestionDialog {
  @Prop sortResult: SortResult;
  private dataService: AppDataService = AppDataService.getInstance();
  controller: CustomDialogController;

  build() {
    Column({ space: 16 }) {
      Text('📱 桌面整理建议')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Scroll() {
        Column({ space: 12 }) {
          // 高频应用
          this.SuggestionSection('🔥 高频应用（建议放首页）', this.sortResult.highFrequencyApps, '#FF6B6B')

          // 中频应用
          this.SuggestionSection('📁 中频应用（建议放文件夹）', this.sortResult.mediumFrequencyApps, '#4ECDC4')

          // 低频应用
          this.SuggestionSection('💤 低频应用（可考虑隐藏）', this.sortResult.lowFrequencyApps.slice(0, 5), '#95A5A6')
        }
        .width('100%')
        .padding({ bottom: 16 })
      }
      .layoutWeight(1)

      Button('关闭')
        .width('100%')
        .height(44)
        .backgroundColor('#007DFF')
        .fontColor('#FFFFFF')
        .onClick(() => {
          this.controller.close();
        })
    }
    .width('100%')
    .height('80%')
    .padding(20)
  }

  @Builder
  SuggestionSection(title: string, apps: AppUsageInfo[], color: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .width('100%')

      Column({ space: 6 }) {
        ForEach(apps.slice(0, 8), (app: AppUsageInfo, index: number) => {
          Row() {
            Text(`${index + 1}. ${app.appName}`)
              .fontSize(13)
              .layoutWeight(1)

            Text(`${app.activityScore}分`)
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')
          .height(32)
        })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F8F9FA')
      .borderRadius(8)
    }
    .width('100%')
  }
}
