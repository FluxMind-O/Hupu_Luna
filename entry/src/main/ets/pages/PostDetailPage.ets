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
import { promptAction, display } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AppNavBar } from '../views/AppNavBar';
import { ImageKnifeComponent } from '@ohos/imageknife';

/** 视频区尺寸（vp） */
class VideoBox {
  w: number = 0;
  h: number = 0;
}

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
  /**
   * 视频帖播放状态。
   * ready=已就绪（隐藏封面）/ playing=播放中 / muted=静音
   * curSec/durSec=进度与总时长（秒）/ scrubbing=拖动进度条中
   */
  @State videoReady: boolean = false;
  @State videoPlaying: boolean = false;
  @State videoMuted: boolean = true;
  @State videoCurSec: number = 0;
  @State videoDurSec: number = 0;
  @State videoScrubbing: boolean = false;
  /** 视频控制器：Video 常驻不销毁，靠它控制播放/暂停/跳转，保住播放进度 */
  private videoController: VideoController = new VideoController();
  /** 静音按钮按下标记：防止点击穿透触发画面暂停 */
  private mutePressed: boolean = false;
  /** 离开页面时是否处于播放中（返回时据此续播） */
  private resumeOnShow: boolean = false;
  /** 内容区宽度缓存（vp，惰性计算） */
  private cachedContentW: number = 0;

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
    // 播放地址变化（缓存 → 网络最新链接）：重置播放态，等新视频就绪后重新自动播放
    const urlChanged: boolean = d.videoUrl !== this.detail.videoUrl;
    this.detail = d;
    if (urlChanged) {
      this.videoReady = false;
      this.videoPlaying = false;
      this.videoCurSec = 0;
      this.videoDurSec = 0;
      this.videoScrubbing = false;
    }
    const raw: string = d.content.trim();
    if (raw.length > 0 && raw.charAt(0) === '{') {
      this.contentText = '（本楼包含赛事卡片等富媒体内容，请在虎扑原帖中查看）';
      this.detail.contentImages = [];
    } else {
      this.contentText = htmlToText(d.content);
    }
  }

  /**
   * 缓存详情归一化：旧版本快照无 hasVideo/videoUrl 等新增字段，
   * 直接取用会在渲染期读到 undefined，逐字段兜底。
   */
  private normalizeDetail(raw: ThreadDetail): ThreadDetail {
    const d: ThreadDetail = new ThreadDetail();
    d.tid = raw.tid ?? '';
    d.fid = raw.fid ?? '';
    d.title = raw.title ?? '';
    d.content = raw.content ?? '';
    d.contentImages = raw.contentImages ?? [];
    d.authorName = raw.authorName ?? '';
    d.authorHeader = raw.authorHeader ?? '';
    d.authorPuid = raw.authorPuid ?? '';
    d.forumName = raw.forumName ?? '';
    d.hits = raw.hits ?? 0;
    d.replies = raw.replies ?? 0;
    d.lights = raw.lights ?? 0;
    d.hasVideo = raw.hasVideo === true;
    d.videoUrl = raw.videoUrl ?? '';
    d.videoCover = raw.videoCover ?? '';
    d.videoWidth = raw.videoWidth ?? 0;
    d.videoHeight = raw.videoHeight ?? 0;
    return d;
  }

  /** 内容区宽度（vp）：屏幕宽 - 页面左右 padding（卡片自身 padding 已计入外层） */
  private contentWidthVp(): number {
    if (this.cachedContentW > 0) {
      return this.cachedContentW;
    }
    let w: number = 328;
    try {
      const screenW: number = this.getUIContext().px2vp(display.getDefaultDisplaySync().width);
      if (screenW > 0) {
        w = screenW - Spacing.lg * 2;
      }
    } catch (e) {
    }
    this.cachedContentW = w;
    return w;
  }

  /** 视频区尺寸：按原始宽高比计算，高度限幅 160~420vp（超高竖屏反算宽度并居中） */
  private videoBox(): VideoBox {
    const box: VideoBox = new VideoBox();
    const cw: number = this.contentWidthVp();
    let ratio: number = 1.78;
    if (this.detail.videoWidth > 0 && this.detail.videoHeight > 0) {
      ratio = this.detail.videoWidth / this.detail.videoHeight;
    }
    let h: number = cw / ratio;
    let w: number = cw;
    if (h < 160) {
      h = 160;
    }
    if (h > 420) {
      h = 420;
      w = h * ratio;
    }
    box.w = w;
    box.h = h;
    return box;
  }

  /**
   * 点击画面：暂停 / 继续。
   * 走 VideoController 而非切换视频源，暂停后继续从原位置续播（不重头开始）。
   */
  private togglePlay(): void {
    if (this.mutePressed) {
      // 落在静音按钮上：只切静音，不切播放
      return;
    }
    if (this.videoPlaying) {
      this.videoController.pause();
    } else {
      this.videoController.start();
    }
  }

  /** 静音按钮触摸：标记按下态，避免点击穿透触发画面暂停 */
  private onMuteTouch(e: TouchEvent): void {
    if (e.type === TouchType.Down) {
      this.mutePressed = true;
    } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
      setTimeout(() => {
        this.mutePressed = false;
      }, 0);
    }
  }

  /** 进度条拖动/点击跳转：拖动期间用本地值，松手才 seek，避免与播放回调打架 */
  private onScrub(value: number, mode: SliderChangeMode): void {
    if (mode === SliderChangeMode.Begin || mode === SliderChangeMode.Moving) {
      this.videoScrubbing = true;
      this.videoCurSec = value;
      return;
    }
    this.videoCurSec = value;
    this.videoController.setCurrentTime(value);
    this.videoScrubbing = false;
  }

  /** 秒 → mm:ss */
  private formatSec(sec: number): string {
    let s: number = Math.floor(sec);
    if (s < 0 || Number.isNaN(s)) {
      s = 0;
    }
    const m: number = Math.floor(s / 60);
    const r: number = s % 60;
    return `${m < 10 ? '0' : ''}${m}:${r < 10 ? '0' : ''}${r}`;
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
        const norm: ThreadDetail = this.normalizeDetail(d);
        // 视频直链带时效 auth_key（数小时过期），缓存里的链接多数已失效：
        // 缓存阶段不展示视频区，等网络返回最新链接再显示，避免"点了播不动"
        norm.hasVideo = false;
        norm.videoUrl = '';
        this.applyDetail(norm);
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

  /** 点击评论头像/昵称 → 他人个人主页（puid 缺失时提示，不跳无效页） */
  private openUserSpace(puid: string): void {
    if (puid.length === 0) {
      this.toastMsg('无法获取该用户信息');
      return;
    }
    this.pageStack.pushPathByName(RouteName.USER_SPACE, puid);
  }

  /**
   * 头像地址：PC 站返回的头像 URL 多自带 `@150h_150w_2e` 缩略样式，
   * 再叠加 thumbUrl 的 `?x-oss-process=` 会参数冲突，故已带样式时直接用。
   */
  private avatarUrl(url: string): string {
    if (url.length === 0) {
      return '';
    }
    if (url.indexOf('@') >= 0) {
      return url;
    }
    return thumbUrl(url, 120);
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

  /**
   * 正文视频区：进入自动播放（静音），底部静音开关 + 进度条 + 时间。
   * 关键：Video 组件**常驻不销毁**，暂停/继续一律走 VideoController，
   * 避免组件重建导致"暂停后再播放从头开始"。
   */
  @Builder
  VideoCard() {
    Column() {
      Stack({ alignContent: Alignment.Bottom }) {
        Video({ src: this.detail.videoUrl, controller: this.videoController })
          .autoPlay(true)
          .muted(this.videoMuted)
          .loop(true)
          .controls(false)
          .objectFit(ImageFit.Cover)
          .width('100%')
          .height('100%')
          .onStart(() => {
            this.videoPlaying = true;
          })
          .onPause(() => {
            this.videoPlaying = false;
          })
          .onPrepared((e: PreparedInfo) => {
            this.videoReady = true;
            if (e.duration > 0) {
              this.videoDurSec = e.duration;
            }
          })
          .onUpdate((e: PlaybackInfo) => {
            // 拖动进度条期间不由播放回调覆盖显示值
            if (!this.videoScrubbing) {
              this.videoCurSec = e.time;
            }
          })
          .onClick(() => {
            this.togglePlay();
          })

        // 封面层：视频就绪前遮挡加载期黑屏
        if (!this.videoReady) {
          if (this.detail.videoCover.length > 0) {
            Image(thumbUrl(this.detail.videoCover, 720))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
          } else {
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('#000000')
          }
        }

        // 底部控件条：静音 + 当前时间 + 进度条 + 总时长
        if (this.videoReady) {
          Row({ space: 8 }) {
            Row() {
              SymbolGlyph(this.videoMuted
                ? $r('sys.symbol.speaker_slash')
                : $r('sys.symbol.speaker_wave_3'))
                .fontSize(15)
                .fontColor([Color.White])
            }
            .width(28)
            .height(28)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#59000000')
            .borderRadius(14)
            .onTouch((e: TouchEvent) => {
              this.onMuteTouch(e);
            })
            .onClick(() => {
              this.videoMuted = !this.videoMuted;
            })

            Text(this.formatSec(this.videoCurSec))
              .fontSize(11)
              .fontColor(Color.White)

            Slider({
              value: this.videoCurSec,
              min: 0,
              max: this.videoDurSec > 0 ? this.videoDurSec : 1,
              step: 0.1,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .trackThickness(3)
              .trackColor('#4DFFFFFF')
              .selectedColor($r('app.color.brand_primary'))
              .blockColor(Color.White)
              .onChange((value: number, mode: SliderChangeMode) => {
                this.onScrub(value, mode);
              })

            Text(this.formatSec(this.videoDurSec))
              .fontSize(11)
              .fontColor(Color.White)
          }
          .width('100%')
          .padding({ left: 10, right: 14, top: 8, bottom: 8 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor('#66000000')
        }
      }
      .width(this.videoBox().w)
      .height(this.videoBox().h)
      .borderRadius(Radius.sm)
      .clip(true)
      .backgroundColor('#000000')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  HeaderCard() {
    Column({ space: 10 }) {
      Text(this.detail.title)
        .fontSize(FontSize.headline)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      Row({ space: 10 }) {
        if (this.detail.authorHeader.length > 0) {
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: this.avatarUrl(this.detail.authorHeader),
              objectFit: ImageFit.Cover,
              border: { radius: 18 }
            }
          })
            .width(36)
            .height(36)
            .onClick(() => {
              this.openUserSpace(this.detail.authorPuid);
            })
        }
        Column({ space: 4 }) {
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
          }
          .width('100%')
          .onClick(() => {
            this.openUserSpace(this.detail.authorPuid);
          })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(`${compactCount(this.detail.hits)} 阅读`)
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.contentText)
        .fontSize(16)
        .lineHeight(26)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      // 视频帖：正文下方展示播放区（PC 站详情提供 video/videoCover）
      if (this.detail.hasVideo && this.detail.videoUrl.length > 0) {
        this.VideoCard()
      }

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
      this.ReplyAuthorRow(sub.puid, sub.userHeader, sub.userName, sub.isLz, sub.createDt)

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

  /** 评论作者行：头像（可点）+ 昵称（可点）+ 楼主标 + 右侧时间 */
  @Builder
  ReplyAuthorRow(puid: string, userHeader: string, userName: string, isLz: boolean, meta: string) {
    Row({ space: 8 }) {
      if (userHeader.length > 0) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.avatarUrl(userHeader),
            objectFit: ImageFit.Cover,
            border: { radius: 14 }
          }
        })
          .width(28)
          .height(28)
          .onClick(() => {
            this.openUserSpace(puid);
          })
      } else {
        // 无头像兜底占位，保证昵称左侧留白一致（点击同样可进主页）
        Column()
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor($r('app.color.tag_bg'))
          .onClick(() => {
            this.openUserSpace(puid);
          })
      }
      Row({ space: 6 }) {
        Text(userName)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (isLz) {
          Text('楼主')
            .fontSize(10)
            .fontColor($r('app.color.brand_primary'))
            .padding({ left: 4, right: 4 })
            .border({ width: 1, color: $r('app.color.brand_primary') })
            .borderRadius(3)
        }
      }
      .layoutWeight(1)
      .onClick(() => {
        this.openUserSpace(puid);
      })
      if (meta.length > 0) {
        Text(meta)
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
          .maxLines(1)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  ReplyCard(item: ReplyItem) {
    Column({ space: 6 }) {
      this.ReplyAuthorRow(
        item.puid,
        item.userHeader,
        item.userName,
        item.isLz,
        item.location.length > 0 ? `${item.location} · ${item.createDt}` : item.createDt)


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
    .onHidden(() => {
      // 离开页面（进入子页/切后台）：暂停视频避免后台偷跑流量，返回时按原状态续播
      if (this.detail.hasVideo && this.detail.videoUrl.length > 0) {
        this.resumeOnShow = this.videoPlaying;
        this.videoController.pause();
      }
    })
    .onShown(() => {
      if (this.resumeOnShow) {
        this.resumeOnShow = false;
        this.videoController.start();
      }
    })
    .backgroundColor($r('app.color.bg_page'))
  }
}
