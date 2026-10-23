import { LimitService, AppLimit, LimitStatus } from '../service/LimitService';
import { UsageAnalyzer } from '../service/UsageAnalyzer';
import { TimeGranularity, AppUsageInfo } from '../model/AppUsageInfo';
import { SortResult } from '../model/SortResult';
import { DateUtil } from '../utils/DateUtil';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';

const TAG = 'LimitPage';

@Entry
@Component
struct LimitPage {
  @State limits: AppLimit[] = [];
  @State limitStatuses: LimitStatus[] = [];
  @State isLoading: boolean = true;
  @State showAddDialog: boolean = false;
  @State newAppName: string = '';
  @State newBundleName: string = '';
  @State newLimitMinutes: number = 60;
  @State editingLimit: AppLimit | null = null;

  private limitService: LimitService = LimitService.getInstance();

  /** 已超限的条目。build() 内不允许声明局部变量，故抽成方法 */
  private getExceeded(): LimitStatus[] {
    return this.limitStatuses.filter((s: LimitStatus): boolean => s.exceeded);
  }

  /** 接近超限（≥80%）但尚未超的条目 */
  private getWarnings(): LimitStatus[] {
    return this.limitStatuses.filter((s: LimitStatus): boolean => !s.exceeded && s.usagePercent >= 80);
  }

