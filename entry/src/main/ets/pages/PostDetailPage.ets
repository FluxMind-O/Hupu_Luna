import { HupuApi } from '../network/HupuApi';
import { ThreadDetail, ReplyItem, SubReplyItem } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { DetailSkeleton } from '../views/Skeleton';
import { Spacing, FontSize, Radius, RouteName } from '../common/Theme';
import { htmlToText, thumbUrl } from '../common/Utils';
import { compactCount } from '../views/TagChip';
import { FavStore, FavRecord } from '../database/FavStore';
import { CacheStore } from '../database/CacheStore';
import { CachedPayload } from '../database/CacheStore';
import { SessionManager } from '../network/SessionManager';
import { WriteApi } from '../network/WriteApi';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AppNavBar } from '../views/AppNavBar';

@Component
export struct PostDetailPage {
  tid: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State detail: ThreadDetail = new ThreadDetail();
  @State contentText: string = '';
  @State state: LoadState = LoadState.Loading;
  @State replies: ReplyItem[] = [];
  @State replyState: LoadState = LoadState.Loading;
  @State replyTotal: number = 0;
  @State hasMoreReplies: boolean = false;
  @State isFav: boolean = false;
  @State subReplies: SubReplyItem[] = [];
  @State expandedPids: string[] = [];
  @State loadingSubPid: string = '';
  private replyPage: number = 0;
  private loadingMore: boolean = false;
  @State inputText: string = '';
  @State sendingReply: boolean = false;
  @State replyTargetPid: string = '';
  @State replyTargetUser: string = '';
  @State lightingPid: string = '';

  aboutToAppear(): void {
    this.loadDetail();
    this.loadReplies();
  }

