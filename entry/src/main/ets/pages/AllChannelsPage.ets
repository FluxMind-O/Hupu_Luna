import { ChannelDef, ChannelCatalog } from '../common/Channels';
import { ChannelStore } from '../database/ChannelStore';
import { Spacing, Radius } from '../common/Theme';
import { common } from '@kit.AbilityKit';
import { AppNavBar } from '../views/AppNavBar';

/** 全部频道管理页（我的频道 / 推荐频道） */
@Component
export struct AllChannelsPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('channelIdsJson') @Watch('onIdsChanged') channelIdsJson: string = '';
  @State myIds: string[] = [];
  @State editing: boolean = false;

  aboutToAppear(): void {
    this.parseIds();
  }

  onIdsChanged(): void {
    this.parseIds();
  }

  private parseIds(): void {
    let ids: string[] = [];
    if (this.channelIdsJson.length > 0) {
      try {
        ids = JSON.parse(this.channelIdsJson) as string[];
      } catch (e) {
      }
    }
    ids = ChannelCatalog.sanitize(ids);
    if (ids.length === 0) {
      ids = ChannelCatalog.defaults();
    }
    this.myIds = ids;
  }

  private getCtx(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  private persist(ids: string[]): void {
    const json: string = JSON.stringify(ids);
    AppStorage.setOrCreate<string>('channelIdsJson', json);
    ChannelStore.save(this.getCtx(), ids);
  }

  private add(id: string): void {
    for (const x of this.myIds) {
      if (x === id) {
        return;
      }
    }
    const ids: string[] = this.myIds.slice();
    ids.push(id);
    this.persist(ids);
  }

  private remove(id: string): void {
    if (this.myIds.length <= 1) {
      return;
    }
    const ids: string[] = [];
    for (const x of this.myIds) {
      if (x !== id) {
        ids.push(x);
      }
    }
    this.persist(ids);
  }

  private jump(id: string): void {
    AppStorage.setOrCreate<string>('activeChannelId', id);
    this.pageStack.pop();
  }

  private recommendIds(): string[] {
    const result: string[] = [];
    for (const c of ChannelCatalog.all()) {
      let inMy: boolean = false;
      for (const id of this.myIds) {
        if (id === c.id) {
          inMy = true;
          break;
        }
      }
      if (!inMy) {
        result.push(c.id);
      }
    }
    return result;
  }

  private chunkRows(ids: string[]): string[][] {
    const rows: string[][] = [];
    let current: string[] = [];
    for (const id of ids) {
      current.push(id);
      if (current.length === 3) {
        rows.push(current);
        current = [];
      }
    }
    if (current.length > 0) {
      rows.push(current);
    }
    return rows;
  }

  @Builder
  MyChip(id: string) {
    Row({ space: 4 }) {
      if (this.editing) {
        Text('−')
          .fontSize(14)
          .fontColor($r('app.color.brand_primary'))
      }
      Text(ChannelCatalog.find(id).name)
        .fontSize(14)
        .fontColor(this.editing ? $r('app.color.brand_primary') : $r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(38)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.tag_bg'))
    .borderRadius(Radius.sm)
    .onClick(() => {
      if (this.editing) {
        this.remove(id);
      } else {
        this.jump(id);
      }
    })
  }

  @Builder
  RecChip(id: string) {
    Row({ space: 2 }) {
      Text('+')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(ChannelCatalog.find(id).name)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(38)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.bg_card'))
    .border({ width: 1, color: $r('app.color.divider') })
    .borderRadius(Radius.sm)
    .onClick(() => {
      this.add(id);
    })
  }

  @Builder
  MyRow(ids: string[]) {
    Row({ space: 8 }) {
      ForEach(ids, (id: string) => {
        this.MyChip(id)
      }, (id: string) => `my_${id}`)
      if (ids.length < 3) {
        Blank().layoutWeight(1)
      }
      if (ids.length < 2) {
        Blank().layoutWeight(1)
      }
    }
    .width('100%')
  }

  @Builder
  RecRow(ids: string[]) {
    Row({ space: 8 }) {
      ForEach(ids, (id: string) => {
        this.RecChip(id)
      }, (id: string) => `rec_${id}`)
      if (ids.length < 3) {
        Blank().layoutWeight(1)
      }
      if (ids.length < 2) {
        Blank().layoutWeight(1)
      }
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: '全部频道' })
        Scroll() {
        Column({ space: 10 }) {
          Row() {
            Text('我的频道')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text('点击进入频道')
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .margin({ left: 6 })
            Blank()
            Text(this.editing ? '完成' : '编辑')
              .fontSize(12)
              .fontColor($r('app.color.brand_primary'))
              .padding({ left: 12, right: 12, top: 4, bottom: 4 })
              .backgroundColor($r('app.color.tag_bg'))
              .borderRadius(12)
              .onClick(() => {
                this.editing = !this.editing;
              })
          }
          .width('100%')

          ForEach(this.chunkRows(this.myIds), (row: string[]) => {
            this.MyRow(row)
          }, (row: string[]) => `myrow_${row.join('_')}`)

          Row() {
            Text('推荐频道')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text('点击添加频道')
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .margin({ left: 6 })
          }
          .width('100%')
          .margin({ top: 10 })

          ForEach(this.chunkRows(this.recommendIds()), (row: string[]) => {
            this.RecRow(row)
          }, (row: string[]) => `recrow_${row.join('_')}`)

          if (this.recommendIds().length === 0) {
            Text('已添加全部频道')
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 10, bottom: 10 })
          }
        }
        .padding(Spacing.lg)
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.bg_page'))
      }
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
