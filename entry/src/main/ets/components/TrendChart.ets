/**
 * 趋势折线图组件
 * 使用 ArkUI 原生组件绘制简单折线图
 */

interface ChartDataPoint {
  label: string;
  value: number;
  color?: string;
}

@Component
export struct TrendChart {
  @Prop data: ChartDataPoint[] = [];
  @Prop title: string = '趋势图';
  @Prop maxValue: number = 0;
  @Prop barColor: string = '#007DFF';
  // 不能叫 height：会和 CustomComponent 自带的 height 属性冲突
  @Prop chartHeight: number = 180;

  private computedMax(): number {
    if (this.maxValue > 0) {
      return this.maxValue;
    }
    // ArkTS 对 Math.max(...arr) 支持受限，改显式循环
    let max: number = 1;
    for (let i = 0; i < this.data.length; i++) {
      if (this.data[i].value > max) {
        max = this.data[i].value;
      }
    }
    return Math.ceil(max * 1.1);
  }

  build() {
    Column({ space: 8 }) {
      if (this.data.length > 0) {
        // 图表区域
        Stack({ alignContent: Alignment.BottomStart }) {
          // 背景网格线
          Column({ space: 0 }) {
            ForEach([1, 2, 3], (gridLine: number, index: number) => {
              Row()
                .width('100%')
                .height(1)
                .backgroundColor('#EEEEEE')
                .layoutWeight(1)
            })
          }
          .width('100%')
          .height(this.chartHeight)

          // 柱状图 + 折线
          Row() {
            ForEach(this.data, (item: ChartDataPoint, index: number) => {
              Column() {
                // 数值标签（只在有足够空间时显示）
                if (this.data.length <= 14) {
                  Text(`${item.value}`)
                    .fontSize(9)
                    .fontColor('#999999')
                    .margin({ bottom: 2 })
                    .visibility(item.value > 0 ? Visibility.Visible : Visibility.Hidden)
                }

                // 柱子
                Column() {
                  Row()
                    .width('60%')
                    .height(`${Math.min((item.value / this.computedMax()) * 100, 100)}%`)
                    .backgroundColor(item.color || this.barColor)
                    .borderRadius({ topLeft: 3, topRight: 3 })
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.End)

                // X轴标签
                Text(item.label)
                  .fontSize(9)
                  .fontColor('#999999')
                  .margin({ top: 4 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width(`${100 / this.data.length}%`)
              .height('100%')
              .justifyContent(FlexAlign.End)
            })
          }
          .width('100%')
          .height(this.chartHeight)
        }
        .width('100%')

        // 图例
        Row({ space: 16 }) {
          Row({ space: 4 }) {
            Row()
              .width(12)
              .height(12)
              .backgroundColor(this.barColor)
              .borderRadius(2)
            Text(this.title)
              .fontSize(12)
              .fontColor('#666666')
          }

          Text(`最大值: ${this.computedMax()}`)
            .fontSize(11)
            .fontColor('#999999')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 4, right: 4 })
      } else {
        Column() {
          Text('暂无数据')
            .fontSize(14)
            .fontColor('#CCCCCC')
        }
        .width('100%')
        .height(this.chartHeight)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
  }
}
