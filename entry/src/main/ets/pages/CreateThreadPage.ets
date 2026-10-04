import { HupuApi } from '../network/HupuApi';
import { WriteApi } from '../network/WriteApi';
import { OssUpload } from '../network/OssUpload';
import { ZoneCategory, ZoneTopic } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, Radius } from '../common/Theme';
import { thumbUrl } from '../common/Utils';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { ImageKnifeComponent } from '@ohos/imageknife';

const MIN_PUBLISH_INTERVAL: number = 30 * 1000;

/**
 * 发帖页（对齐官方三 Tab 形态：帖子 / 视频 / 投票）
 *
 * 布局（自下而上与官方一致）：
 *   发布按钮 → Tab 栏 → 工具栏（专区 / 公开 / 创作类型 + 添加话题）→ 内容区 → 顶部关闭
 *
 * 功能状态：
 * - 帖子：标题 + 正文 + 话题区 → **发布可用**（createThread 接口已验证）
 * - 视频 / 投票：UI 已按官方还原，但**发布链路未接通**（见下方说明），
 *   点击发布时给出明确提示，不做静默失败。
 *
 * 未接通原因（已实测确认）：
 * - 视频需先向 `/pcmapi/pc/bbs/v1/video/auth` 取授权，再把文件直传阿里云 OSS
 *   （STS 凭证接口 + `getSignData` 签名算法 + OSS SDK），链路重且风控敏感；
 * - 投票需以官方编辑器的 `format: JSON.stringify({slateValue, imgList, videoInfo})`
 *   结构提交（投票是富文本内的 slate 卡片元素），与当前已验证的 `{title,fid,content}`
 *   接口不同源，需另行验证。
 */
@Component
export struct CreateThreadPage {
  /** 预设话题区（从专区页进入时传入，格式："topicId|topicName"；空=需手动选择） */
  param: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State categories: ZoneCategory[] = [];
  @State state: LoadState = LoadState.Loading;
  @State showPicker: boolean = false;
  @State picked: ZoneTopic | null = null;
  /** 0=帖子 / 1=视频 / 2=投票 */
  @State tab: number = 0;
  /** 帖子正文数据 */
  @State title: string = '';
  @State content: string = '';
  /** 视频标题 */
  @State videoTitle: string = '';
  /** 投票数据 */
  @State pollTitle: string = '';
  @State pollOptions: string[] = ['', ''];
  @State pollDesc: string = '';
  /** 投票形式：false=文字投票 / true=图片投票 */
  @State pollImageMode: boolean = false;
  @State pollDuration: string = '不限';
  @State pollSingle: boolean = true;
  @State publishing: boolean = false;
  /** 已上传的图片地址（发布时写入 format.imgList） */
  @State uploadedImages: string[] = [];
  /** 图片上传中 */
  @State uploading: boolean = false;

  aboutToAppear(): void {
    // 专区页进入：预设话题区，用户无需再选（param 可能未传）
    const parts: string[] = (this.param ?? '').split('|');
    if (parts.length > 0 && parts[0].length > 0) {
      const preset: ZoneTopic = new ZoneTopic();
      preset.topicId = Number(parts[0]);
      preset.topicName = parts.length > 1 ? parts[1] : '';
      if (preset.topicId > 0) {
        this.picked = preset;
      }
    }
    this.loadZones();
  }

