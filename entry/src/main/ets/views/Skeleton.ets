/** 骨架屏组件：加载中的占位布局（呼吸闪烁） */

function skeletonRange(count: number): number[] {
  const arr: number[] = [];
  for (let i = 0; i < count; i++) {
    arr.push(i);
  }
  return arr;
}

/** 信息流骨架（首页/频道列表加载用） */
@Component
export struct FeedSkeleton {
  @Prop withCover: boolean = true;
  @Prop count: number = 6;
  @State shimmer: number = 0.45;

  aboutToAppear(): void {
    setTimeout(() => {
      try {
        this.getUIContext().animateTo({
          duration: 700,
          iterations: -1,
          playMode: PlayMode.Alternate,
          curve: Curve.EaseInOut
        }, () => {
          this.shimmer = 1.0;
        });
      } catch (e) {
      }
    }, 60);
  }

  @Builder
  Bar(w: string, h: number) {
    Row()
      .width(w)
      .height(h)
      .borderRadius(4)
      .backgroundColor($r('app.color.tag_bg'))
  }

  @Builder
  Card() {
    Row({ space: 10 }) {
      Column({ space: 8 }) {
        this.Bar('100%', 16)
        this.Bar('68%', 16)
        Row({ space: 8 }) {
          this.Bar('30%', 12)
          this.Bar('22%', 12)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.withCover) {
        Row()
          .width(96)
          .height(72)
          .borderRadius(6)
          .backgroundColor($r('app.color.tag_bg'))
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 12, bottom: 12 })
  }

  build() {
    Column() {
      ForEach(skeletonRange(this.count), (n: number) => {
        Column() {
          this.Card()
          Divider().color($r('app.color.divider'))
        }
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.bg_card'))
      }, (n: number) => `sk_${n}`)
    }
    .width('100%')
    .opacity(this.shimmer)
  }
}

/** 帖子详情骨架 */
@Component
export struct DetailSkeleton {
  @State shimmer: number = 0.45;

  aboutToAppear(): void {
    setTimeout(() => {
      try {
        this.getUIContext().animateTo({
          duration: 700,
          iterations: -1,
          playMode: PlayMode.Alternate,
          curve: Curve.EaseInOut
        }, () => {
          this.shimmer = 1.0;
        });
      } catch (e) {
      }
    }, 60);
  }

  @Builder
  Bar(w: string, h: number) {
    Row()
      .width(w)
      .height(h)
      .borderRadius(4)
      .backgroundColor($r('app.color.tag_bg'))
  }

  build() {
    Column({ space: 10 }) {
      this.Bar('92%', 20)
      this.Bar('60%', 20)
      Row({ space: 8 }) {
        this.Bar('24%', 12)
        this.Bar('20%', 12)
      }
      .width('100%')

      Row()
        .width('100%')
        .height(1)
        .backgroundColor($r('app.color.divider'))
        .margin({ top: 6, bottom: 6 })

      this.Bar('100%', 14)
      this.Bar('100%', 14)
      this.Bar('96%', 14)
      this.Bar('88%', 14)
      Row()
        .width('100%')
        .height(150)
        .borderRadius(6)
        .backgroundColor($r('app.color.tag_bg'))
        .margin({ top: 6 })

      ForEach(skeletonRange(3), (n: number) => {
        Column({ space: 8 }) {
          this.Bar('30%', 12)
          this.Bar('100%', 14)
          this.Bar('72%', 14)
        }
        .width('100%')
        .padding({ top: 14, bottom: 6 })
      }, (n: number) => `ds_${n}`)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(10)
    .opacity(this.shimmer)
  }
}
