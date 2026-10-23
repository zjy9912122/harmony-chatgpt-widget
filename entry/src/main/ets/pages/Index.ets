import { UsageAnalyzer } from '../service/UsageAnalyzer';
import { AppDataService } from '../service/AppDataService';
import { HistoryService } from '../service/HistoryService';
import { LimitService, LimitStatus } from '../service/LimitService';
import { AppUsageInfo, TimeGranularity, UsageCategory } from '../model/AppUsageInfo';
import { SortResult } from '../model/SortResult';
import { ComparisonResult } from '../model/Types';
import { AppCard } from '../components/AppCard';
import { StatCard } from '../components/StatCard';
import { SortSuggestionDialog } from '../components/SortSuggestion';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';

const TAG = 'IndexPage';

@Entry
@Component
struct Index {
  @State sortResult: SortResult = new SortResult();
  @State currentGranularity: TimeGranularity = TimeGranularity.WEEKLY;
  @State isLoading: boolean = false;
  @State activeTab: number = 0;
  @State comparison: ComparisonResult = {
    highChange: 0, mediumChange: 0, lowChange: 0, totalChange: 0, hasHistory: false
  };
  @State exceededLimits: LimitStatus[] = [];
  @State warningLimits: LimitStatus[] = [];

  private analyzer: UsageAnalyzer = UsageAnalyzer.getInstance();
  private dataService: AppDataService = AppDataService.getInstance();
  private historyService: HistoryService = HistoryService.getInstance();
  private limitService: LimitService = LimitService.getInstance();
  private suggestionDialogController: CustomDialogController | null = null;

  async aboutToAppear() {
    // 初始化各服务
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await this.analyzer.init(context);
      await this.historyService.init(context);
      await this.limitService.init(context);
    } catch (e) {
      console.warn(TAG, 'Context初始化部分失败，继续加载');
    }