  private getCtx(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  private toast(msg: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: msg });
    } catch (e) {
    }
  }

  private async loadZones(): Promise<void> {
    try {
      this.categories = await HupuApi.getZones();
      this.state = LoadState.Ready;
    } catch (e) {
      this.state = LoadState.Error;
    }
  }

  /** 从 uri 推断扩展名（默认 png） */
  private extOf(uri: string): string {
    const dot: number = uri.lastIndexOf('.');
    if (dot < 0) {
      return 'png';
    }
    const e: string = uri.substring(dot + 1).toLowerCase();
    return e.length > 0 && e.length <= 5 ? e : 'png';
  }

  /** 扩展名 → MIME */
  private mimeOf(ext: string): string {
    if (ext === 'jpg' || ext === 'jpeg') {
      return 'image/jpeg';
    }
    if (ext === 'gif') {
      return 'image/gif';
    }
    if (ext === 'webp') {
      return 'image/webp';
    }
    if (ext === 'png') {
      return 'image/png';
    }
    if (ext === 'mp4') {
      return 'video/mp4';
    }
    return 'application/octet-stream';
  }

  /** 读取本地文件字节 */
  private readFile(uri: string): Uint8Array {
    const file: fileIo.File = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    try {
      const size: number = fileIo.statSync(file.fd).size;
      const buf: ArrayBuffer = new ArrayBuffer(size);
      fileIo.readSync(file.fd, buf);
      return new Uint8Array(buf);
    } finally {
      fileIo.closeSync(file);
    }
  }

  /**
   * 选择图片并上传到虎扑图床。
   * 链路：系统选择器 → 读字节 → STS 凭证 → 阿里云 OSS 直传 → 得公网地址
   */
  private async pickAndUploadImages(): Promise<void> {
    if (this.uploading) {
      return;
    }
    if (this.uploadedImages.length >= 9) {
      this.toast('最多 9 张图片');
      return;
    }
    let uris: string[] = [];
    try {
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const opts: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      opts.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      opts.maxSelectNumber = 9 - this.uploadedImages.length;
      const res: photoAccessHelper.PhotoSelectResult = await picker.select(opts);
      uris = res.photoUris ?? [];
    } catch (e) {
      // 用户取消选择：静默
      return;
    }
    if (uris.length === 0) {
      return;
    }
    this.uploading = true;
    let ok: number = 0;
    const added: string[] = [];
    for (const uri of uris) {
      try {
        const ext: string = this.extOf(uri);
        const data: Uint8Array = this.readFile(uri);
        const url: string = await OssUpload.uploadImage(data, ext, this.mimeOf(ext));
        added.push(url);
        ok++;
      } catch (e) {
        this.toast(e instanceof Error ? e.message : '图片上传失败');
        break;
      }
    }
    if (added.length > 0) {
      this.uploadedImages = this.uploadedImages.concat(added);
    }
    this.uploading = false;
    if (ok > 0) {
      this.toast(`已上传 ${ok} 张图片`);
    }
  }

  private removeImage(idx: number): void {
    const arr: string[] = [];
    for (let i: number = 0; i < this.uploadedImages.length; i++) {
      if (i !== idx) {
        arr.push(this.uploadedImages[i]);
      }
    }
    this.uploadedImages = arr;
  }

  /**
   * 构造 format 字段（对齐官方新编辑器提交结构）：
   *   { slateValue: [...节点], imgList: [{remoteUrl, key}], videoInfo: {extra:1} }
   * - 段落节点：{type:'paragraph', children:[{text}]}
   * - 图片节点：{type:'img', children:[{text:''}], imageInfo:{remoteUrl}}
   */
  private buildFormat(): string {
    const nodes: Record<string, Object>[] = [];
    if (this.content.trim().length > 0) {
      const para: Record<string, Object> = {
        'type': 'paragraph',
        'children': [{ 'text': this.content } as Record<string, Object>]
      };
      nodes.push(para);
    }
    const imgList: Record<string, Object>[] = [];
    for (const url of this.uploadedImages) {
      nodes.push({
        'type': 'img',
        'children': [{ 'text': '' } as Record<string, Object>],
        'imageInfo': { 'remoteUrl': url } as Record<string, Object>
      });
      imgList.push({
        'remoteUrl': url,
        'key': url.substring(Math.max(0, url.length - 12))
      });
    }
    const payload: Record<string, Object> = {
      'slateValue': nodes,
      'imgList': imgList,
      'videoInfo': { 'extra': 1 } as Record<string, Object>
    };
    return JSON.stringify(payload);
  }

  /** 正文 HTML（与官方一致：段落用 <p>，图片用 <img>） */
  private buildContentHtml(): string {
    const parts: string[] = [];
    const text: string = this.content.trim();
    if (text.length > 0) {
      // 换行转 <br>，与 slate 段落语义对齐
      const html: string = text.replace(new RegExp('\n', 'g'), '<br>');
      parts.push(`<p>${html}</p>`);
    }
    for (const url of this.uploadedImages) {
      parts.push(`<p><img src="${url}"/></p>`);
    }
    return parts.join('');
  }

  /** 发布：帖子 Tab 走已验证的 createThread（支持图片）；视频/投票 Tab 未接通，给出明确提示 */
  private async publish(): Promise<void> {
    if (this.publishing || this.uploading) {
      return;
    }
    if (this.tab === 1) {
      this.toast('视频发布尚未接通（视频需先授权转码，链路仍在验证）');
      return;
    }
    if (this.tab === 2) {
      this.toast('投票发布尚未接通（投票卡片结构待验证）');
      return;
    }
    const t: string = this.title.trim();
    const c: string = this.content.trim();
    if (t.length === 0) {
      this.toast('请填写标题');
      return;
    }
    // 官方允许"仅图片无正文"，故正文与图片皆空才拦截
    if (c.length === 0 && this.uploadedImages.length === 0) {
      this.toast('请填写正文或添加图片');
      return;
    }
    if (this.picked === null) {
      this.toast('请选择话题区');
      return;
    }
    this.publishing = true;
    try {
      const html: string = this.buildContentHtml();
      const format: string = this.buildFormat();
      await WriteApi.createThread(t, String(this.picked.topicId), html, format);
      this.toast('发布成功');
      this.pageStack.pop();
    } catch (e) {
      this.toast(e instanceof Error ? e.message : '发布失败，请重试');
    }
    this.publishing = false;
  }

  /** 顶部：关闭 + 标题（对齐官方 ✕） */
  @Builder
  TopBar() {
    Row({ space: 4 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(20)
          .fontColor([$r('app.color.text_primary')])
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.pageStack.pop();
      })

      Text('发帖')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
    }
    .constraintSize({ minHeight: 44 })
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 8, right: 16, top: px2vp(this.getTopAvoid()) + 4, bottom: 4 })
    .backgroundColor($r('app.color.bg_page'))
  }

  private getTopAvoid(): number {
    try {
      const v: number | undefined = AppStorage.get<number>('topAvoidPx');
      return v !== undefined ? v : 0;
    } catch (e) {
      return 0;
    }
  }

  // ---------------- 帖子 Tab ----------------

  @Builder
  PostTab() {
    Column() {
      // 标题：官方为大字号通栏输入（"分享你的心情、观点和经历…"）
      TextInput({ text: this.title, placeholder: '分享你的心情、观点和经历…' })
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .placeholderFont({ size: 17 })
        .backgroundColor(Color.Transparent)
        .padding(0)
        .height(52)
        .onChange((v: string) => {
          this.title = v;
        })

      Divider().color($r('app.color.divider'))

      // 正文（选填）
      TextArea({ text: this.content, placeholder: '输入正文(选填)' })
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .placeholderFont({ size: 15 })
        .backgroundColor(Color.Transparent)
        .padding(0)
        .height(120)
        .onChange((v: string) => {
          this.content = v;
        })

      // 已上传图片（可删除）
      if (this.uploadedImages.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.uploadedImages, (url: string, idx: number) => {
            Stack({ alignContent: Alignment.TopEnd }) {
              ImageKnifeComponent({
                imageKnifeOption: {
                  loadSrc: thumbUrl(url, 200),
                  objectFit: ImageFit.Cover,
                  border: { radius: 4 }
                }
              })
                .width(84)
                .height(84)
              // 删除角标
              Text('✕')
                .fontSize(11)
                .fontColor(Color.White)
                .width(18)
                .height(18)
                .textAlign(TextAlign.Center)
                .backgroundColor('#99000000')
                .borderRadius(9)
                .margin(3)
                .onClick(() => {
                  this.removeImage(idx);
                })
            }
            .width(84)
            .height(84)
            .margin({ right: 8, bottom: 8 })
          }, (url: string, idx: number) => `up_${idx}_${url}`)
        }
        .width('100%')
        .padding({ top: 12 })
      }

      // 添加图片（上传中显示进度提示）
      Row() {
        Column({ space: 4 }) {
          if (this.uploading) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color($r('app.color.text_tertiary'))
            Text('上传中…')
              .fontSize(10)
              .fontColor($r('app.color.text_tertiary'))
          } else {
            SymbolGlyph($r('sys.symbol.plus'))
              .fontSize(22)
              .fontColor([$r('app.color.text_tertiary')])
          }
        }
        .width(84)
        .height(84)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.tag_bg'))
        .borderRadius(4)
        .onClick(() => {
          this.pickAndUploadImages();
        })
      }
      .width('100%')
      .padding({ top: this.uploadedImages.length > 0 ? 0 : 12 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 12 })
  }

  // ---------------- 视频 Tab ----------------

  @Builder
  VideoTab() {
    Column() {
      // 添加视频大块（对齐官方）
      Column({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(34)
          .fontColor([$r('app.color.text_tertiary')])
        Text('添加视频')
          .fontSize(13)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')
      .height(180)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.tag_bg'))
      .borderRadius(4)
      .onClick(() => {
        this.toast('视频上传尚未接通（需先打通 OSS 直传链路）');
      })

      // 输入标题
      TextInput({ text: this.videoTitle, placeholder: '输入标题' })
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .placeholderFont({ size: 17 })
        .backgroundColor(Color.Transparent)
        .padding(0)
        .height(52)
        .margin({ top: 12 })
        .onChange((v: string) => {
          this.videoTitle = v;
        })

      Divider().color($r('app.color.divider'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 12 })
  }

  // ---------------- 投票 Tab ----------------

  @Builder
  PollTab() {
    Column() {
      // 标题
      TextInput({ text: this.pollTitle, placeholder: '输入标题' })
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .placeholderFont({ size: 17 })
        .backgroundColor(Color.Transparent)
        .padding(0)
        .height(52)
        .onChange((v: string) => {
          this.pollTitle = v;
        })

      Divider().color($r('app.color.divider'))

      // 文字投票 / 图片投票 切换
      Row({ space: 8 }) {
        Text('文字投票')
          .fontSize(13)
          .fontColor(this.pollImageMode ? $r('app.color.text_secondary') : $r('app.color.text_primary'))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.pollImageMode ? Color.Transparent : $r('app.color.tag_bg'))
          .borderRadius(4)
          .onClick(() => {
            this.pollImageMode = false;
          })
        Text('图片投票')
          .fontSize(13)
          .fontColor(this.pollImageMode ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.pollImageMode ? $r('app.color.tag_bg') : Color.Transparent)
          .borderRadius(4)
          .onClick(() => {
            this.pollImageMode = true;
          })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      // 选项
      ForEach(this.pollOptions, (opt: string, idx: number) => {
        Row({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.list_bullet'))
            .fontSize(18)
            .fontColor([$r('app.color.text_tertiary')])
          TextInput({ text: opt, placeholder: `选项 ${idx + 1}` })
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_tertiary'))
            .placeholderFont({ size: 15 })
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .height(46)
            .onChange((v: string) => {
              this.pollOptions[idx] = v;
            })
        }
        .width('100%')
        .padding({ left: 12, right: 12 })
        .backgroundColor($r('app.color.tag_bg'))
        .borderRadius(4)
        .margin({ bottom: 8 })
      }, (opt: string, idx: number) => `poll_${idx}`)

      // 添加选项
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(18)
          .fontColor([$r('app.color.text_tertiary')])
        Text('添加选项')
          .fontSize(15)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')
      .height(46)
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.tag_bg'))
      .borderRadius(4)
      .onClick(() => {
        if (this.pollOptions.length >= 20) {
          this.toast('最多 20 个选项');
          return;
        }
        this.pollOptions = this.pollOptions.concat(['']);
      })

      // 投票时长 / 投票类型
      Row() {
        Row({ space: 4 }) {
          Text(`投票时长: ${this.pollDuration}`)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
          SymbolGlyph($r('sys.symbol.chevron_down'))
            .fontSize(14)
            .fontColor([$r('app.color.text_secondary')])
        }
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .borderRadius(4)
        .backgroundColor($r('app.color.tag_bg'))
        .bindMenu([
          { value: '不限', action: () => { this.pollDuration = '不限'; } },
          { value: '1 天', action: () => { this.pollDuration = '1 天'; } },
          { value: '3 天', action: () => { this.pollDuration = '3 天'; } },
          { value: '7 天', action: () => { this.pollDuration = '7 天'; } }
        ])

        Blank()

        Row({ space: 4 }) {
          Text(`投票类型: ${this.pollSingle ? '单选' : '多选'}`)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
          SymbolGlyph($r('sys.symbol.chevron_down'))
            .fontSize(14)
            .fontColor([$r('app.color.text_secondary')])
        }
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .borderRadius(4)
        .backgroundColor($r('app.color.tag_bg'))
        .bindMenu([
          { value: '单选', action: () => { this.pollSingle = true; } },
          { value: '多选', action: () => { this.pollSingle = false; } }
        ])
      }
      .width('100%')
      .padding({ top: 12 })

      // 投票说明
      TextArea({ text: this.pollDesc, placeholder: '添加投票说明…' })
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .placeholderFont({ size: 15 })
        .backgroundColor(Color.Transparent)
        .padding(0)
        .height(80)
        .margin({ top: 8 })
        .onChange((v: string) => {
          this.pollDesc = v;
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 12 })
  }

  // ---------------- 话题区选择面板 ----------------

  @Builder
  PickerPanel() {
    Column() {
      Text('选择话题区')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .padding({ top: 10, bottom: 6 })
      if (this.categories.length === 0) {
        Text('话题列表加载失败，点击重试')
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 24, bottom: 24 })
          .onClick(() => {
            this.state = LoadState.Loading;
            this.loadZones();
          })
      }
      Scroll() {
        Column() {
          ForEach(this.categories, (cat: ZoneCategory) => {
            Text(cat.name)
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .padding({ top: 8, bottom: 4 })
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(cat.topics, (t: ZoneTopic) => {
                Text(t.topicName)
                  .fontSize(12)
                  .fontColor(this.picked !== null && this.picked.topicId === t.topicId
                    ? Color.White : $r('app.color.text_primary'))
                  .backgroundColor(this.picked !== null && this.picked.topicId === t.topicId
                    ? $r('app.color.brand_primary') : $r('app.color.tag_bg'))
                  .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                  .borderRadius(Radius.sm)
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => {
                    this.picked = t;
                    this.showPicker = false;
                  })
              }, (t: ZoneTopic) => `pick_${t.topicId}`)
            }
            .width('100%')
          }, (cat: ZoneCategory) => `pickcat_${cat.categoryId}`)
        }
        .width('100%')
      }
      .width('100%')
      .height(240)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 8 })
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(Radius.md)
  }

  // ---------------- 底部区域 ----------------

  /** 工具栏：专区 / 公开 / 创作类型 + 添加话题 */
  @Builder
  BottomTools() {
    Column() {
      if (this.showPicker) {
        this.PickerPanel()
      } else {
        Row({ space: 10 }) {
          // 话题区（带小图标）
          Row({ space: 4 }) {
            Text(this.picked !== null && this.picked.topicName.length > 0 ? this.picked.topicName : '选择话题区')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .constraintSize({ maxWidth: 160 })
          .onClick(() => {
            this.showPicker = true;
          })

          Blank()

          // 公开
          Row({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.lock_open'))
              .fontSize(13)
              .fontColor([$r('app.color.text_secondary')])
            Text('公开')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .border({ width: 1, color: $r('app.color.divider') })
          .borderRadius(4)

          // 创作类型
          Row({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.square_grid_2x2'))
              .fontSize(13)
              .fontColor([$r('app.color.text_secondary')])
            Text('创作类型')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .border({ width: 1, color: $r('app.color.divider') })
          .borderRadius(4)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ left: Spacing.lg, right: Spacing.lg, top: 6, bottom: 6 })

        // 添加话题
        Row({ space: 6 }) {
          SymbolGlyph($r('sys.symbol.hash'))
            .fontSize(14)
            .fontColor([$r('app.color.text_secondary')])
          Text('添加话题')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding({ left: Spacing.lg, right: Spacing.lg, top: 4, bottom: 10 })
        .onClick(() => {
          this.toast('话题标签暂未接通');
        })
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
  }

  /** Tab 栏：帖子 / 视频 / 投票 */
  @Builder
  TabBar() {
    Row() {
      this.TabItem('帖子', 0)
      this.TabItem('视频', 1)
      this.TabItem('投票', 2)
    }
    .width('100%')
    .padding({ top: 8, bottom: 4 })
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  TabItem(label: string, idx: number) {
    Column({ space: 5 }) {
      Text(label)
        .fontSize(15)
        .fontWeight(this.tab === idx ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.tab === idx ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
      Row()
        .width(24)
        .height(3)
        .borderRadius(2)
        .backgroundColor(this.tab === idx ? $r('app.color.brand_primary') : Color.Transparent)
    }
    .layoutWeight(1)
    .onClick(() => {
      if (this.tab !== idx) {
        this.tab = idx;
        this.showPicker = false;
      }
    })
  }

  /** 发布按钮 */
  @Builder
  PublishArea() {
    Column({ space: 6 }) {
      Text(this.publishing ? '正在发布…' : '发布')
        .fontSize(15)
        .fontColor(this.publishing ? $r('app.color.text_tertiary') : Color.White)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .backgroundColor(this.publishing ? $r('app.color.tag_bg') : $r('app.color.brand_primary'))
        .borderRadius(Radius.sm)
        .onClick(() => {
          this.publish();
        })

      if (this.tab === 0) {
        Text('发帖为风控敏感操作，发布间隔过短可能触发虎扑风控，请理性发帖。')
          .fontSize(11)
          .lineHeight(16)
          .fontColor($r('app.color.text_tertiary'))
          .width('100%')
      } else {
        Text(this.tab === 1
          ? '视频发布需先打通文件上传链路，当前仅完成界面。'
          : '投票发布需先验证富文本提交结构，当前仅完成界面。')
          .fontSize(11)
          .lineHeight(16)
          .fontColor($r('app.color.text_tertiary'))
          .width('100%')
      }
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 4, bottom: 12 })
    .backgroundColor($r('app.color.bg_card'))
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()
        if (this.picked === null && (this.state === LoadState.Loading || this.state === LoadState.Error)) {
          // 已预设话题区时不阻塞：话题列表加载失败也应能直接发帖
          Column() {
            StateView({
              state: this.state,
              onRetry: (): void => {
                this.state = LoadState.Loading;
                this.loadZones();
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          Scroll() {
            Column() {
              if (this.tab === 0) {
                this.PostTab()
              } else if (this.tab === 1) {
                this.VideoTab()
              } else {
                this.PollTab()
              }
            }
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .align(Alignment.Top)
          .backgroundColor($r('app.color.bg_page'))

          Divider().color($r('app.color.divider'))
          this.BottomTools()
          Divider().color($r('app.color.divider'))
          this.TabBar()
          Divider().color($r('app.color.divider'))
          this.PublishArea()
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