  private getCtx(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  private async loadDetail(): Promise<void> {
    this.state = LoadState.Loading;
    // 缓存优先：先渲染缓存详情（网络成功后静默替换；失败则保持缓存不白屏）
    await this.renderDetailFromCache();
    try {
      const d = await HupuApi.getThreadDetail(this.tid);
      this.applyDetail(d);
      this.saveDetailCache(d);
      this.state = LoadState.Ready;
      this.refreshFavState();
    } catch (e) {
      if (this.state !== LoadState.Ready) {
        this.state = LoadState.Error;
      }
    }
  }

  /** 应用详情模型到视图状态 */
  private applyDetail(d: ThreadDetail): void {
    this.detail = d;
    const raw: string = d.content.trim();
    if (raw.length > 0 && raw.charAt(0) === '{') {
      this.contentText = '（本楼包含赛事卡片等富媒体内容，请在虎扑原帖中查看）';
      this.detail.contentImages = [];
    } else {
      this.contentText = htmlToText(d.content);
    }
  }

  /** 写详情缓存（fire-and-forget，失败静默） */
  private saveDetailCache(d: ThreadDetail): void {
    CacheStore.put(this.getCtx(), `detail/${this.tid}`, JSON.stringify(d));
  }

  /** 读缓存详情并渲染（缺失或损坏时静默跳过） */
  private async renderDetailFromCache(): Promise<void> {
    let cached: CachedPayload | null = null;
    try {
      cached = await CacheStore.get(this.getCtx(), `detail/${this.tid}`);
    } catch (e) {
    }
    if (cached === null) {
      return;
    }
    try {
      const d = JSON.parse(cached.json) as ThreadDetail;
      if (d && d.title) {
        this.applyDetail(d);
        this.state = LoadState.Ready;
        this.refreshFavState();
      }
    } catch (e) {
    }
  }

  private async refreshFavState(): Promise<void> {
    try {
      this.isFav = await FavStore.isFav(this.getCtx(), this.tid);
    } catch (e) {
    }
  }

  /** 楼层点亮（登录态）；乐观更新，失败提示 */
  private async lightFloor(item: ReplyItem): Promise<void> {
    if (!SessionManager.hasCookie()) {
      this.toastMsg('未登录，请先在设置页注入 Cookie');
      return;
    }
    if (item.puid.length === 0 || this.lightingPid === item.pid) {
      return;
    }
    this.lightingPid = item.pid;
    try {
      const r: number = await WriteApi.lightReply(item.puid, item.pid, this.tid, this.detail.fid);
      if (r === 1) {
        item.light = item.light + 1;
        this.toastMsg('已点亮');
      } else {
        this.toastMsg('已点亮过');
      }
    } catch (e) {
      this.toastMsg((e as Error).message);
    }
    this.lightingPid = '';
  }

  /** 发送回复（replyTargetPid 非空 = 楼中楼） */
  private async sendReply(): Promise<void> {
    const content: string = this.inputText.trim();
    if (content.length === 0 || this.sendingReply) {
      return;
    }
    if (!SessionManager.hasCookie()) {
      this.toastMsg('未登录，请先在设置页注入 Cookie');
      return;
    }
    if (this.detail.fid.length === 0) {
      this.toastMsg('缺少板块信息，无法回复');
      return;
    }
    this.sendingReply = true;
    try {
      await WriteApi.createReply(this.tid, this.detail.fid, content, this.replyTargetPid);
      this.inputText = '';
      this.replyTargetPid = '';
      this.replyTargetUser = '';
      this.toastMsg('回复成功');
    } catch (e) {
      this.toastMsg((e as Error).message);
    }
    this.sendingReply = false;
  }

  private toastMsg(msg: string) {
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }

  private async toggleFav(): Promise<void> {
    const loggedIn: boolean = SessionManager.hasCookie();
    const willFav: boolean = !this.isFav;
    // 云收藏先行（登录态）；失败则不改动本地，保证状态一致
    if (loggedIn) {
      try {
        if (willFav) {
          await WriteApi.collect(this.tid);
        } else {
          await WriteApi.uncollect(this.tid);
        }
      } catch (e) {
        this.toastMsg((e as Error).message);
        return;
      }
    }
    try {
      if (this.isFav) {
        await FavStore.remove(this.getCtx(), this.tid);
        this.isFav = false;
      } else {
        const rec: FavRecord = new FavRecord();
        rec.tid = this.tid;
        rec.title = this.detail.title;
        rec.author = this.detail.authorName;
        rec.forum = this.detail.forumName;
        rec.favTime = Date.now();
        await FavStore.add(this.getCtx(), rec);
        this.isFav = true;
      }
      AppStorage.setOrCreate<number>('favVersion', Date.now());
      if (!loggedIn) {
        this.toastMsg('已存本地收藏（注入 Cookie 可同步云端）');
      }
    } catch (e) {
    }
  }

  private async loadReplies(): Promise<void> {
    try {
      const res = await HupuApi.getReplies(this.tid, 1);
      this.replies = res.items;
      this.replyTotal = res.totalCount;
      this.replyPage = 1;
      this.hasMoreReplies = res.hasMore;
      this.replyState = this.replies.length > 0 ? LoadState.Ready : LoadState.Empty;
    } catch (e) {
      this.replyState = LoadState.Error;
    }
  }

  private async loadMoreReplies(): Promise<void> {
    if (this.loadingMore || !this.hasMoreReplies || this.replyState !== LoadState.Ready) {
      return;
    }
    this.loadingMore = true;
    try {
      const res = await HupuApi.getReplies(this.tid, this.replyPage + 1);
      this.replies = this.replies.concat(res.items);
      this.replyPage = this.replyPage + 1;
      this.hasMoreReplies = res.hasMore;
    } catch (e) {
    }
    this.loadingMore = false;
  }

  /** 打开图片查看器 */
  private openViewer(urls: string[], index: number): void {
    if (urls.length === 0) {
      return;
    }
    const param: string = `${index}||${urls.join('|')}`;
    this.pageStack.pushPathByName(RouteName.IMAGE_VIEWER, param);
  }

  private isExpanded(pid: string): boolean {
    for (const p of this.expandedPids) {
      if (p === pid) {
        return true;
      }
    }
    return false;
  }

  private hasLoadedSub(pid: string): boolean {
    for (const s of this.subReplies) {
      if (s.parentPid === pid) {
        return true;
      }
    }
    return false;
  }

  private subsOf(pid: string): SubReplyItem[] {
    const result: SubReplyItem[] = [];
    for (const s of this.subReplies) {
      if (s.parentPid === pid) {
        result.push(s);
      }
    }
    return result;
  }

  /** 展开/收起楼中楼 */
  private async toggleSub(item: ReplyItem): Promise<void> {
    const pid: string = item.pid;
    if (this.isExpanded(pid)) {
      const arr: string[] = [];
      for (const p of this.expandedPids) {
        if (p !== pid) {
          arr.push(p);
        }
      }
      this.expandedPids = arr;
      return;
    }
    if (this.hasLoadedSub(pid)) {
      this.expandedPids = this.expandedPids.concat([pid]);
      return;
    }
    if (this.loadingSubPid.length > 0) {
      return;
    }
    this.loadingSubPid = pid;
    try {
      const list: SubReplyItem[] = await HupuApi.getSubReplies(this.tid, pid);
      this.subReplies = this.subReplies.concat(list);
      this.expandedPids = this.expandedPids.concat([pid]);
    } catch (e) {
    }
    this.loadingSubPid = '';
  }

  @Builder
  HeaderCard() {
    Column({ space: 10 }) {
      Text(this.detail.title)
        .fontSize(FontSize.headline)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      Row({ space: 8 }) {
        if (this.detail.forumName.length > 0) {
          Text(this.detail.forumName)
            .fontSize(11)
            .fontColor($r('app.color.brand_primary'))
            .maxLines(1)
        }
        Text(this.detail.authorName)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(`${compactCount(this.detail.hits)} 阅读`)
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')

      Text(this.contentText)
        .fontSize(16)
        .lineHeight(26)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      ForEach(this.detail.contentImages, (img: string, idx: number) => {
        Image(thumbUrl(img, 720))
          .width('100%')
          .objectFit(ImageFit.Contain)
          .borderRadius(Radius.sm)
          .backgroundColor($r('app.color.tag_bg'))
          .onClick(() => {
            this.openViewer(this.detail.contentImages, idx);
          })
      }, (img: string, idx: number) => `cimg_${idx}_${img}`)

      Row() {
        Blank()
        Text(this.isFav ? '★ 已收藏' : '☆ 收藏')
          .fontSize(13)
          .fontColor(this.isFav ? Color.White : $r('app.color.text_secondary'))
          .padding({ left: 16, right: 16, top: 7, bottom: 7 })
          .backgroundColor(this.isFav ? $r('app.color.brand_primary') : $r('app.color.tag_bg'))
          .borderRadius(18)
          .onClick(() => {
            this.toggleFav();
          })
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.lg)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(Radius.md)
  }

  @Builder
  SubReplyRow(sub: SubReplyItem) {
    Column({ space: 4 }) {
      Row({ space: 6 }) {
        Text(sub.userName)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
        if (sub.isLz) {
          Text('楼主')
            .fontSize(10)
            .fontColor($r('app.color.brand_primary'))
            .padding({ left: 4, right: 4 })
            .border({ width: 1, color: $r('app.color.brand_primary') })
            .borderRadius(3)
        }
        Blank()
        Text(sub.createDt)
          .fontSize(10)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')

      Text(sub.content)
        .fontSize(14)
        .lineHeight(21)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      ForEach(sub.contentImages, (img: string, idx: number) => {
        Image(thumbUrl(img, 360))
          .width(110)
          .objectFit(ImageFit.Contain)
          .borderRadius(Radius.sm)
          .backgroundColor($r('app.color.tag_bg'))
          .onClick(() => {
            this.openViewer(sub.contentImages, idx);
          })
      }, (img: string, idx: number) => `simg_${sub.pid}_${idx}`)

      Text(`${compactCount(sub.light)} 亮`)
        .fontSize(10)
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.tag_bg'))
    .borderRadius(Radius.sm)
  }

  @Builder
  ReplyCard(item: ReplyItem) {
    Column({ space: 6 }) {
      Row({ space: 6 }) {
        Text(item.userName)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
        if (item.isLz) {
          Text('楼主')
            .fontSize(10)
            .fontColor($r('app.color.brand_primary'))
            .padding({ left: 4, right: 4 })
            .border({ width: 1, color: $r('app.color.brand_primary') })
            .borderRadius(3)
        }
        Blank()
        Text(item.location.length > 0 ? `${item.location} · ${item.createDt}` : item.createDt)
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')

      Text(item.content)
        .fontSize(15)
        .lineHeight(23)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      ForEach(item.contentImages, (img: string, idx: number) => {
        Image(thumbUrl(img, 480))
          .width(140)
          .objectFit(ImageFit.Contain)
          .borderRadius(Radius.sm)
          .backgroundColor($r('app.color.tag_bg'))
          .onClick(() => {
            this.openViewer(item.contentImages, idx);
          })
      }, (img: string, idx: number) => `rimg_${item.pid}_${idx}`)

      Row({ space: 12 }) {
        Blank()
        if (item.replyCount > 0) {
          Text(this.isExpanded(item.pid) ? '收起回复' :
            (this.loadingSubPid === item.pid ? '加载中…' : `${compactCount(item.replyCount)} 条回复 ▾`))
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor($r('app.color.tag_bg'))
            .borderRadius(10)
            .onClick(() => {
              this.toggleSub(item);
            })
        }
        Row({ space: 3 }) {
          Text('🔥')
            .fontSize(11)
          Text(`${compactCount(item.light)}`)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
        }
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .backgroundColor($r('app.color.tag_bg'))
        .borderRadius(10)
        .opacity(this.lightingPid === item.pid ? 0.5 : 1)
        .onClick(() => {
          this.lightFloor(item);
        })
        Text(`${this.replyTargetPid === item.pid ? '回复此楼…' : '回复'}`)
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor($r('app.color.tag_bg'))
          .borderRadius(10)
          .onClick(() => {
            this.replyTargetPid = item.pid;
            this.replyTargetUser = item.userName;
          })
      }
      .width('100%')

      if (this.isExpanded(item.pid)) {
        Column({ space: 6 }) {
          ForEach(this.subsOf(item.pid), (sub: SubReplyItem) => {
            this.SubReplyRow(sub)
          }, (sub: SubReplyItem) => `sub_${sub.pid}`)
          if (this.subsOf(item.pid).length === 0) {
            Text('暂无可见回复')
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(8)
          }
        }
        .width('100%')
        .padding({ top: 4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.bg_card'))
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: '帖子详情' })
        if (this.state === LoadState.Ready) {
        Column() {
        List({ space: 0 }) {
          ListItem() {
            this.HeaderCard()
          }
          .margin({ bottom: Spacing.sm })

          ListItem() {
            Row() {
              Text(`全部回复 ${this.replyTotal > 0 ? this.replyTotal : ''}`)
                .fontSize(FontSize.title)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
            }
            .width('100%')
            .padding({ left: Spacing.lg, right: Spacing.lg, top: 8, bottom: 8 })
          }

          ForEach(this.replies, (item: ReplyItem) => {
            ListItem() {
              Column() {
                this.ReplyCard(item)
                Divider().color($r('app.color.divider'))
              }
            }
          }, (item: ReplyItem, index: number) => `${item.pid}_${index}`)

          ListItem() {
            Column() {
              if (this.replyState === LoadState.Loading) {
                LoadingProgress()
                  .width(24)
                  .height(24)
                  .color($r('app.color.text_tertiary'))
              } else if (this.hasMoreReplies) {
                Text('上拉加载更多回复')
                  .fontSize(12)
                  .fontColor($r('app.color.text_tertiary'))
              } else {
                Text('已加载全部回复')
                  .fontSize(12)
                  .fontColor($r('app.color.text_tertiary'))
              }
            }
            .width('100%')
            .padding({ top: 16, bottom: 24 })
            .alignItems(HorizontalAlign.Center)
          }
        }
        .onReachEnd(() => {
          this.loadMoreReplies();
        })
        .cachedCount(4)
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.bg_page'))
        .scrollBar(BarState.Off)

        // 底部回复输入条
        Row({ space: 8 }) {
          if (this.replyTargetPid.length > 0) {
            Text(`回复 @${this.replyTargetUser} ✕`)
              .fontSize(11)
              .fontColor($r('app.color.brand_primary'))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor($r('app.color.tag_bg'))
              .borderRadius(10)
              .onClick(() => {
                this.replyTargetPid = '';
                this.replyTargetUser = '';
              })
          }
          TextInput({ text: this.inputText, placeholder: '友善回复…' })
            .fontSize(14)
            .layoutWeight(1)
            .height(38)
            .backgroundColor($r('app.color.tag_bg'))
            .borderRadius(19)
            .onChange((v: string) => {
              this.inputText = v;
            })
            .onSubmit(() => {
              this.sendReply();
            })
          Text(this.sendingReply ? '…' : '发送')
            .fontSize(13)
            .fontColor(Color.White)
            .padding({ left: 14, right: 14, top: 9, bottom: 9 })
            .backgroundColor(this.inputText.trim().length > 0 && !this.sendingReply
              ? $r('app.color.brand_primary') : $r('app.color.text_tertiary'))
            .borderRadius(19)
            .onClick(() => {
              this.sendReply();
            })
        }
        .width('100%')
        .padding({ left: Spacing.lg, right: Spacing.lg, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.bg_card'))
        .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.state === LoadState.Loading) {
        Scroll() {
          DetailSkeleton()
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.lg })
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.bg_page'))
      } else {
        StateView({
          state: this.state,
          onRetry: () => {
            this.loadDetail();
            this.loadReplies();
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
