/** 全屏图片查看器：多图滑动 + 双指缩放 + 双击放大 + 放大后拖动 */
@Component
export struct ImageViewerPage {
  /** 格式："index||url1|url2|..." */
  param: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State urls: string[] = [];
  @State index: number = 0;
  @State zoom: number = 1;
  @State offX: number = 0;
  @State offY: number = 0;
  @State chromeVisible: boolean = true;
  private baseZoom: number = 1;
  private dragStartX: number = 0;
  private dragStartY: number = 0;
  private dragBaseX: number = 0;
  private dragBaseY: number = 0;
  private boxW: number = 360;
  private boxH: number = 720;

  aboutToAppear(): void {
    const parts: string[] = this.param.split('||');
    if (parts.length >= 2) {
      let idx: number = 0;
      const parsed: number = Number.parseInt(parts[0]);
      if (!Number.isNaN(parsed)) {
        idx = parsed;
      }
      const list: string[] = [];
      for (const u of parts[1].split('|')) {
        if (u.length > 0) {
          list.push(u);
        }
      }
      this.urls = list;
      this.index = idx >= 0 && idx < list.length ? idx : 0;
    }
  }

  private resetZoom(animated: boolean): void {
    if (animated) {
      this.getUIContext().animateTo({ duration: 180, curve: Curve.FastOutSlowIn }, () => {
        this.zoom = 1;
        this.offX = 0;
        this.offY = 0;
      });
    } else {
      this.zoom = 1;
      this.offX = 0;
      this.offY = 0;
    }
  }

  private clampOffsets(): void {
    const maxX: number = this.boxW * (this.zoom - 1) / 2;
    const maxY: number = this.boxH * (this.zoom - 1) / 2;
    if (this.offX > maxX) {
      this.offX = maxX;
    }
    if (this.offX < -maxX) {
      this.offX = -maxX;
    }
    if (this.offY > maxY) {
      this.offY = maxY;
    }
    if (this.offY < -maxY) {
      this.offY = -maxY;
    }
  }

  /** 放大状态下的单指拖动（未放大时交给 Swiper 翻页） */
  private onImageTouch(e: TouchEvent): void {
    if (this.zoom <= 1.01) {
      return;
    }
    if (e.type === TouchType.Down) {
      if (e.touches.length !== 1) {
        return;
      }
      this.dragStartX = e.touches[0].windowX;
      this.dragStartY = e.touches[0].windowY;
      this.dragBaseX = this.offX;
      this.dragBaseY = this.offY;
    } else if (e.type === TouchType.Move) {
      if (e.touches.length !== 1) {
        return;
      }
      this.offX = this.dragBaseX + (e.touches[0].windowX - this.dragStartX);
      this.offY = this.dragBaseY + (e.touches[0].windowY - this.dragStartY);
      this.clampOffsets();
    }
  }

  @Builder
  ZoomableImage(url: string) {
    Image(url)
      .width('100%')
      .height('100%')
      .objectFit(ImageFit.Contain)
      .scale({ x: this.zoom, y: this.zoom })
      .translate({ x: this.offX, y: this.offY })
      .onTouch((e: TouchEvent) => {
        this.onImageTouch(e);
      })
      .gesture(
        GestureGroup(
          GestureMode.Exclusive,
          TapGesture({ count: 2 })
            .onAction(() => {
              if (this.zoom > 1.01) {
                this.resetZoom(true);
              } else {
                this.getUIContext().animateTo({ duration: 200, curve: Curve.FastOutSlowIn }, () => {
                  this.zoom = 2.5;
                });
              }
            }),
          PinchGesture({ fingers: 2 })
            .onActionStart(() => {
              this.baseZoom = this.zoom;
            })
            .onActionUpdate((event: GestureEvent) => {
              let s: number = this.baseZoom * event.scale;
              if (s < 1) {
                s = 1;
              }
              if (s > 5) {
                s = 5;
              }
              this.zoom = s;
              this.clampOffsets();
            })
            .onActionEnd(() => {
              if (this.zoom < 1.05) {
                this.resetZoom(true);
              }
            })
        )
      )
  }

  build() {
    NavDestination() {
      Stack() {
        Swiper() {
          ForEach(this.urls, (u: string) => {
            Stack() {
              this.ZoomableImage(u)
            }
            .width('100%')
            .height('100%')
          }, (u: string, i: number) => `img_${i}_${u}`)
        }
        .index(this.index)
        .loop(false)
        .indicator(false)
        .disableSwipe(this.zoom > 1.01)
        .backgroundColor(Color.Black)
        .width('100%')
        .height('100%')
        .onChange((i: number) => {
          this.index = i;
          this.resetZoom(false);
        })
        .onAreaChange((oldArea: Area, newArea: Area) => {
          this.boxW = newArea.width as number;
          this.boxH = newArea.height as number;
        })

        if (this.chromeVisible) {
          Row() {
            Text('✕')
              .fontSize(20)
              .fontColor(Color.White)
              .width(40)
              .height(40)
              .textAlign(TextAlign.Center)
              .borderRadius(20)
              .backgroundColor('#66000000')
              .onClick(() => {
                this.pageStack.pop();
              })
            Blank()
            Text(`${this.index + 1} / ${this.urls.length}`)
              .fontSize(14)
              .fontColor(Color.White)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(14)
              .backgroundColor('#66000000')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 48 })
          .position({ x: 0, y: 0 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .onClick(() => {
        this.chromeVisible = !this.chromeVisible;
      })
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Black)
  }
}
