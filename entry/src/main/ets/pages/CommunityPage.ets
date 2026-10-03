import { HupuApi } from '../network/HupuApi';
import { ZoneCategory, ZoneTopic } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, FontSize, Radius, RouteName } from '../common/Theme';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'hupluna_settings';
const KEY_MY_TOPICS: string = 'my_topic_ids';

/** 官方社区页形态：左侧分类导航 + 右侧 3 列分区网格 + "我的"收藏区块 */
@Component
export struct CommunityPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State categories: ZoneCategory[] = [];
  @State state: LoadState = LoadState.Loading;
  @State activeIndex: number = 0;
  @State myTopics: ZoneTopic[] = [];
  @StorageLink('topAvoidPx') topAvoidPx: number = 0;
  private ctx: common.Context | null = null;

  aboutToAppear(): void {
    this.ctx = this.getUIContext().getHostContext() as common.Context;
    this.load();
  }

  private getCtx(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
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

  private toast(msg: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: msg });
    } catch (e) {
    }
  }

  private currentTopics(): ZoneTopic[] {
    if (this.activeIndex < 0 || this.activeIndex >= this.categories.length) {
      return [];
    }
    return this.categories[this.activeIndex].topics;
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
            border: { radius: 12 }
          }
        })
          .width(56)
          .height(56)
        if (this.myTopics.some((t: ZoneTopic) => t.topicId === topic.topicId)) {
          Text('我的')
            .fontSize(9)
            .fontColor(Color.White)
            .backgroundColor('#B3000000')
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .borderRadius({ bottomLeft: 12, bottomRight: 12 })
        }
      }
      .width(56)
      .height(56)

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
      Row() {
        Text('社区')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({ left: Spacing.lg, right: Spacing.lg, top: 10, bottom: 6 })
      }
      .width('100%')
      .padding({ top: px2vp(this.topAvoidPx) })
      .backgroundColor($r('app.color.bg_page'))

      if (this.state === LoadState.Ready) {
        Row() {
          // 左侧分类导航
          Scroll() {
            Column() {
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
                .onClick(() => {
                  this.activeIndex = index;
                })
              }, (cat: ZoneCategory, index: number) => `${cat.categoryId}_${index}`)
            }
            .width('100%')
          }
          .scrollBar(BarState.Off)
          .width(96)
          .height('100%')
          .backgroundColor($r('app.color.bg_page'))

          // 右侧内容
          Column() {
            Scroll() {
              Column({ space: 10 }) {
                // 我的分区
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
                  .height(Math.ceil(this.myTopics.length / 3) * 106 + 12)
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

                // 推荐网格（当前分类全部分区）
                Row() {
                  Text(this.categories[this.activeIndex].name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                  Blank()
                  Text(`${this.currentTopics().length} 个分区`)
                    .fontSize(10)
                    .fontColor($r('app.color.text_tertiary'))
                }
                .width('100%')

                Grid() {
                  ForEach(this.currentTopics(), (t: ZoneTopic) => {
                    GridItem() {
                      this.TopicCell(t)
                    }
                  }, (t: ZoneTopic) => `rec_${t.topicId}`)
                }
                .columnsTemplate('1fr 1fr 1fr')
                .columnsGap(6)
                .rowsGap(6)
                .width('100%')
              }
              .padding({ left: 10, right: 10, bottom: 20 })
              .width('100%')
            }
            .scrollBar(BarState.Off)
            .layoutWeight(1)
            .width('100%')
            .backgroundColor($r('app.color.bg_page'))
          }
          .layoutWeight(1)
          .height('100%')
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