  async aboutToAppear() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await this.limitService.init(context);
    } catch (e) {
      console.warn(TAG, '初始化失败');
    }
    await this.loadLimits();
  }

  async loadLimits() {
    this.isLoading = true;
    try {
      this.limits = await this.limitService.loadLimits();

      // 计算今日使用情况。数据源与首页一致，同样是模拟的（见 UsageAnalyzer 顶部注释）
      const analyzer: UsageAnalyzer = UsageAnalyzer.getInstance();
      const daily: SortResult = await analyzer.analyze(TimeGranularity.DAILY);

      const usageMap: Map<string, number> = new Map();
      const allApps: AppUsageInfo[] = daily.highFrequencyApps
        .concat(daily.mediumFrequencyApps)
        .concat(daily.lowFrequencyApps);
      for (let i = 0; i < allApps.length; i++) {
        usageMap.set(allApps[i].bundleName, allApps[i].totalTimeInForeground);
      }

      const statuses: LimitStatus[] = [];
      for (const limit of this.limits) {
        if (!limit.enabled) {
          continue;
        }
        const used: number = usageMap.get(limit.bundleName) ?? 0;
        const status: LimitStatus | null = await this.limitService.checkLimit(limit.bundleName, used);
        if (status !== null) {
          statuses.push(status);
        }
      }
      this.limitStatuses = statuses;
    } catch (error) {
      console.error(TAG, `加载限额失败: ${JSON.stringify(error)}`);
    } finally {
      this.isLoading = false;
    }
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

        Text($r('app.string.app_limits'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Button() {
          Text('+')
            .fontSize(24)
            .fontColor('#007DFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.editingLimit = null;
          this.newAppName = '';
          this.newBundleName = '';
          this.newLimitMinutes = 60;
          this.showAddDialog = true;
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#007DFF')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.limits.length === 0) {
        Column({ space: 12 }) {
          Text('📋')
            .fontSize(48)
          Text($r('app.string.no_limits'))
            .fontSize(16)
            .fontColor('#999999')
          Text('点击右上角 + 添加使用限额')
            .fontSize(13)
            .fontColor('#CCCCCC')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            // 超限预警。ArkTS 的 build 里只能写 UI 语法，不能声明 const，
            // 所以把过滤逻辑挪到了下面的 getExceeded() / getWarnings() 方法里
            if (this.getExceeded().length > 0) {
              Column({ space: 8 }) {
                Row({ space: 4 }) {
                  Text('⚠️')
                    .fontSize(16)
                  // Resource 没有 .value 属性，不能拼进模板字符串，拆成独立 Text
                  Text($r('app.string.limit_exceeded'))
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FF6B6B')
                  Text(`(${this.getExceeded().length})`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FF6B6B')
                }
                .width('100%')

                ForEach(this.getExceeded(), (status: LimitStatus) => {
                  this.LimitStatusCard(status, true)
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFF5F5')
              .borderRadius(12)
            }

            if (this.getWarnings().length > 0) {
              Column({ space: 8 }) {
                Row({ space: 4 }) {
                  Text('⚡')
                    .fontSize(16)
                  Text($r('app.string.limit_warning'))
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFA500')
                  Text(`(${this.getWarnings().length})`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFA500')
                }
                .width('100%')

                ForEach(this.getWarnings(), (status: LimitStatus) => {
                  this.LimitStatusCard(status, false)
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFBE6')
              .borderRadius(12)
            }

            // 限额列表
            Column({ space: 8 }) {
              Text('限额列表')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              ForEach(this.limits, (limit: AppLimit) => {
                this.LimitConfigCard(limit)
              })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
      }

      // 添加/编辑弹窗
      if (this.showAddDialog) {
        this.AddLimitDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F7')
  }

  @Builder
  LimitStatusCard(status: LimitStatus, isExceeded: boolean) {
    Row({ space: 12 }) {
      Column({ space: 2 }) {
        Text(status.appName)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        Text(`${DateUtil.formatDuration(status.todayUsageMs)} / ${status.dailyLimitMinutes}分钟`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .layoutWeight(1)

      Column({ space: 2 }) {
        Text(`${status.usagePercent}%`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(isExceeded ? '#FF6B6B' : '#FFA500')

        // 进度条
        Row() {
          Row()
            .width(`${status.usagePercent}%`)
            .height(6)
            .backgroundColor(isExceeded ? '#FF6B6B' : '#FFA500')
            .borderRadius(3)
        }
        .width(60)
        .height(6)
        .backgroundColor('#EEEEEE')
        .borderRadius(3)
      }
      .width(80)
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  @Builder
  LimitConfigCard(limit: AppLimit) {
    Row({ space: 12 }) {
      Column({ space: 2 }) {
        Text(limit.appName)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Text(`${limit.dailyLimitMinutes}分钟/天`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: limit.enabled })
        .selectedColor('#007DFF')
        .onChange(async (isOn: boolean) => {
          limit.enabled = isOn;
          await this.limitService.upsertLimit(limit);
          await this.loadLimits();
        })

      Button($r('app.string.remove_limit'))
        .fontSize(12)
        .fontColor('#FF6B6B')
        .backgroundColor(Color.Transparent)
        .onClick(async () => {
          await this.limitService.removeLimit(limit.bundleName);
          await this.loadLimits();
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  @Builder
  AddLimitDialog() {
    Column({ space: 16 }) {
      Text(this.editingLimit ? $r('app.string.edit_limit') : $r('app.string.add_limit'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)

      Column({ space: 8 }) {
        Text('应用名称')
          .fontSize(13)
          .fontColor('#666666')
          .width('100%')
        TextInput({ placeholder: '如：抖音', text: this.newAppName })
          .width('100%')
          .height(44)
          .onChange((value: string) => {
            this.newAppName = value;
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        Text('包名（bundleName）')
          .fontSize(13)
          .fontColor('#666666')
          .width('100%')
        TextInput({ placeholder: '如：com.example.app', text: this.newBundleName })
          .width('100%')
          .height(44)
          .onChange((value: string) => {
            this.newBundleName = value;
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        Row({ space: 2 }) {
          Text($r('app.string.limit_minutes'))
            .fontSize(13)
            .fontColor('#666666')
          Text(`: ${this.newLimitMinutes}分钟`)
            .fontSize(13)
            .fontColor('#666666')
        }
        .width('100%')
        Slider({
          value: this.newLimitMinutes,
          min: 5,
          max: 480,
          step: 5
        })
          .width('100%')
          .selectedColor('#007DFF')
          .onChange((v: number) => {
            this.newLimitMinutes = Math.round(v);
          })
      }
      .width('100%')

      Row({ space: 12 }) {
        Button($r('app.string.close'))
          .width('45%')
          .height(44)
          .backgroundColor('#F0F0F0')
          .fontColor('#333333')
          .onClick(() => {
            this.showAddDialog = false;
          })

        Button($r('app.string.save'))
          .width('45%')
          .height(44)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .onClick(async () => {
            if (this.newAppName && this.newBundleName) {
              await this.limitService.upsertLimit({
                bundleName: this.newBundleName,
                appName: this.newAppName,
                dailyLimitMinutes: this.newLimitMinutes,
                enabled: true
              });
              this.showAddDialog = false;
              await this.loadLimits();
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}
