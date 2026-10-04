import { HupuApi } from '../network/HupuApi';
import { ZoneCategory, ZoneTopic } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, FontSize, Radius, RouteName } from '../common/Theme';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const STORE_NAME: string = 'hupluna_settings';
const KEY_MY_TOPICS: string = 'my_topic_ids';

/** 官方社区页形态：左侧分类导航 + 右侧分区区块长列表（滚动联动左侧选中态）+ "我的"收藏区块 */
@Component
export struct CommunityPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State categories: ZoneCategory[] = [];
  @State state: LoadState = LoadState.Loading;
  @State activeIndex: number = -1;
  @State myTopics: ZoneTopic[] = [];
  @State searchMode: boolean = false;
  @State searchKeyword: string = '';
  @State searchResults: ZoneTopic[] = [];
  @StorageLink('topAvoidPx') topAvoidPx: number = 0;
  private ctx: common.Context | null = null;
  private rightScroller: Scroller = new Scroller();
  private leftScroller: Scroller = new Scroller();
  private suppressSync: boolean = false;
  private leftManual: boolean = false;
  private suppressTimer: number = -1;

  aboutToAppear(): void {
    this.ctx = this.getUIContext().getHostContext() as common.Context;
    this.load();
  }

  private getCtx(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  /** 专区搜索：全部分区按关键词过滤 */
  private filterTopics(kw: string): ZoneTopic[] {
    const k: string = kw.trim().toLowerCase();
    if (k.length === 0) {
      return [];
    }
    const list: ZoneTopic[] = [];
    for (const cat of this.categories) {
      for (const t of cat.topics) {
        if (t.topicName.toLowerCase().indexOf(k) >= 0) {
          list.push(t);
        }
      }
    }
    return list;
  }

  private async load(): Promise<void> {
    this.state = LoadState.Loading;
    try {
      const cats = await HupuApi.getZones();
      this.categories = cats;
      await this.loadMyTopics();
      this.state = cats.length > 0 ? LoadState.Ready : LoadState.Empty;
    } catch (e) {
      this.state = LoadState.Error;
    }
  }

  /** 读取"我的分区"收藏（存 topicId，显示时按 zones 匹配） */
  private async loadMyTopics(): Promise<void> {
    try {
      const opt: preferences.Options = { name: STORE_NAME };
      const pref = await preferences.getPreferences(this.getCtx(), opt);
      const v: preferences.ValueType = await pref.get(KEY_MY_TOPICS, '');
      const s: string = v as string;
      const ids: number[] = s.length > 0 ? JSON.parse(s) as number[] : [];
      const list: ZoneTopic[] = [];
      for (const cat of this.categories) {
        for (const t of cat.topics) {
          if (ids.indexOf(t.topicId) >= 0 && list.length < 6) {
            list.push(t);
          }
        }
      }
      this.myTopics = list;
    } catch (e) {
      this.myTopics = [];
    }
  }

  private async saveMyTopics(ids: number[]): Promise<void> {
    try {
      const opt: preferences.Options = { name: STORE_NAME };
      const pref = await preferences.getPreferences(this.getCtx(), opt);
      await pref.put(KEY_MY_TOPICS, JSON.stringify(ids));
      await pref.flush();
    } catch (e) {
    }
  }

  /** 长按分区卡：加入/移出"我的分区" */
  private async toggleMyTopic(topic: ZoneTopic): Promise<void> {
    try {
      const opt: preferences.Options = { name: STORE_NAME };
      const pref = await preferences.getPreferences(this.getCtx(), opt);
      const v: preferences.ValueType = await pref.get(KEY_MY_TOPICS, '');
      const s: string = v as string;
      const ids: number[] = s.length > 0 ? JSON.parse(s) as number[] : [];
      const pos: number = ids.indexOf(topic.topicId);
      if (pos >= 0) {
        ids.splice(pos, 1);
        this.toast(`已移出我的分区：${topic.topicName}`);
      } else {
        if (ids.length >= 6) {
          this.toast('最多收藏 6 个分区');
          return;
        }
        ids.push(topic.topicId);
        this.toast(`已加入我的分区：${topic.topicName}`);
      }
      await this.saveMyTopics(ids);
      await this.loadMyTopics();
    } catch (e) {
    }
  }

  /**
   * 右侧 List 滚动 → 联动左侧选中态。
   * List index：0=我的，i+1=分类 i。first=视口顶部可见项 → 头部过顶即切换，与官方行为一致；
   * 滚到底（last 达最后分类项）强制选中末分类，保证短区块也能被高亮。
   */
  private syncActiveFromList(first: number, last: number): void {
    if (this.suppressSync || this.categories.length === 0) {
      return;
    }
    const len: number = this.categories.length;
    if (last >= len && first >= 1) {
      this.setActive(len - 1);
      return;
    }
    if (first <= 0) {
      this.setActive(-1);
      return;
    }
    this.setActive(first - 1);
  }

  /** 选中态变更（-1=我的）+ 左侧导航滚动到可见 */
  private setActive(i: number): void {
    if (this.activeIndex === i) {
      return;
    }
    this.activeIndex = i;
    this.ensureActiveVisible();
  }

  /** 左侧导航自动滚动让选中项居中可见（用户手动滑动中不干预） */
  private ensureActiveVisible(): void {
    if (this.leftManual) {
      return;
    }
    try {
      const idx: number = this.activeIndex;
      if (idx < -1 || idx >= this.categories.length) {
        return;
      }
      const ui = this.getUIContext();
      const id: string = idx === -1 ? 'zone_cat_my' : 'zone_cat_' + idx;
      const rect = ui.getComponentUtils().getRectangleById(id);
      const area = ui.getComponentUtils().getRectangleById('zone_left_area');
      const areaTop: number = area.windowOffset.y;
      const areaBottom: number = area.windowOffset.y + area.size.height;
      const top: number = rect.windowOffset.y;
      const bottom: number = top + rect.size.height;
      if (top >= areaTop && bottom <= areaBottom) {
        return;
      }
      const cur = this.leftScroller.currentOffset().yOffset;
      const target: number = cur + (top + rect.size.height / 2 - (areaTop + area.size.height / 2));
      this.leftScroller.scrollTo({
        xOffset: 0,
        yOffset: Math.max(0, target),
        animation: { duration: 200, curve: Curve.EaseOut }
      });
    } catch (e) {
    }
  }

  /**
   * 点击左侧栏目（-1=我的）→ 右侧 List 按索引定位区块头部。
   * scrollToIndex(ScrollAlign.START) 是框架原生锚点定位：不依赖手工测量/换算，
   * 无动画瞬移必然精确对齐 item 顶；静默窗口延时解除避免滚动回调抢高亮。
   */
  private scrollToSection(i: number): void {
    const len: number = this.categories.length;
    if (i < -1 || i >= len) {
      return;
    }
    this.setActive(i);
    this.suppressSync = true;
    const idx: number = i === -1 ? 0 : i + 1;
    try {
      this.rightScroller.scrollToIndex(idx, false, ScrollAlign.START);
    } catch (e) {
      hilog.error(0x0000, 'HupuLuna', 'scrollToIndex failed idx=%{public}d err=%{public}s', idx, String(e));
    }
    if (this.suppressTimer >= 0) {
      clearTimeout(this.suppressTimer);
    }
    this.suppressTimer = setTimeout(() => {
      this.suppressSync = false;
    }, 400);
  }


  private toast(msg: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: msg });
    } catch (e) {
    }
  }


  /** 热度文案：146.4万 / 2.9万 / 3.7万 */
  private heatText(count: string): string {
    const n: number = Number(count);
    if (Number.isNaN(n) || n <= 0) {
      return '';
    }
    if (n >= 10000) {
      return `${(n / 10000).toFixed(1)}万`;
    }
    return count;
  }

  /** 官方热图标的替代：纯文字 🔥 emoji（跨平台安全） */
  @Builder
  TopicCell(topic: ZoneTopic) {
    Column({ space: 5 }) {
      Stack({ alignContent: Alignment.Bottom }) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: topic.topicLogo,
            objectFit: ImageFit.Cover,
            border: { radius: 10 }
          }
        })
          .width(48)
          .height(48)
        if (this.myTopics.some((t: ZoneTopic) => t.topicId === topic.topicId)) {
          Text('我的')
            .fontSize(9)
            .fontColor(Color.White)
            .backgroundColor('#B3000000')
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .borderRadius({ bottomLeft: 10, bottomRight: 10 })
        }
      }
      .width(48)
      .height(48)

      Text(topic.topicName)
        .fontSize(12)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)

      Row({ space: 2 }) {
        Text('🔥')
          .fontSize(10)
        Text(this.heatText(topic.count))
          .fontSize(10)
          .fontColor($r('app.color.text_tertiary'))
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .onClick(() => {
      this.pageStack.pushPathByName(RouteName.TOPIC_THREADS, `${topic.topicId}|${topic.topicName}`);
    })
    .gesture(LongPressGesture({ repeat: false, duration: 500 })
      .onAction(() => {
        this.toggleMyTopic(topic);
      }))
  }

  build() {
    Column() {
      Column() {
      if (this.searchMode) {
        Row({ space: 10 }) {
          TextInput({ text: this.searchKeyword, placeholder: '搜索专区' })
            .layoutWeight(1)
            .height(36)
            .fontSize(13)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_tertiary'))
            .backgroundColor($r('app.color.tag_bg'))
            .borderRadius(18)
            .onChange((v: string) => {
              this.searchKeyword = v;
              this.searchResults = this.filterTopics(v);
            })
          Text('取消')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .onClick(() => {
              this.searchMode = false;
              this.searchKeyword = '';
              this.searchResults = [];
            })
        }
        .width('100%')
        .padding({ left: Spacing.lg, right: Spacing.lg, top: 8, bottom: 6 })
      } else {
        Row({ space: 8 }) {
          Text('Hupu Luna')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.brand_primary'))
            .maxLines(1)
          Blank()
          Row() {
            Text('搜索专区')
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .maxLines(1)
              .width('100%')
          }
          .width(120)
          .height(30)
          .padding({ left: 12, right: 12 })
          .backgroundColor($r('app.color.tag_bg'))
          .borderRadius(15)
          .onClick(() => {
            this.searchMode = true;
          })

        }
        .width('100%')
        .padding({ left: Spacing.lg, right: Spacing.lg, top: 10, bottom: 6 })
      }
      }
      .width('100%')
      .padding({ top: px2vp(this.topAvoidPx) })
      .backgroundColor($r('app.color.bg_page'))

      if (this.searchMode) {
        Scroll() {
          Column({ space: 10 }) {
            if (this.searchKeyword.trim().length === 0) {
              Text('输入关键词搜索分区')
                .fontSize(13)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 40, bottom: 40 })
            } else if (this.searchResults.length === 0) {
              Text('未找到相关分区')
                .fontSize(13)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 40, bottom: 40 })
            } else {
              Text(`${this.searchResults.length} 个匹配分区`)
                .fontSize(11)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
              Grid() {
                ForEach(this.searchResults, (t: ZoneTopic) => {
                  GridItem() {
                    this.TopicCell(t)
                  }
                }, (t: ZoneTopic) => `srch_${t.topicId}`)
              }
              .columnsTemplate('1fr 1fr 1fr')
              .columnsGap(6)
              .rowsGap(6)
              .width('100%')
              .height(Math.ceil(this.searchResults.length / 3) * 110)
            }
          }
          .padding({ left: 10, right: 10, bottom: 20 })
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
      } else if (this.state === LoadState.Ready) {
        Row() {
          // 左侧分类导航（含"我的"入口，可上下滑动，联动时自动滚到选中项）
          Scroll(this.leftScroller) {
            Column() {
              Row() {
                if (this.activeIndex === -1) {
                  Column()
                    .width(3)
                    .height(18)
                    .backgroundColor($r('app.color.brand_primary'))
                    .borderRadius(2)
                    .margin({ right: 6 })
                } else {
                  Column().width(3).height(18).margin({ right: 6 })
                }
                Text('我的')
                  .fontSize(13)
                  .fontWeight(this.activeIndex === -1 ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.activeIndex === -1 ? $r('app.color.brand_primary') : $r('app.color.text_secondary'))
                  .maxLines(1)
              }
              .width('100%')
              .height(44)
              .padding({ left: 8, right: 4 })
              .alignItems(VerticalAlign.Center)
              .id('zone_cat_my')
              .onClick(() => {
                this.scrollToSection(-1);
              })

              ForEach(this.categories, (cat: ZoneCategory, index: number) => {
                Row() {
                  if (index === this.activeIndex) {
                    Column()
                      .width(3)
                      .height(18)
                      .backgroundColor($r('app.color.brand_primary'))
                      .borderRadius(2)
                      .margin({ right: 6 })
                  } else {
                    Column().width(3).height(18).margin({ right: 6 })
                  }
                  Text(cat.name)
                    .fontSize(13)
                    .fontWeight(index === this.activeIndex ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(index === this.activeIndex ? $r('app.color.brand_primary') : $r('app.color.text_secondary'))
                    .maxLines(1)
                }
                .width('100%')
                .height(44)
                .padding({ left: 8, right: 4 })
                .alignItems(VerticalAlign.Center)
                .id('zone_cat_' + index)
                .onClick(() => {
                  this.scrollToSection(index);
                })
              }, (cat: ZoneCategory, index: number) => `${cat.categoryId}_${index}`)
            }
            .width('100%')
          }
          .id('zone_left_area')
          .scrollBar(BarState.Off)
          .width(96)
          .height('100%')
          .backgroundColor($r('app.color.bg_page'))
          .onScrollStart(() => {
            this.leftManual = true;
          })
          .onScrollStop(() => {
            this.leftManual = false;
          })

          // 右侧内容：List + ListItem（每区块一项），scrollToIndex 原生锚点定位 + onScrollIndex 联动
          List({ space: 10, scroller: this.rightScroller }) {
            ListItem() {
              // 我的分区区块
              Column({ space: 10 }) {
                Row() {
                  Text('我的')
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                  Blank()
                  Text('长按卡片可添加/移除')
                    .fontSize(10)
                    .fontColor($r('app.color.text_tertiary'))
                }
                .width('100%')

                if (this.myTopics.length > 0) {
                  Grid() {
                    ForEach(this.myTopics, (t: ZoneTopic) => {
                      GridItem() {
                        this.TopicCell(t)
                      }
                    }, (t: ZoneTopic) => `my_${t.topicId}`)
                  }
                  .columnsTemplate('1fr 1fr 1fr')
                  .columnsGap(6)
                  .rowsGap(6)
                  .width('100%')
                  .height(Math.ceil(this.myTopics.length / 3) * 110)
                } else {
                  Text('长按下方分区卡片，添加到"我的"')
                    .fontSize(11)
                    .fontColor($r('app.color.text_tertiary'))
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding(14)
                    .backgroundColor($r('app.color.bg_card'))
                    .borderRadius(Radius.md)
                }
              }
              .id('zone_sec_my')
              .width('100%')
            }
            .width('100%')

            // 各分类分区区块（依序拼接）
            ForEach(this.categories, (cat: ZoneCategory, index: number) => {
              ListItem() {
                Column({ space: 10 }) {
                  Row() {
                    Text(cat.name)
                      .fontSize(15)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.text_primary'))
                    Blank()
                    Text(`${cat.topics.length} 个分区`)
                      .fontSize(10)
                      .fontColor($r('app.color.text_tertiary'))
                  }
                  .width('100%')

                  Grid() {
                    ForEach(cat.topics, (t: ZoneTopic) => {
                      GridItem() {
                        this.TopicCell(t)
                      }
                    }, (t: ZoneTopic) => `sec${index}_${t.topicId}`)
                  }
                  .columnsTemplate('1fr 1fr 1fr')
                  .columnsGap(6)
                  .rowsGap(6)
                  .width('100%')
                  .height(Math.ceil(cat.topics.length / 3) * 110)
                }
                .id('zone_sec_' + index)
                .width('100%')
              }
              .width('100%')
            }, (cat: ZoneCategory, index: number) => `${cat.categoryId}_${index}`)
          }
          .id('zone_scroll_area')
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .layoutWeight(1)
          .width('100%')
          .padding({ left: 10, right: 10, bottom: 20 })
          .onScrollIndex((first: number, last: number) => {
            this.syncActiveFromList(first, last);
          })
        }
        .layoutWeight(1)
        .width('100%')
      } else {
        StateView({
          state: this.state,
          onRetry: () => {
            this.load();
          }
        })
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
