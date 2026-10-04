import { HupuApi } from '../network/HupuApi';
import { ThreadListItem, ThreadListPage, TopicInfo } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, FontSize, Radius, RouteName } from '../common/Theme';
import { compactCount } from '../views/TagChip';
import { thumbUrl } from '../common/Utils';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { AppNavBar } from '../views/AppNavBar';

/**
 * 专区页（对齐官方形态）：
 * - 头部：专区背景图（放大铺满 + 暗化蒙层）+ 头像 + 名称 + 热度 + 版主 + 话题介绍
 * - 列表：PC 话题页分页（/ {topicId}-{N}），支持无限下滑
 * - 底部：立即发布（预选本专区，直接进入发帖页）
 */
@Component
export struct TopicThreadsPage {
  /** 格式："topicId|板块名" */
  param: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State topicName: string = '';
  @State info: TopicInfo = new TopicInfo();
  @State items: ThreadListItem[] = [];
  @State state: LoadState = LoadState.Loading;
  @State hasMore: boolean = true;
  private topicId: number = 0;
  private pageIndex: number = 0;
  private loadingMore: boolean = false;

  aboutToAppear(): void {
    const parts: string[] = this.param.split('|');
    if (parts.length > 0) {
      this.topicId = Number(parts[0]);
    }
    if (parts.length > 1) {
      this.topicName = parts[1];
    }
    this.loadInfo();
    this.loadFirst();
  }

  /** 专区信息（背景图/简介/热度/版主）：失败静默，不影响帖子列表展示 */
  private async loadInfo(): Promise<void> {
    if (this.topicId <= 0) {
      return;
    }
    try {
      this.info = await HupuApi.getTopicInfo(this.topicId);
      // 导航栏标题优先用接口返回的规范名称
      if (this.info.name.length > 0) {
        this.topicName = this.info.name;
      }
    } catch (e) {
    }
  }

  private async loadFirst(): Promise<void> {
    this.state = LoadState.Loading;
    try {
      const res: ThreadListPage = await HupuApi.getForumThreads(this.topicId, 1);
      this.items = res.items;
      this.pageIndex = 1;
      this.hasMore = res.hasMore;
      this.state = this.items.length > 0 ? LoadState.Ready : LoadState.Empty;
    } catch (e) {
      this.state = LoadState.Error;
    }
  }

  private async loadMore(): Promise<void> {
    if (this.loadingMore || !this.hasMore || this.state !== LoadState.Ready) {
      return;
    }
    this.loadingMore = true;
    try {
      const res: ThreadListPage = await HupuApi.getForumThreads(this.topicId, this.pageIndex + 1);
      this.items = this.items.concat(res.items);
      this.pageIndex = this.pageIndex + 1;
      this.hasMore = res.hasMore;
    } catch (e) {
      // 风控/网络异常：停止翻页（保留已加载内容），避免持续触发风控
      this.hasMore = false;
    }
    this.loadingMore = false;
  }

  private openThread(tid: string): void {
    if (tid.length > 0) {
      this.pageStack.pushPathByName(RouteName.POST_DETAIL, tid);
    }
  }

  /** 进入发帖页（预选本专区） */
  private openCreate(): void {
    this.pageStack.pushPathByName(RouteName.CREATE_THREAD, `${this.topicId}|${this.topicName}`);
  }

  /** 专区头部：背景图 + 头像 + 名称 + 热度 + 版主 */
  @Builder
  TopicHeader() {
    Column() {
      // 背景区：方形 LOGO 放大铺满 + 自下而上暗化，保证前景文字可读
      Stack({ alignContent: Alignment.BottomStart }) {
        if (this.info.bannerUrl.length > 0) {
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: thumbUrl(this.info.bannerUrl, 720),
              objectFit: ImageFit.Cover
            }
          })
            .width('100%')
            .height(160)
        } else {
          Column()
            .width('100%')
            .height(160)
            .backgroundColor($r('app.color.brand_primary'))
        }
        // 暗化蒙层（透明 → 深色，确保底部文字清晰）
        Column()
          .width('100%')
          .height(160)
          .linearGradient({
            angle: 180,
            colors: [['#00000000', 0.0], ['#33000000', 0.45], ['#CC000000', 1.0]]
          })

