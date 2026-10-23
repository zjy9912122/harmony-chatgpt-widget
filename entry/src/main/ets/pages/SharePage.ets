import { AppDataService } from '../service/AppDataService';
import { ShareService } from '../service/ShareService';
import { UsageAnalyzer } from '../service/UsageAnalyzer';
import { TimeGranularity } from '../model/AppUsageInfo';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';

const TAG = 'SharePage';

@Entry
@Component
struct SharePage {
  @State shareText: string = '';
  @State jsonReport: string = '';
  @State isLoading: boolean = true;
  @State showCopied: boolean = false;

  private dataService: AppDataService = AppDataService.getInstance();
  private shareService: ShareService = ShareService.getInstance();
  private analyzer: UsageAnalyzer = UsageAnalyzer.getInstance();

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const result = await this.analyzer.analyze(TimeGranularity.WEEKLY);
      this.shareText = this.dataService.generateSuggestionText(result);
      this.jsonReport = this.dataService.generateJSONReport(result);
    } catch (error) {
      console.error(TAG, `加载数据失败: ${JSON.stringify(error)}`);
    } finally {
      this.isLoading = false;
    }
  }

  getContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Text('←')
            .fontSize(24)
            .fontColor('#333333')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })

        Text($r('app.string.share'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 16 })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#007DFF')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            // 文本预览卡片
            Column({ space: 8 }) {
              Text($r('app.string.share_text'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              Text(this.shareText)
                .fontSize(13)
                .fontColor('#333333')
                .width('100%')
                .maxLines(10)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .backgroundColor('#F8F9FA')
                .padding(12)
                .borderRadius(8)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })

            // 操作按钮
            Column({ space: 12 }) {
              Button($r('app.string.copy_clipboard'))
                .width('100%')
                .height(48)
                .backgroundColor('#007DFF')
                .fontColor('#FFFFFF')
                .onClick(async () => {
                  const success = await this.shareService.copyToClipboard(this.getContext(), this.shareText);
                  if (success) {
                    this.showCopied = true;
                    setTimeout(() => this.showCopied = false, 2000);
                  }
                })

              Button($r('app.string.share_text'))
                .width('100%')
                .height(48)
                .backgroundColor('#4ECDC4')
                .fontColor('#FFFFFF')
                .onClick(() => {
                  this.shareService.shareText(this.getContext(), this.shareText, '应用使用分析报告');
                })

              Button($r('app.string.share_json'))
                .width('100%')
                .height(48)
                .backgroundColor('#F0F0F0')
                .fontColor('#333333')
                .onClick(() => {
                  this.shareService.shareJSON(this.getContext(), this.jsonReport);
                })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })

            // 提示
            if (this.showCopied) {
              Text($r('app.string.copied'))
                .fontSize(14)
                .fontColor('#4ECDC4')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(8)
                .backgroundColor('#E8F8F5')
                .borderRadius(8)
            }
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F7')
  }
}
