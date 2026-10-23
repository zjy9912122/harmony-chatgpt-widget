@Entry
@Component
struct ChatGPTCard {
  @Local title: string = 'ChatGPT';
  @Local subtitle: string = '随时开始一段对话';
  @Local prompt: string = '点击打开应用，继续与你的 AI 对话';

  build() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text('✦').fontSize(24).fontColor('#FFFFFF')
        Column({ space: 2 }) {
          Text(this.title)
            .fontSize(19)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
          Text(this.subtitle)
            .fontSize(12)
            .fontColor('#E6FFFFFF')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Text(this.prompt)
        .fontSize(13)
        .fontColor('#F2FFFFFF')
        .width('100%')

      Row() {
        Text('开始对话')
          .fontSize(13)
          .fontColor('#FFFFFF')
        Blank()
        Text('↗').fontSize(16).fontColor('#FFFFFF')
      }
      .padding({ left: 12, right: 12, top: 9, bottom: 9 })
      .width('100%')
      .backgroundColor('#30FFFFFF')
      .borderRadius(14)
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor('#CC202124')
    .border({ width: 1, color: '#40FFFFFF' })
    .borderRadius(22)
    .justifyContent(FlexAlign.Center)
  }
}