        Row({ space: 12 }) {
          if (this.info.bannerUrl.length > 0) {
            ImageKnifeComponent({
              imageKnifeOption: {
                loadSrc: thumbUrl(this.info.bannerUrl, 160),
                objectFit: ImageFit.Cover,
                border: { radius: 10 }
              }
            })
              .width(52)
              .height(52)
          }
          Column({ space: 5 }) {
            Text(this.topicName.length > 0 ? this.topicName : '专区')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Row({ space: 10 }) {
              if (this.info.heat.length > 0) {
                Text(`🔥 ${this.info.heat}`)
                  .fontSize(11)
                  .fontColor('#E6FFFFFF')
              }
              if (this.info.moderators.length > 0) {
                Text(`版主 ${this.info.moderators.join('、')}`)
                  .fontSize(11)
                  .fontColor('#E6FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: Spacing.lg, right: Spacing.lg, bottom: 12 })
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .height(160)

      // 话题介绍
      if (this.info.desc.length > 0) {
        Row({ space: 8 }) {
          Text('简介')
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor($r('app.color.tag_bg'))
            .borderRadius(4)
          Text(this.info.desc)
            .fontSize(12)
            .lineHeight(18)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .padding({ left: Spacing.lg, right: Spacing.lg, top: 10, bottom: 10 })
        .backgroundColor($r('app.color.bg_card'))
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  ThreadRow(item: ThreadListItem) {
    Column({ space: 6 }) {
      Text(item.title)
        .fontSize(FontSize.title)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Row({ space: 10 }) {
        Text(item.userName)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(item.time)
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
        if (item.replies > 0) {
          Text(`${compactCount(item.replies)} 回复`)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
        }
        if (item.visits > 0) {
          Text(`${compactCount(item.visits)} 浏览`)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
        }
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.bg_card'))
    .onClick(() => {
      this.openThread(item.tid);
    })
  }

  /**
   * 底部发布条（对齐官方形态：居中「✎ 立即发布」红字，无按钮底色）
   */
  @Builder
  PublishBar() {
    Row({ space: 6 }) {
      SymbolGlyph($r('sys.symbol.pencil_line'))
        .fontSize(18)
        .fontColor([$r('app.color.brand_primary')])
      Text('立即发布')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.brand_primary'))
    }
    .width('100%')
    .height(52)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.bg_card'))
    .onClick(() => {
      this.openCreate();
    })
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: this.topicName.length > 0 ? this.topicName : '专区' })
        if (this.state === LoadState.Ready) {
          Column() {
            List({ space: 0 }) {
              ListItem() {
                this.TopicHeader()
              }
              .margin({ bottom: Spacing.sm })

              ForEach(this.items, (item: ThreadListItem) => {
                ListItem() {
                  Column() {
                    this.ThreadRow(item)
                    Divider().color($r('app.color.divider'))
                  }
                }
              }, (item: ThreadListItem, idx: number) => `${item.tid}_${idx}`)

              ListItem() {
                Text(this.hasMore ? '上拉加载更多' : '已经到底了')
                  .fontSize(12)
                  .fontColor($r('app.color.text_tertiary'))
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 16, bottom: 24 })
              }
            }
            .onReachEnd(() => {
              this.loadMore();
            })
            .cachedCount(3)
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .backgroundColor($r('app.color.bg_page'))

            Divider().color($r('app.color.divider'))
            this.PublishBar()
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          StateView({
            state: this.state,
            onRetry: () => {
              this.loadInfo();
              this.loadFirst();
            }
          })
            .width('100%')
            .layoutWeight(1)
            .backgroundColor($r('app.color.bg_page'))
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