    await this.refreshData();
  }

  async refreshData() {
    this.isLoading = true;
    try {
      // 使用带缓存的数据服务
      this.sortResult = await this.dataService.getAnalysisResult(this.analyzer, this.currentGranularity);

      // 保存历史快照
      await this.historyService.saveSnapshot(this.sortResult, this.currentGranularity);

      // 计算与上次对比
      this.comparison = await this.historyService.getComparison(this.sortResult, this.currentGranularity);

      // 检查限额状态
      const usageMap = new Map<string, number>();
      [...this.sortResult.highFrequencyApps, ...this.sortResult.mediumFrequencyApps, ...this.sortResult.lowFrequencyApps]
        .forEach(app => usageMap.set(app.bundleName, app.totalTimeInForeground));

      this.exceededLimits = await this.limitService.getExceededLimits(usageMap);
      this.warningLimits = await this.limitService.getWarningLimits(usageMap);
    } catch (error) {
      console.error(TAG, `刷新数据失败: ${JSON.stringify(error)}`);
    } finally {
      this.isLoading = false;
    }
  }

  @Builder
  TabBuilder(title: ResourceStr, index: number, count: number) {
    Column() {
      // Resource 不能拼进模板字符串（它没有 .value 属性），拆成两个 Text
      Row({ space: 2 }) {
        Text(title)
          .fontSize(13)
          .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.activeTab === index ? '#007DFF' : '#666666')

        Text(`(${count})`)
          .fontSize(13)
          .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.activeTab === index ? '#007DFF' : '#666666')
      }
    }
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.Center)
    .border({
      width: { bottom: this.activeTab === index ? 2 : 0 },
      color: { bottom: '#007DFF' }
    })
    .onClick(() => {
      this.activeTab = index;
    })
  }

  @Builder
  ChangeBadge(value: number) {
    if (value !== 0) {
      Text(value > 0 ? `+${value}` : `${value}`)
        .fontSize(10)
        .fontColor('#FFFFFF')
        .padding({ left: 4, right: 4 })
        .height(16)
        .backgroundColor(value > 0 ? '#4ECDC4' : '#FF6B6B')
        .borderRadius(8)
    }
  }

  @Builder
  LimitAlert() {
    if (this.exceededLimits.length > 0) {
      Row({ space: 8 }) {
        Text('⚠️')
          .fontSize(16)
        Text(`${this.exceededLimits.length}个应用已超出使用限额`)
          .fontSize(13)
          .fontColor('#FF6B6B')
          .layoutWeight(1)

        Button('查看')
          .fontSize(12)
          .fontColor('#007DFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.pushUrl({ url: 'pages/LimitPage' });
          })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFF5F5')
      .borderRadius(8)
      .margin({ left: 16, right: 16, bottom: 8 })
    } else if (this.warningLimits.length > 0) {
      Row({ space: 8 }) {
        Text('⚡')
          .fontSize(16)
        Text(`${this.warningLimits.length}个应用即将达到使用限额`)
          .fontSize(13)
          .fontColor('#FFA500')
          .layoutWeight(1)

        Button('查看')
          .fontSize(12)
          .fontColor('#007DFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.pushUrl({ url: 'pages/LimitPage' });
          })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFBE6')
      .borderRadius(8)
      .margin({ left: 16, right: 16, bottom: 8 })
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text($r('app.string.app_name'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Blank()

        // 限额入口
        Button() {
          Text('🛡️')
            .fontSize(16)
        }
        .width(36)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.pushUrl({ url: 'pages/LimitPage' });
        })

        // 分享入口
        Button() {
          Text('📤')
            .fontSize(16)
        }
        .width(36)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.pushUrl({ url: 'pages/SharePage' });
        })

        // 设置入口
        Button() {
          Text('⚙️')
            .fontSize(16)
        }
        .width(36)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.pushUrl({ url: 'pages/Settings' });
        })

        // 刷新按钮
        Button() {
          Text('🔄')
            .fontSize(16)
        }
        .width(36)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.dataService.clearCache();
          this.refreshData();
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 4 })

      // 限额提醒
      this.LimitAlert()

      // 时间粒度选择
      Row({ space: 8 }) {
        this.GranularityButton(TimeGranularity.DAILY, $r('app.string.today'));
        this.GranularityButton(TimeGranularity.WEEKLY, $r('app.string.last_7_days'));
        this.GranularityButton(TimeGranularity.MONTHLY, $r('app.string.last_30_days'));
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 12 })

      // 统计概览卡片
      Row({ space: 12 }) {
        StatCard({
          label: $r('app.string.high_frequency'),
          value: this.sortResult.highFrequencyApps.length.toString(),
          color: '#FF6B6B'
        })
        StatCard({
          label: $r('app.string.medium_frequency'),
          value: this.sortResult.mediumFrequencyApps.length.toString(),
          color: '#4ECDC4'
        })
        StatCard({
          label: $r('app.string.low_frequency'),
          value: this.sortResult.lowFrequencyApps.length.toString(),
          color: '#95A5A6'
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      // 历史对比（如果有）
      if (this.comparison.hasHistory) {
        Row({ space: 8 }) {
          Text($r('app.string.comparison'))
            .fontSize(12)
            .fontColor('#666666')

          this.ChangeBadge(this.comparison.highChange)
          this.ChangeBadge(this.comparison.mediumChange)
          this.ChangeBadge(this.comparison.lowChange)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })
      }

      // 加载指示器
      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .color('#007DFF')
          .margin({ top: 8, bottom: 8 })
      }

      // Tab 切换
      Tabs({ barPosition: BarPosition.Start, index: this.activeTab }) {
        TabContent() {
          this.AppList(this.sortResult.highFrequencyApps, $r('app.string.suggest_home'), $r('app.string.no_data_high'))
        }
        .tabBar(this.TabBuilder($r('app.string.high_frequency'), 0, this.sortResult.highFrequencyApps.length))

        TabContent() {
          this.AppList(this.sortResult.mediumFrequencyApps, $r('app.string.suggest_folder'), $r('app.string.no_data_medium'))
        }
        .tabBar(this.TabBuilder($r('app.string.medium_frequency'), 1, this.sortResult.mediumFrequencyApps.length))

        TabContent() {
          this.AppList(this.sortResult.lowFrequencyApps, $r('app.string.suggest_hide'), $r('app.string.no_data_low'))
        }
        .tabBar(this.TabBuilder($r('app.string.low_frequency'), 2, this.sortResult.lowFrequencyApps.length))
      }
      .width('100%')
      .layoutWeight(1)
      .barHeight(44)
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.activeTab = index;
      })

      // 底部操作栏
      Row() {
        Button($r('app.string.generate_suggestion'))
          .width('100%')
          .height(48)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .fontSize(15)
          .onClick(() => {
            this.suggestionDialogController = new CustomDialogController({
              builder: SortSuggestionDialog({ sortResult: this.sortResult }),
              autoCancel: true,
              alignment: DialogAlignment.Bottom,
              offset: { dx: 0, dy: -20 }
            });
            this.suggestionDialogController.open();
          })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F7')
  }

  @Builder
  GranularityButton(granularity: TimeGranularity, label: Resource | string) {
    Button(label)
      .fontSize(12)
      .height(32)
      .backgroundColor(this.currentGranularity === granularity ? '#007DFF' : '#FFFFFF')
      .fontColor(this.currentGranularity === granularity ? '#FFFFFF' : '#333333')
      .border({ width: 1, color: this.currentGranularity === granularity ? '#007DFF' : '#DDDDDD' })
      .borderRadius(16)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.currentGranularity = granularity;
        this.refreshData();
      })
  }

  @Builder
  AppList(apps: AppUsageInfo[], hint: Resource | string, emptyHint: Resource | string) {
    Column() {
      if (apps.length === 0) {
        Column({ space: 8 }) {
          Text($r('app.string.no_data'))
            .fontSize(16)
            .fontColor('#999999')
          Text(emptyHint)
            .fontSize(12)
            .fontColor('#CCCCCC')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Text(hint)
          .fontSize(12)
          .fontColor('#999999')
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 8 })

        List({ space: 8 }) {
          ForEach(apps, (app: AppUsageInfo, index: number) => {
            ListItem() {
              AppCard({ app: app, index: index })
            }
            .onClick(() => {
              router.pushUrl({
                url: 'pages/AppDetail',
                params: { bundleName: app.bundleName, appName: app.appName }
              });
            })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .lanes(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
  }
}
