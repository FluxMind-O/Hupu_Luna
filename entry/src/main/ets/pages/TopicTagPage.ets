import { HupuApi } from '../network/HupuApi';
import { ThreadListItem, ThreadListPage } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, FontSize, Radius, RouteName } from '../common/Theme';
import { thumbUrl } from '../common/Utils';
import { compactCount } from '../views/TagChip';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { AppNavBar } from '../views/AppNavBar';

/** 热榜话题下的帖子流 */
@Component
export struct TopicTagPage {
  /** 格式："tagId|tagName" */
  param: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State tagName: string = '';
  @State items: ThreadListItem[] = [];
  @State state: LoadState = LoadState.Loading;
  @State hasMore: boolean = true;
  private tagId: number = 0;
  private tagType: number = 1;
  private pageIndex: number = 0;
  private cursor: string = '';
  private loadingMore: boolean = false;

  aboutToAppear(): void {
    const parts: string[] = this.param.split('|');
    if (parts.length > 0) {
      this.tagId = Number(parts[0]);
    }
    if (parts.length > 1) {
      this.tagName = parts[1];
    }
    this.loadFirst();
  }

  private async loadFirst(): Promise<void> {
    this.state = LoadState.Loading;
    try {
      let res: ThreadListPage = await HupuApi.getTagThreads(this.tagId, 1, 1, '');
      if (res.items.length === 0) {
        // tagType=1 无数据时回退到 2
        this.tagType = 2;
        res = await HupuApi.getTagThreads(this.tagId, 2, 1, '');
      }
      this.items = res.items;
      this.pageIndex = 1;
      this.cursor = res.cursor;
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
      const res: ThreadListPage = await HupuApi.getTagThreads(this.tagId, this.tagType, this.pageIndex + 1, this.cursor);
      this.items = this.items.concat(res.items);
      this.pageIndex = this.pageIndex + 1;
      this.cursor = res.cursor;
      this.hasMore = res.hasMore;
    } catch (e) {
    }
    this.loadingMore = false;
  }

  @Builder
  ThreadRow(item: ThreadListItem) {
    Row({ space: 10 }) {
      Column({ space: 6 }) {
        Text(item.title)
          .fontSize(FontSize.title)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row({ space: 8 }) {
          Text(item.userName)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(item.time)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
          Text(`${compactCount(item.replies)} 回复`)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
          Text(`${compactCount(item.recommendCount)} 亮`)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (item.coverUrl.length > 0) {
        Stack({ alignContent: Alignment.BottomEnd }) {
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: thumbUrl(item.coverUrl, 240),
              objectFit: ImageFit.Cover,
              border: { radius: Radius.sm }
            }
          })
            .width(96)
            .height(72)
          if (item.isVideo) {
            Text(item.videoDuration.length > 0 ? item.videoDuration : '视频')
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor('#80000000')
              .borderRadius(3)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin(4)
          }
        }
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 12, bottom: 12 })
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: this.tagName.length > 0 ? this.tagName : '话题' })
        if (this.state === LoadState.Ready) {
        List({ space: 0 }) {
          ForEach(this.items, (item: ThreadListItem) => {
            ListItem() {
              Column() {
                this.ThreadRow(item)
                Divider().color($r('app.color.divider'))
              }
              .padding({ left: Spacing.lg, right: Spacing.lg })
              .backgroundColor($r('app.color.bg_card'))
              .onClick(() => {
                this.pageStack.pushPathByName(RouteName.POST_DETAIL, item.tid);
              })
            }
          }, (item: ThreadListItem) => item.tid)
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
      } else {
        StateView({
          state: this.state,
          onRetry: () => {
            this.loadFirst();
          }
        })
          .width('100%')
          .layoutWeight(1)
      }
      }
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
