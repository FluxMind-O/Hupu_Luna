import { HupuApi } from '../network/HupuApi';
import { SearchItem } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, FontSize, RouteName } from '../common/Theme';
import { formatTime } from '../common/Utils';
import { compactCount } from '../views/TagChip';
import { AppNavBar } from '../views/AppNavBar';

@Component
export struct SearchPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State keyword: string = '';
  @State items: SearchItem[] = [];
  @State state: LoadState = LoadState.Empty;
  @State searched: boolean = false;
  @State hasMore: boolean = false;
  private pageIndex: number = 0;
  private loadingMore: boolean = false;

  private async doSearch(): Promise<void> {
    const kw: string = this.keyword.trim();
    if (kw.length === 0) {
      return;
    }
    this.searched = true;
    this.state = LoadState.Loading;
    try {
      const res = await HupuApi.search(kw, 1);
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
    const kw: string = this.keyword.trim();
    if (kw.length === 0) {
      return;
    }
    this.loadingMore = true;
    try {
      const res = await HupuApi.search(kw, this.pageIndex + 1);
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
        AppNavBar({ title: '搜索' })
        Row({ space: 8 }) {
          TextInput({ placeholder: '搜索虎扑帖子', text: $$this.keyword })
            .layoutWeight(1)
            .height(38)
            .fontSize(14)
          Button('搜索')
            .fontSize(13)
            .height(38)
            .backgroundColor($r('app.color.brand_primary'))
            .onClick(() => {
              this.doSearch();
            })
        }
        .width('100%')
        .padding({ left: Spacing.lg, right: Spacing.lg, top: 8, bottom: 8 })

        if (this.searched) {
          if (this.state === LoadState.Ready) {
            List({ space: 0 }) {
              ForEach(this.items, (item: SearchItem) => {
                ListItem() {
                  Column({ space: 6 }) {
                    Text(item.title)
                      .fontSize(FontSize.title)
                      .fontColor($r('app.color.text_primary'))
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                    if (item.summary.length > 0) {
                      Text(item.summary)
                        .fontSize(13)
                        .fontColor($r('app.color.text_secondary'))
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                    }
                    Row({ space: 10 }) {
                      if (item.forumName.length > 0) {
                        Text(item.forumName)
                          .fontSize(11)
                          .fontColor($r('app.color.brand_primary'))
                          .maxLines(1)
                      }
                      Text(item.userName)
                        .fontSize(11)
                        .fontColor($r('app.color.text_tertiary'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)
                      Text(`${compactCount(item.replies)} 回复`)
                        .fontSize(11)
                        .fontColor($r('app.color.text_tertiary'))
                      Text(formatTime(item.createTime))
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
              }, (item: SearchItem) => item.tid)
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
            .layoutWeight(1)
            .width('100%')
            .scrollBar(BarState.Off)
          } else {
            StateView({
              state: this.state,
              onRetry: () => {
                this.doSearch();
              }
            })
              .layoutWeight(1)
          }
        } else {
          Column({ space: 8 }) {
            Text('输入关键字，搜索虎扑全站帖子')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg_page'))
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
