import { NbaApi } from '../network/NbaApi';
import {
  PlayerHeadInfo,
  PlayerSeasonData,
  PlayerStageStats,
  PlayerStatItem,
  ShootZone,
  AwardItem
} from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, Radius } from '../common/Theme';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { AppNavBar } from '../views/AppNavBar';

/** 热区元数据：区域编号 → 名称与半场坐标（330×290 画布，圆心坐标） */
class ZoneMeta {
  id: number = 0;
  name: string = '';
  cx: number = 0;
  cy: number = 0;
}

const ZONE_Z: number = 36;
const ZONES: ZoneMeta[] = [
  { id: 1, name: '篮下', cx: 165, cy: 252 },
  { id: 2, name: '油漆区左侧', cx: 135, cy: 235 },
  { id: 3, name: '油漆区右侧', cx: 195, cy: 235 },
  { id: 4, name: '左侧底线中距', cx: 72, cy: 258 },
  { id: 5, name: '右侧底线中距', cx: 258, cy: 258 },
  { id: 6, name: '左侧底角三分', cx: 22, cy: 262 },
  { id: 7, name: '右侧底角三分', cx: 308, cy: 262 },
  { id: 8, name: '左翼中距离', cx: 95, cy: 200 },
  { id: 9, name: '右翼中距离', cx: 235, cy: 200 },
  { id: 10, name: '左翼三分', cx: 58, cy: 148 },
  { id: 11, name: '右翼三分', cx: 272, cy: 148 },
  { id: 12, name: '左侧肘区', cx: 128, cy: 182 },
  { id: 13, name: '右侧肘区', cx: 202, cy: 182 },
  { id: 14, name: '弧顶三分', cx: 165, cy: 92 }
];

/** 球员主页（资料头 + 数据/投篮/资料 页签） */
@Component
export struct PlayerProfilePage {
  /** 格式："playerId||leagueType(可选，默认 NBA)" */
  param: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State head: PlayerHeadInfo = new PlayerHeadInfo();
  @State season: PlayerSeasonData = new PlayerSeasonData();
  @State state: LoadState = LoadState.Loading;
  @State tabSel: number = 0;
  @State dimSel: number = 0;
  @State stageSel: number = 0;
  @State hotZones: ShootZone[] = [];
  @State hotState: LoadState = LoadState.Loading;
  @State hotStage: string = 'REGULAR';
  @State selectedZone: number = -1;
  @State awards: AwardItem[] = [];
  private playerId: string = '';
  private league: string = 'NBA';
  private hotLoadedStage: string = '';

  aboutToAppear(): void {
    const parts: string[] = this.param.split('||');
    if (parts.length >= 1) {
      this.playerId = parts[0];
    }
    if (parts.length >= 2 && parts[1].length > 0) {
      this.league = parts[1];
    }
    this.load();
  }

  private async load(): Promise<void> {
    this.state = LoadState.Loading;
    try {
      this.head = await NbaApi.getPlayerHeadInfo(this.playerId, this.league);
    } catch (e) {
      try {
        const alt: string = this.league === 'NBA' ? 'CBA' : 'NBA';
        this.head = await NbaApi.getPlayerHeadInfo(this.playerId, alt);
        this.league = alt;
      } catch (e2) {
        this.state = LoadState.Error;
        return;
      }
    }
    try {
      this.season = await NbaApi.getPlayerSeasonStats(this.playerId, this.league);
      let anchorIdx: number = -1;
      for (let i = 0; i < this.season.basicStages.length; i++) {
        if (this.season.basicStages[i].stage === this.season.anchorStage) {
          anchorIdx = i;
        }
      }
      this.stageSel = anchorIdx >= 0 ? anchorIdx : 0;
    } catch (e) {
      this.season = new PlayerSeasonData();
    }
    this.state = LoadState.Ready;
    this.loadAwards();
  }

  private async loadAwards(): Promise<void> {
    try {
      this.awards = await NbaApi.getPlayerAwards(this.playerId, this.league);
    } catch (e) {
      this.awards = [];
    }
  }

  /** 加载投篮热图（按阶段） */
  private async loadHotMap(stage: string): Promise<void> {
    if (this.hotLoadedStage === stage) {
      return;
    }
    this.hotState = LoadState.Loading;
    try {
      this.hotZones = await NbaApi.getShootHotMap(this.playerId, this.league, stage);
      this.hotLoadedStage = stage;
      this.hotState = this.hotZones.length > 0 ? LoadState.Ready : LoadState.Empty;
    } catch (e) {
      this.hotState = LoadState.Error;
    }
  }

