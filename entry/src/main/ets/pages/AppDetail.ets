import { AppDataService } from '../service/AppDataService';
import { TrendPoint } from '../model/Types';
import { DateUtil } from '../utils/DateUtil';
import { TrendChart } from '../components/TrendChart';
import router from '@ohos.router';

const TAG = 'AppDetailPage';

interface ChartPoint {
  label: string;
  value: number;
  color?: string;
}

@Entry
@Component
struct AppDetail {
  @State bundleName: string = '';
  @State appName: string = '';
  @State trendData: TrendPoint[] = [];
  @State isLoading: boolean = true;

  private dataService: AppDataService = AppDataService.getInstance();

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.bundleName = params['bundleName'] || '';
      this.appName = params['appName'] || '';
      this.loadTrend();
    }
  }

  async loadTrend() {
    this.isLoading = true;
    try {
      this.trendData = await this.dataService.getAppTrend(this.bundleName, 7);
    } catch (error) {
      console.error(TAG, `加载趋势失败: ${JSON.stringify(error)}`);
    } finally {
      this.isLoading = false;
    }
  }

  // 转换趋势数据为图表数据（启动次数）
  getCountChartData(): ChartPoint[] {
    const out: ChartPoint[] = [];
    for (let i = 0; i < this.trendData.length; i++) {
      const p: ChartPoint = {
        label: this.trendData[i].date,
        value: this.trendData[i].count,
        color: '#007DFF'
      };
      out.push(p);
    }
    return out;
  }

  // 转换趋势数据为图表数据（使用时长 → 分钟）
  getTimeChartData(): ChartPoint[] {
    const out: ChartPoint[] = [];
    for (let i = 0; i < this.trendData.length; i++) {
      const p: ChartPoint = {
        label: this.trendData[i].date,
        value: Math.round(this.trendData[i].time / (60 * 1000)), // 毫秒转分钟
        color: '#4ECDC4'
      };
      out.push(p);
    }
    return out;
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

        Text(this.appName)
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

      // 包名
      Text(this.bundleName)
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ bottom: 16 })

      // 内容区域
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
      } else if (this.trendData.length === 0) {
        Column() {
          Text('暂无使用数据')
            .fontSize(16)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            // 启动次数趋势图
            Column({ space: 8 }) {
              Text('📈 启动次数趋势')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              TrendChart({
                data: this.getCountChartData(),
                title: '每日启动次数',
                barColor: '#007DFF',
                chartHeight: 160
              })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })

            // 使用时长趋势图
            Column({ space: 8 }) {
              Text('⏱️ 使用时长趋势')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              TrendChart({
                data: this.getTimeChartData(),
                title: '每日使用时长（分钟）',
                barColor: '#4ECDC4',
                chartHeight: 160
              })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })

            // 趋势数据表格
            Column({ space: 8 }) {
              Text('📊 详细数据')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              Row() {
                Text('日期')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .width('30%')

                Text('启动次数')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .width('25%')
                  .textAlign(TextAlign.Center)

                Text('使用时长')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .width('25%')
                  .textAlign(TextAlign.Center)

                Text('趋势')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .width('20%')
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .height(40)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#F0F0F0')
              .borderRadius({ topLeft: 8, topRight: 8 })

              ForEach(this.trendData, (item: TrendPoint, index: number) => {
                Row() {
                  Text(item.date)
                    .fontSize(13)
                    .width('30%')

                  Text(`${item.count}次`)
                    .fontSize(13)
                    .width('25%')
                    .textAlign(TextAlign.Center)

                  Text(DateUtil.formatDuration(item.time))
                    .fontSize(13)
                    .width('25%')
                    .textAlign(TextAlign.Center)

                  // 简单柱状图
                  Row() {
                    if (item.count > 0) {
                      Row()
                        .width(`${Math.min(item.count * 10, 100)}%`)
                        .height(10)
                        .backgroundColor('#007DFF')
                        .borderRadius(5)
                    }
                  }
                  .width('20%')
                  .height(10)
                  .backgroundColor('#EEEEEE')
                  .borderRadius(5)
                }
                .width('100%')
                .height(44)
                .padding({ left: 12, right: 12 })
                .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#FAFAFA')
              })
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
            .padding({ top: 0, bottom: 8 })

            // 统计说明
            Column({ space: 8 }) {
              Text('📋 数据说明')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              Text('· 数据来自系统 UsageStats 服务')
                .fontSize(13)
                .fontColor('#666666')
                .width('100%')

              Text('· 统计周期为最近7天')
                .fontSize(13)
                .fontColor('#666666')
                .width('100%')

              Text('· 图表展示每日启动次数和使用时长趋势')
                .fontSize(13)
                .fontColor('#666666')
                .width('100%')
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F7')
  }
}
