@Component
export struct StatCard {
  // ResourceStr = string | Resource，这样既能传字面量也能传 $r('app.string.xxx')
  @Prop label: ResourceStr;
  @Prop value: string;
  @Prop color: ResourceColor;

  build() {
    Column({ space: 6 }) {
      Text(this.value)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.color)

      Text(this.label)
        .fontSize(12)
        .fontColor('#666666')
    }
    .width('30%')
    .height(90)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
  }
}