  private currentStages(): PlayerStageStats[] {
    if (this.dimSel === 1 && this.season.advancedStages.length > 0) {
      return this.season.advancedStages;
    }
    return this.season.basicStages;
  }

  private currentItems(): PlayerStatItem[] {
    const stages: PlayerStageStats[] = this.currentStages();
    if (this.stageSel < 0 || this.stageSel >= stages.length) {
      return [];
    }
    return stages[this.stageSel].items;
  }

  private chunk3(items: PlayerStatItem[]): PlayerStatItem[][] {
    const rows: PlayerStatItem[][] = [];
    let cur: PlayerStatItem[] = [];
    for (const it of items) {
      cur.push(it);
      if (cur.length === 3) {
        rows.push(cur);
        cur = [];
      }
    }
    if (cur.length > 0) {
      rows.push(cur);
    }
    return rows;
  }

  private draftText(): string {
    if (this.head.draftYear.length === 0) {
      return '';
    }
    let s: string = `${this.head.draftYear}年`;
    if (this.head.draftRound > 0) {
      s = s + ` 第${this.head.draftRound}轮`;
    }
    if (this.head.draftPick > 0) {
      s = s + ` 第${this.head.draftPick}顺位`;
    }
    return s;
  }

  private salaryText(): string {
    if (this.head.salary <= 0) {
      return '';
    }
    return `${(this.head.salary / 10000).toFixed(0)}万美元/年`;
  }

  /** 按区域编号取热图数据 */
  private zoneOf(id: number): ShootZone | null {
    for (const z of this.hotZones) {
      if (z.areaId === id) {
        return z;
      }
    }
    return null;
  }

  private zoneBg(id: number): string {
    const z: ShootZone | null = this.zoneOf(id);
    if (z === null || z.color.length < 7) {
      return '#33FFFFFF';
    }
    return `#D9${z.color.substring(1)}`;
  }

  private zoneText(id: number): string {
    const z: ShootZone | null = this.zoneOf(id);
    if (z === null || z.fgs === 0) {
      return '—';
    }
    return z.fgp;
  }

  private zoneFg(id: number): string {
    const z: ShootZone | null = this.zoneOf(id);
    if (z === null || z.level === 2) {
      return '#3D2E00';
    }
    return '#FFFFFF';
  }

  private selectedMeta(): ZoneMeta | null {
    for (const m of ZONES) {
      if (m.id === this.selectedZone) {
        return m;
      }
    }
    return null;
  }

