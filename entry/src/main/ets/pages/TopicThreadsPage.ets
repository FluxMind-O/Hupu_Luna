import { HupuApi } from '../network/HupuApi';
import { ThreadListItem } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, FontSize, RouteName } from '../common/Theme';
import { compactCount } from '../views/TagChip';
import { AppNavBar } from '../views/AppNavBar';

@Component
export struct TopicThreadsPage {
  /** 格式："topicId|板块名" */
  param: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State topicName: string = '';
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
    this.loadFirst();
  }

  private async loadFirst(): Promise<void> {
    this.state = LoadState.Loading;
    try {
      const res = await HupuApi.getTopicThreads(this.topicId, 1, '');
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
      const res = await HupuApi.getTopicThreads(this.topicId, this.pageIndex + 1, '');
      this.items = this.items.concat(res.items);
      this.pageIndex = this.pageIndex + 1;
      this.hasMore = res.hasMore;
    } catch (e) {
    }
    this.loadingMore = false;
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: this.topicName.length > 0 ? this.topicName : '板块' })
        if (this.state === LoadState.Ready) {
        List({ space: 0 }) {
          ForEach(this.items, (item: ThreadListItem) => {
            ListItem() {
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
                  Text(`${compactCount(item.replies)} 回复`)
                    .fontSize(11)
                    .fontColor($r('app.color.text_tertiary'))
                  Text(`${compactCount(item.recommendCount)} 亮`)
                    .fontSize(11)
                    .fontColor($r('app.color.text_tertiary'))
                }
                .width('100%')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding({ left: Spacing.lg, right: Spacing.lg, top: 12, bottom: 12 })
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
        .backgroundColor($r('app.color.bg_page'))
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
          .backgroundColor($r('app.color.bg_page'))
      }
      }
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
