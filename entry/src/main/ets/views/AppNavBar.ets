import { SymbolGlyphModifier } from '@kit.ArkUI';

/**
 * 二级页面自绘标题栏（NavDestination 专用）。
 * 背景：窗口为全屏沉浸式布局（setWindowLayoutFullScreen(true)），
 * NavDestination 默认标题栏在该布局下不避让状态栏，导致标题与系统时间重叠。
 * 统一改为 hideTitleBar(true) + 本组件自绘：手动避让状态栏 + 返回键 + 标题。
 */
@Component
export struct AppNavBar {
  @Prop title: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('topAvoidPx') topAvoidPx: number = 0;

  build() {
    Row({ space: 4 }) {
      // 返回键
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.text_primary')])
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.pageStack.pop();
      })

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .constraintSize({ minHeight: 44 })
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({
      left: 8,
      right: 16,
      top: px2vp(this.topAvoidPx) + 4,
      bottom: 4
    })
  }
}