  @Builder
  HeaderCard() {
    Column({ space: 12 }) {
      Row({ space: 14 }) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.head.photo,
            objectFit: ImageFit.Cover,
            border: { radius: 8 }
          }
        })
          .width(84)
          .height(84)

        Column({ space: 6 }) {
          Text(this.head.name.length > 0 ? this.head.name : this.head.alias)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.head.engName.length > 0) {
            Text(this.head.engName)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
          }
          Row({ space: 8 }) {
            if (this.head.teamName.length > 0) {
              Row({ space: 4 }) {
                ImageKnifeComponent({
                  imageKnifeOption: {
                    loadSrc: this.head.teamLogo,
                    objectFit: ImageFit.Contain
                  }
                })
                  .width(16)
                  .height(16)
                Text(this.head.teamName)
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
              }
            }
            if (this.head.nick.length > 0) {
              Text(`昵称 ${this.head.nick}`)
                .fontSize(11)
                .fontColor($r('app.color.text_tertiary'))
            }
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row() {
        Text(this.head.position.length > 0 ? `${this.head.position} / ${this.head.number}号` : '')
          .fontSize(13)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text(this.head.age.length > 0 ? `${this.head.age}岁` : '')
          .fontSize(13)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text(this.head.height.length > 0 ? `${this.head.height}m` : '')
          .fontSize(13)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text(this.head.weight.length > 0 ? `${this.head.weight}kg` : '')
          .fontSize(13)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: 8, bottom: 4 })
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  TabItem(label: string, idx: number) {
    Column({ space: 5 }) {
      Text(label)
        .fontSize(15)
        .fontWeight(this.tabSel === idx ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.tabSel === idx ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
      Row()
        .width(40)
        .height(3)
        .borderRadius(2)
        .backgroundColor(this.tabSel === idx ? $r('app.color.brand_primary') : Color.Transparent)
    }
    .onClick(() => {
      this.tabSel = idx;
      if (idx === 1) {
        this.loadHotMap(this.hotStage);
      }
    })
  }

  @Builder
  TabBar() {
    Row({ space: 22 }) {
      this.TabItem('数据', 0)
      this.TabItem('投篮', 1)
      this.TabItem('资料', 2)
      Blank()
      if (this.season.season.length > 0) {
        Text(`${this.season.season} 赛季`)
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
      }
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 10, bottom: 8 })
  }

  /* ---------------- 数据页签 ---------------- */

  @Builder
  StageTab(stage: PlayerStageStats, idx: number) {
    Text(stage.label)
      .fontSize(13)
      .fontColor(this.stageSel === idx ? Color.White : $r('app.color.text_secondary'))
      .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      .backgroundColor(this.stageSel === idx ? $r('app.color.brand_primary') : Color.Transparent)
      .borderRadius(14)
      .onClick(() => {
        this.stageSel = idx;
      })
  }

  @Builder
  DimTab(label: string, idx: number) {
    Text(label)
      .fontSize(12)
      .fontColor(this.dimSel === idx ? $r('app.color.text_primary') : $r('app.color.text_tertiary'))
      .fontWeight(this.dimSel === idx ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .onClick(() => {
        this.dimSel = idx;
        if (this.stageSel >= this.currentStages().length) {
          this.stageSel = 0;
        }
      })
  }

  @Builder
  StatCell(item: PlayerStatItem) {
    Column({ space: 4 }) {
      Text(item.quota.length > 0 ? item.quota : '—')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
      Text(item.cnName)
        .fontSize(11)
        .fontColor($r('app.color.text_tertiary'))
        .maxLines(1)
      if (item.rank > 0) {
        Text(`联盟第${item.rank}`)
          .fontSize(9)
          .fontColor($r('app.color.brand_primary'))
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .backgroundColor($r('app.color.tag_bg'))
          .borderRadius(3)
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  DataTab() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        this.DimTab('基础数据', 0)
        if (this.season.advancedStages.length > 0) {
          this.DimTab('进阶数据', 1)
        }
        Blank()
      }
      .width('100%')

      Row({ space: 8 }) {
        ForEach(this.currentStages(), (stage: PlayerStageStats, idx: number) => {
          this.StageTab(stage, idx)
        }, (stage: PlayerStageStats, idx: number) => `stg_${stage.stage}_${idx}`)
        Blank()
      }
      .width('100%')

      Column() {
        ForEach(this.chunk3(this.currentItems()), (row: PlayerStatItem[]) => {
          Row() {
            ForEach(row, (item: PlayerStatItem) => {
              this.StatCell(item)
            }, (item: PlayerStatItem) => `cell_${item.name}`)
            if (row.length < 3) {
              Blank().layoutWeight(1)
            }
            if (row.length < 2) {
              Blank().layoutWeight(1)
            }
          }
          .width('100%')
          Divider().color($r('app.color.divider'))
        }, (row: PlayerStatItem[]) => `row_${row[0].name}`)
      }
      .width('100%')
      .backgroundColor($r('app.color.bg_card'))
      .borderRadius(Radius.md)

      if (this.currentItems().length === 0) {
        Text('该阶段暂无数据')
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 30, bottom: 30 })
      }
    }
    .width('100%')
    .padding(Spacing.lg)
  }

  /* ---------------- 投篮页签 ---------------- */

  @Builder
  HotStageChip(label: string, stage: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.hotStage === stage ? Color.White : $r('app.color.text_secondary'))
      .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      .backgroundColor(this.hotStage === stage ? $r('app.color.brand_primary') : $r('app.color.tag_bg'))
      .borderRadius(14)
      .onClick(() => {
        if (this.hotStage !== stage) {
          this.hotStage = stage;
          this.selectedZone = -1;
          this.loadHotMap(stage);
        }
      })
  }

  @Builder
  ZoneDot(id: number, meta: ZoneMeta) {
    Stack() {
      Column()
        .width(ZONE_Z)
        .height(ZONE_Z)
        .borderRadius(ZONE_Z / 2)
        .backgroundColor(this.zoneBg(id))
        .border({
          width: this.selectedZone === id ? 2 : 1,
          color: this.selectedZone === id ? $r('app.color.brand_primary') : '#66FFFFFF'
        })
      Text(this.zoneText(id))
        .fontSize(9)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.zoneFg(id))
    }
    .width(ZONE_Z)
    .height(ZONE_Z)
    .position({ x: meta.cx - ZONE_Z / 2, y: meta.cy - ZONE_Z / 2 })
    .onClick(() => {
      this.selectedZone = this.selectedZone === id ? -1 : id;
    })
  }

  @Builder
  Court() {
    Stack() {
      // 场地外框（左右边线 + 底线）
      Column()
        .width(330)
        .height(290)
        .border({
          width: { left: 1.5, right: 1.5, bottom: 1.5 },
          color: $r('app.color.text_tertiary')
        })
      // 油漆区
      Column()
        .width(90)
        .height(115)
        .border({ width: 1.5, color: $r('app.color.text_tertiary') })
        .position({ x: 120, y: 175 })
      // 罚球圈
      Column()
        .width(60)
        .height(60)
        .borderRadius(30)
        .border({ width: 1.5, color: $r('app.color.text_tertiary') })
        .position({ x: 135, y: 145 })
      // 篮筐
      Column()
        .width(16)
        .height(16)
        .borderRadius(8)
        .border({ width: 1.5, color: $r('app.color.text_tertiary') })
        .position({ x: 157, y: 254 })
      // 三分线
      Path()
        .commands('M 8 288 L 8 232 A 158 158 0 0 1 322 232 L 322 288')
        .fill(Color.Transparent)
        .stroke($r('app.color.text_tertiary'))
        .strokeWidth(1.5)
        .width(330)
        .height(290)
        .position({ x: 0, y: 0 })

      // 14 个热区
      ForEach(ZONES, (meta: ZoneMeta) => {
        this.ZoneDot(meta.id, meta)
      }, (meta: ZoneMeta) => `zone_${meta.id}`)
    }
    .width(330)
    .height(290)
  }

  @Builder
  Legend() {
    Row({ space: 16 }) {
      Row({ space: 4 }) {
        Column().width(10).height(10).borderRadius(5).backgroundColor('#ff7838')
        Text('火热').fontSize(11).fontColor($r('app.color.text_secondary'))
      }
      Row({ space: 4 }) {
        Column().width(10).height(10).borderRadius(5).backgroundColor('#ffd303')
        Text('一般').fontSize(11).fontColor($r('app.color.text_secondary'))
      }
      Row({ space: 4 }) {
        Column().width(10).height(10).borderRadius(5).backgroundColor('#58cce0')
        Text('偏冷').fontSize(11).fontColor($r('app.color.text_secondary'))
      }
      Blank()
      Text('数值为命中率')
        .fontSize(10)
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
  }

  @Builder
  SelectedInfo() {
    Row({ space: 8 }) {
      if (this.selectedMeta() !== null) {
        Column()
          .width(10)
          .height(10)
          .borderRadius(5)
          .backgroundColor(this.zoneBg(this.selectedZone))
        Text(`${this.selectedMeta()!.name}`)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        if (this.zoneOf(this.selectedZone) !== null) {
          Text(`命中 ${this.zoneOf(this.selectedZone)!.fgm}/${this.zoneOf(this.selectedZone)!.fgs} · ${this.zoneOf(this.selectedZone)!.fgp}`)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        } else {
          Text('暂无出手')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
        }
      } else {
        Text('点击热区查看该区域命中详情')
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
      }
      Blank()
    }
    .width('100%')
    .height(30)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  ZoneRow(meta: ZoneMeta) {
    Row({ space: 10 }) {
      Column()
        .width(10)
        .height(10)
        .borderRadius(5)
        .backgroundColor(this.zoneBg(meta.id))
      Text(`${meta.id}  ${meta.name}`)
        .fontSize(13)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      if (this.zoneOf(meta.id) !== null && this.zoneOf(meta.id)!.fgs > 0) {
        Text(`${this.zoneOf(meta.id)!.fgm}/${this.zoneOf(meta.id)!.fgs}`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        Text(this.zoneOf(meta.id)!.fgp)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width(52)
          .textAlign(TextAlign.End)
      } else {
        Text('—')
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .width(52)
          .textAlign(TextAlign.End)
      }
    }
    .width('100%')
    .padding({ top: 9, bottom: 9 })
  }

  @Builder
  HotTab() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        this.HotStageChip('常规赛', 'REGULAR')
        this.HotStageChip('季后赛', 'PLAYOFF')
        Blank()
      }
      .width('100%')

      if (this.hotState === LoadState.Ready) {
        this.SelectedInfo()
        Row() {
          this.Court()
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        this.Legend()

        Column() {
          ForEach(ZONES, (meta: ZoneMeta) => {
            Column() {
              this.ZoneRow(meta)
              Divider().color($r('app.color.divider'))
            }
          }, (meta: ZoneMeta) => `zrow_${meta.id}`)
        }
        .width('100%')
        .padding({ left: 12, right: 12 })
        .backgroundColor($r('app.color.bg_card'))
        .borderRadius(Radius.md)
      } else if (this.hotState === LoadState.Loading) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color($r('app.color.text_tertiary'))
        }
        .width('100%')
        .padding({ top: 60, bottom: 60 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Text(this.hotState === LoadState.Empty ? '该阶段暂无投篮数据' : '投篮数据加载失败，下拉重试')
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 40, bottom: 40 })
          .onClick(() => {
            this.hotLoadedStage = '';
            this.loadHotMap(this.hotStage);
          })
      }
    }
    .width('100%')
    .padding(Spacing.lg)
  }

  /* ---------------- 资料页签 ---------------- */

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width(76)
      Text(value.length > 0 ? value : '—')
        .fontSize(13)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 11, bottom: 11 })
  }

  @Builder
  AwardRow(item: AwardItem) {
    Row({ space: 10 }) {
      Text('🏆')
        .fontSize(15)
      Column({ space: 3 }) {
        Row({ space: 6 }) {
          Text(item.name)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          if (item.count > 1) {
            Text(`x${item.count}`)
              .fontSize(11)
              .fontColor($r('app.color.brand_primary'))
          }
        }
        if (item.dates.length > 0) {
          Text(item.dates.slice(0, 3).join(' · ') + (item.dates.length > 3 ? ' 等' : ''))
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  ProfileTab() {
    Column({ space: 10 }) {
      Column() {
        this.InfoRow('国籍', this.head.country)
        Divider().color($r('app.color.divider'))
        this.InfoRow('出生日期', this.head.birthDate)
        Divider().color($r('app.color.divider'))
        this.InfoRow('大学', this.head.college)
        Divider().color($r('app.color.divider'))
        this.InfoRow('选秀', this.draftText())
        Divider().color($r('app.color.divider'))
        this.InfoRow('薪资', this.salaryText())
        if (this.head.contract.length > 0) {
          Divider().color($r('app.color.divider'))
          this.InfoRow('合同', this.head.contract)
        }
      }
      .width('100%')
      .padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor($r('app.color.bg_card'))
      .borderRadius(Radius.md)

      if (this.awards.length > 0) {
        Column() {
          Row() {
            Text('荣誉')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
            Blank()
            Text(`共 ${this.awards.length} 项`)
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
          }
          .width('100%')
          .padding({ top: 12, bottom: 4 })

          ForEach(this.awards, (a: AwardItem) => {
            Column() {
              this.AwardRow(a)
              Divider().color($r('app.color.divider'))
            }
          }, (a: AwardItem) => `award_${a.name}`)
        }
        .width('100%')
        .padding({ left: Spacing.lg, right: Spacing.lg, bottom: 6 })
        .backgroundColor($r('app.color.bg_card'))
        .borderRadius(Radius.md)
      }
    }
    .width('100%')
    .padding(Spacing.lg)
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: this.head.name.length > 0 ? this.head.name : '球员资料' })
        if (this.state === LoadState.Ready) {
        Scroll() {
          Column({ space: 0 }) {
            this.HeaderCard()
            this.TabBar()
            if (this.tabSel === 0) {
              this.DataTab()
            } else if (this.tabSel === 1) {
              this.HotTab()
            } else {
              this.ProfileTab()
            }
            Text('数据来自虎扑')
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 12, bottom: 24 })
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.bg_page'))
      } else if (this.state === LoadState.Loading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color($r('app.color.text_tertiary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.bg_page'))
      } else {
        StateView({
          state: this.state,
          message: '暂无该球员资料',
          onRetry: () => {
            this.load();
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
