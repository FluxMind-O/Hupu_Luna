export enum LoadState {
  Loading,
  Empty,
  Error,
  Ready
}

/**
 * 列表/页面三态组件：Loading / Empty / Error（Error 带重试）
 */
@Component
export struct StateView {
  @Prop state: LoadState = LoadState.Loading;
  @Prop message: string = '';
  onRetry: () => void = () => {
  };

  build() {
    Column({ space: 12 }) {
      if (this.state === LoadState.Loading) {
        LoadingProgress()
          .width(44)
          .height(44)
          .color($r('app.color.text_secondary'))
        Text('正在加载…')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      } else if (this.state === LoadState.Empty) {
        Text(this.message.length > 0 ? this.message : '这里还没有内容')
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
      } else if (this.state === LoadState.Error) {
        Text(this.message.length > 0 ? this.message : '加载失败，请检查网络后重试')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
        Button('重试')
          .fontSize(14)
          .backgroundColor($r('app.color.brand_primary'))
          .onClick(() => {
            this.onRetry();
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }
}
