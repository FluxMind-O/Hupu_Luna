import { HttpManager, RequestOptions, ExtraHeaders } from './HttpManager';
import { SessionManager } from './SessionManager';

const MOBILE_UA: string =
  'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36';

/** 我的页个人信息（m.hupu.com/my SSR 解析） */
export class MyProfile {
  avatar: string = '';
  username: string = '';
  level: string = '';
  calories: string = '';
  regDate: string = '';
  gender: string = '';
  selfIntro: string = '';
  joinedDays: number = 0;
  /** 主题帖/回帖条数（SSR 首页条数，20 上限即 20+） */
  threadCount: number = 0;
  replyCount: number = 0;
}

/** 我的主题帖/回帖条目（m 站 userthreads/userreplies SSR 解析） */
export class MyThreadItem {
  tid: string = '';
  title: string = '';
  lights: number = 0;
  replies: number = 0;
}

/**
 * m 站“我的”域接口（SSR 页面解析，需登录 Cookie）
 * - m.hupu.com/my：头像/昵称/等级/卡路里
 * - m.hupu.com/my/userdetail：数字ID/性别/注册时间/自我介绍
 * - m.hupu.com/my/userthreads / userreplies：主题帖/回帖流
 */
export class MyApi {
  private static async getHtml(path: string): Promise<string> {
    const cookie: string = SessionManager.cookieHeader();
    if (cookie.length === 0) {
      throw new Error('未登录');
    }
    const url: string = `https://m.hupu.com${path}`;
    const opts: RequestOptions = new RequestOptions();
    opts.ua = MOBILE_UA;
    const h: ExtraHeaders = new ExtraHeaders();
    h.cookie = cookie;
    opts.headers = h;
    return HttpManager.request(url, opts);
  }

  /** 我的资料（my + userdetail 合并） */
  static async getMyProfile(): Promise<MyProfile> {
    const homeHtml: string = await MyApi.getHtml('/my');
    const p: MyProfile = new MyProfile();
    // 头像：url(...) 内地址
    const av = homeHtml.match(/class="avatar"\s+style="background-image:\s*url\(([^)]+)\)/);
    if (av !== null) {
      p.avatar = av[1];
    }
    const nm = homeHtml.match(/<div class="name">\s*([^<]+?)\s*<\/div>/);
    if (nm !== null) {
      p.username = nm[1];
    }
    const lv = homeHtml.match(/<div class="level">([^<]*?)<\/div>/);
    if (lv !== null) {
      p.level = lv[1].replace(/&nbsp;/g, ' ').trim();
    }
    const cal = homeHtml.match(/<div class="calories">([^<]*?)<\/div>/);
    if (cal !== null) {
      p.calories = cal[1].replace(/&nbsp;/g, ' ').trim();
    }
    // userdetail：注册时间等
    try {
      const dHtml: string = await MyApi.getHtml('/my/userdetail');
      const reg = dHtml.match(/注册时间\s*<\/[^>]+>\s*<[^>]+>\s*([0-9\-: ]+)/);
      if (reg !== null) {
        p.regDate = reg[1].trim();
        const ts = Date.parse(p.regDate.replace(/-/g, '/'));
        if (!Number.isNaN(ts)) {
          p.joinedDays = Math.max(0, Math.floor((Date.now() - ts) / 86400000));
        }
      }
      const g = dHtml.match(/性别\s*<\/[^>]+>\s*<[^>]+>\s*([^<\s]+)/);
      if (g !== null) {
        p.gender = g[1].trim();
      }
      // userdetail 兜底：论坛等级 / 银行现金（卡路里）——真机 home 页部分字段缺失
      const lv2 = dHtml.match(/论坛等级\s*<\/[^>]+>\s*<[^>]+>\s*([^<]+?)\s*</);
      if (lv2 !== null && p.level.length === 0) {
        p.level = lv2[1].trim();
      }
      if (lv2 !== null && p.level.length === 0) {
        p.level = '论坛等级 ' + lv2[1].trim();
      }
      const cal2 = dHtml.match(/(?:银行现金|卡路里)\s*<\/[^>]+>\s*<[^>]+>\s*([^<]+?)\s*</);
      if (cal2 !== null && p.calories.length === 0) {
        p.calories = cal2[1].trim();
      }
    } catch (e) {
    }
    // 条数统计（首页条数，20 表示 20+）
    try {
      const thHtml: string = await MyApi.getHtml('/my/userthreads');
      const thBlocks = thHtml.match(/class="bbs-list-a"/g) || [];
      p.threadCount = thBlocks.length;
    } catch (e) {
    }
    try {
      const rpHtml: string = await MyApi.getHtml('/my/userreplies');
      const rpBlocks = rpHtml.match(/class="bbs-list-a"/g) || [];
      p.replyCount = rpBlocks.length;
    } catch (e) {
    }
    return p;
  }

  /** 从 userthreads / userreplies 页解析帖子流 */
  static async getMyThreads(path: string): Promise<MyThreadItem[]> {
    const html: string = await MyApi.getHtml(path);
    const result: MyThreadItem[] = [];
    // 逐 <li> 块解析
    const blocks = html.match(/<a href="\/\/m\.hupu\.com\/bbs\/(\d+)\.html"[^>]*class="bbs-list-a"[\s\S]*?<\/a>/g) || [];
    for (const block of blocks) {
      const item: MyThreadItem = new MyThreadItem();
      const tid = block.match(/bbs\/(\d+)\.html/);
      if (tid === null) {
        continue;
      }
      item.tid = tid[1];
      const title = block.match(/<h3>([\s\S]*?)<\/h3>/);
      item.title = title !== null ? title[1].trim() : '';
      const bright = block.match(/class="bright-no">(\d+)</);
      item.lights = bright !== null ? Number(bright[1]) : 0;
      // icon-comment 后第一个 <span>数字</span>
      const rep = block.match(/icon-comment"[^>]*>\s*<\/i>\s*<span>(\d+)<\/span>/);
      item.replies = rep !== null ? Number(rep[1]) : 0;
      if (item.title.length > 0) {
        result.push(item);
      }
    }
    return result;
  }
}
