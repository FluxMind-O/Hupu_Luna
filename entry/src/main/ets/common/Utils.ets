/**
 * 通用工具：HTML 处理、时间格式化
 */

const TAG_REG: RegExp = new RegExp('<[^>]+>', 'g');
const IMG_REG: RegExp = new RegExp('<img[^>]+src="([^"]+)"', 'g');

/** HTML 转纯文本（保留段落换行） */
export function htmlToText(html: string): string {
  if (!html) {
    return '';
  }
  let s: string = html;
  s = s.replace(new RegExp('<br\\s*/?>', 'gi'), '\n');
  s = s.replace(new RegExp('</p>', 'gi'), '\n');
  s = s.replace(TAG_REG, '');
  s = s.replace(new RegExp('&nbsp;', 'g'), ' ');
  s = s.replace(new RegExp('&amp;', 'g'), '&');
  s = s.replace(new RegExp('&lt;', 'g'), '<');
  s = s.replace(new RegExp('&gt;', 'g'), '>');
  s = s.replace(new RegExp('&quot;', 'g'), '"');
  s = s.replace(new RegExp('&#39;', 'g'), "'");
  s = s.replace(new RegExp('\\n{3,}', 'g'), '\n\n');
  return s.trim();
}

/** 提取 HTML 中的图片地址 */
export function extractImages(html: string): string[] {
  const result: string[] = [];
  if (!html) {
    return result;
  }
  const reg: RegExp = new RegExp(IMG_REG.source, 'g');
  let m: RegExpExecArray | null = reg.exec(html);
  while (m !== null) {
    const url: string = m[1];
    if (url.indexOf('http') === 0) {
      result.push(url);
    }
    m = reg.exec(html);
  }
  return result;
}

/** 帖子正文字段兼容：纯 HTML 或 {"team":...} 卡片 JSON */
export function normalizeContent(raw: string): string {
  if (!raw) {
    return '';
  }
  const t: string = raw.trim();
  if (t.indexOf('{') === 0) {
    return '（含赛事卡片，详见原帖）';
  }
  return raw;
}

/** 秒级时间戳 → 相对时间 / 日期 */
export function formatTime(sec: number): string {
  if (sec <= 0) {
    return '';
  }
  const now: number = Math.floor(Date.now() / 1000);
  const diff: number = now - sec;
  if (diff < 60) {
    return '刚刚';
  }
  if (diff < 3600) {
    return `${Math.floor(diff / 60)}分钟前`;
  }
  if (diff < 86400) {
    return `${Math.floor(diff / 3600)}小时前`;
  }
  if (diff < 86400 * 7) {
    return `${Math.floor(diff / 86400)}天前`;
  }
  const d: Date = new Date(sec * 1000);
  const mm: number = d.getMonth() + 1;
  const dd: number = d.getDate();
  return `${mm}-${dd < 10 ? '0' + dd : dd}`;
}

/** 图片地址瘦身：OSS 参数裁剪 */
export function thumbUrl(url: string, width: number): string {
  if (!url) {
    return '';
  }
  if (url.indexOf('hoopchina.com.cn') < 0) {
    return url;
  }
  const base: string = url.indexOf('?') >= 0 ? `${url}&` : `${url}?`;
  return `${base}x-oss-process=image/resize,w_${width}/format,webp`;
}
