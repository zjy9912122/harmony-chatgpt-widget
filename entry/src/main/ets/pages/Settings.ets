import { UsageAnalyzer } from '../service/UsageAnalyzer';
import { PreferenceService } from '../service/PreferenceService';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

@Entry
@Component
struct Settings {
  @State timeWeight: number = 50;
  @State countWeight: number = 25;
  @State recencyWeight: number = 15;
  @State consistencyWeight: number = 10;
  @State highThreshold: number = 60;
  @State mediumThreshold: number = 25;
  @State showSavedTip: boolean = false;

  private analyzer: UsageAnalyzer = UsageAnalyzer.getInstance();
  private prefService: PreferenceService = PreferenceService.getInstance();

  async aboutToAppear() {
    // 初始化持久化服务
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await this.prefService.init(context);
      await this.analyzer.init(context);
    } catch (e) {
      console.warn('Settings', 'Context初始化失败，使用默认值');
    }

    const weights = this.analyzer.getWeights();
    this.timeWeight = Math.round(weights.time * 100);
    this.countWeight = Math.round(weights.count * 100);
    this.recencyWeight = Math.round(weights.recency * 100);
    this.consistencyWeight = Math.round(weights.consistency * 100);

    const thresholds = this.analyzer.getThresholds();
    this.highThreshold = thresholds.high;
    this.mediumThreshold = thresholds.medium;
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

        Text($r('app.string.settings'))
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

      Scroll() {
        Column({ space: 20 }) {
          // 权重设置
          Column({ space: 12 }) {
            Text($r('app.string.weight_settings'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .width('100%')

            this.SliderItem($r('app.string.time_weight'), this.timeWeight, (value: number) => {
              this.timeWeight = value;
            })

            this.SliderItem($r('app.string.count_weight'), this.countWeight, (value: number) => {
              this.countWeight = value;
            })

            this.SliderItem($r('app.string.recency_weight'), this.recencyWeight, (value: number) => {
              this.recencyWeight = value;
            })

            this.SliderItem($r('app.string.consistency_weight'), this.consistencyWeight, (value: number) => {
              this.consistencyWeight = value;
            })

            // 权重总计提示
            Row() {
              Text('权重总计:')
                .fontSize(12)
                .fontColor('#999999')
              Text(`${this.timeWeight + this.countWeight + this.recencyWeight + this.consistencyWeight}%`)
                .fontSize(12)
                .fontColor(this.timeWeight + this.countWeight + this.recencyWeight + this.consistencyWeight === 100 ? '#4ECDC4' : '#FF6B6B')
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .justifyContent(FlexAlign.End)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })

          // 阈值设置
          Column({ space: 12 }) {
            Text($r('app.string.threshold_settings'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .width('100%')

            this.SliderItem($r('app.string.high_threshold'), this.highThreshold, (value: number) => {
              this.highThreshold = value;
            }, 0, 100)

            this.SliderItem($r('app.string.medium_threshold'), this.mediumThreshold, (value: number) => {
              this.mediumThreshold = value;
            }, 0, 100)

            // 阈值校验提示
            if (this.mediumThreshold >= this.highThreshold) {
              Text('⚠️ 中频阈值应小于高频阈值')
                .fontSize(12)
                .fontColor('#FF6B6B')
                .width('100%')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })

          // 说明
          Column({ space: 8 }) {
            Text('💡 参数说明')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width('100%')

            Text('· 权重：各维度在活跃度计算中的占比，总和应为100%')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')

            Text('· 阈值：应用分类的分数界限，中频阈值需小于高频阈值')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')

            Text('· 调整参数后保存即可生效，配置会自动持久化')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })

          // 保存成功提示
          if (this.showSavedTip) {
            Text('✅ 设置已保存并持久化')
              .fontSize(14)
              .fontColor('#4ECDC4')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(12)
              .backgroundColor('#E8F8F5')
              .borderRadius(8)
          }

          // 按钮
          Row({ space: 12 }) {
            Button($r('app.string.reset'))
              .width('45%')
              .height(44)
              .backgroundColor('#F0F0F0')
              .fontColor('#333333')
              .onClick(() => {
                this.timeWeight = 50;
                this.countWeight = 25;
                this.recencyWeight = 15;
                this.consistencyWeight = 10;
                this.highThreshold = 60;
                this.mediumThreshold = 25;
                this.saveSettings();
              })

            Button($r('app.string.save'))
              .width('45%')
              .height(44)
              .backgroundColor('#007DFF')
              .fontColor('#FFFFFF')
              .onClick(() => {
                if (this.mediumThreshold >= this.highThreshold) {
                  return; // 阈值不合法，不保存
                }
                this.saveSettings();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 8, bottom: 16 })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F7')
  }

  @Builder
  SliderItem(label: ResourceStr, value: number, onChange: (value: number) => void, min: number = 0, max: number = 100) {
    Column({ space: 4 }) {
      Row() {
        Text(label)
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)

        Text(`${value}`)
          .fontSize(14)
          .fontColor('#007DFF')
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')

      Slider({
        value: value,
        min: min,
        max: max,
        step: 1
      })
        .width('100%')
        .selectedColor('#007DFF')
        .onChange((v: number) => {
          onChange(v);
        })
    }
    .width('100%')
  }

  async saveSettings() {
    await this.analyzer.setWeights(
      this.timeWeight,
      this.countWeight,
      this.recencyWeight,
      this.consistencyWeight
    );
    await this.analyzer.setThresholds(this.highThreshold, this.mediumThreshold);

    this.showSavedTip = true;
    setTimeout(() => this.showSavedTip = false, 2000);
  }
}
