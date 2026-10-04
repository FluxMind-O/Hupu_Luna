import { HttpManager } from './HttpManager';
import { SessionManager, writeHeaders } from './SessionManager';

/**
 * 虎扑写接口族（V2 · bbs.hupu.com 桌面 Web 接口，V2-M0 实测口径）
 *
 * 统一响应判定：
 * - code 200 / 1 = 成功
 * - 401 / 401000 / PC022003 = 登录失效 → markInvalid 降级只读
 * - 5003 重复点亮（幂等视为成功）、5009 重复点灭
 */
export class WriteApi {
  /** 写接口统一执行与错误归一 */
  private static async execute(url: string, body: string, needBody: boolean): Promise<number> {
    if (!SessionManager.hasCookie()) {
      throw new Error('未登录，请先在设置页注入 Cookie');
    }
    let text: string;
    try {
      text = await HttpManager.postJson(url, needBody ? body : '', writeHeaders(needBody), '');
    } catch (e) {
      const err = e as Error;
      if (err.message.indexOf('HTTP 401') >= 0) {
        throw new Error('登录已失效，请重新注入 Cookie');
      }
      throw new Error(`请求失败: ${err.message}`);
    }
    try {
      const obj = JSON.parse(text) as WriteRespDto;
      if (obj.code === 200 || obj.code === 1) {
        return 1;
      }
      if (obj.code === 5003) {
        return 2; // 已点亮过（幂等成功）
      }
      if (obj.internalCode === 'PC022003' || obj.code === 401 || obj.code === 401000) {
        throw new Error('登录已失效，请重新注入 Cookie');
      }
      if (obj.msg && obj.msg.length > 0) {
        throw new Error(obj.msg);
      }
      throw new Error(`操作失败（${obj.code}）`);
    } catch (e) {
      if (e instanceof Error) {
        throw e;
      }
      throw new Error('响应解析失败');
    }
  }

  /** 云收藏（实测闭环成功） */
  static async collect(tid: string): Promise<number> {
    return WriteApi.execute(`https://bbs.hupu.com/api/v2/threads/${tid}/collect`, '{}', true);
  }

  /** 取消云收藏（实测闭环成功） */
  static async uncollect(tid: string): Promise<number> {
    return WriteApi.execute(`https://bbs.hupu.com/api/v2/threads/${tid}/collect`, '', false);
  }

  /** 回复点亮（实测闭环成功；puid=被点亮回复作者） */
  static async lightReply(puid: string, pid: string, tid: string, fid: string): Promise<number> {
    const body = `{"puid":"${puid}","pid":"${pid}","tid":"${tid}","fid":"${fid}"}`;
    return WriteApi.execute('https://bbs.hupu.com/pcmapi/pc/bbs/v1/reply/light', body, true);
  }

  /** 取消回复点亮（实测闭环成功） */
  static async cancelLightReply(puid: string, pid: string, tid: string, fid: string): Promise<number> {
    const body = `{"puid":"${puid}","pid":"${pid}","tid":"${tid}","fid":"${fid}"}`;
    return WriteApi.execute('https://bbs.hupu.com/pcmapi/pc/bbs/v1/reply/cancelLight', body, true);
  }

  /** 帖子点亮（pid 为回复 id，必填；已点亮返回幂等码 2） */
  static async light(pid: string, tid: string): Promise<number> {
    const body = `{"tid":"${tid}","pid":"${pid}"}`;
    return WriteApi.execute('https://bbs.hupu.com/api/v2/light', body, true);
  }

  /** 发表回复（鉴权层已实测通过；pid 非空 = 楼中楼） */
  static async createReply(tid: string, fid: string, content: string, pid: string): Promise<number> {
    const fields: string[] = [
      `"tid":"${tid}"`,
      `"fid":"${fid}"`,
      `"content":"${WriteApi.escapeJson(content)}"`
    ];
    if (pid.length > 0) {
      fields.push(`"pid":"${pid}"`);
    }
    const body = `{${fields.join(',')}}`;
    return WriteApi.execute('https://bbs.hupu.com/pcmapi/pc/bbs/v1/createReply', body, true);
  }

  /**
   * 发帖（V2-P2 · createThread 路径已实测有效）。
   *
   * 提交结构逆向自 PC 站新编辑器：
   *   { title, fid, content: HTML, format: JSON.stringify({slateValue, imgList, videoInfo}) }
   * 其中 `content` 为 HTML（与旧格式一致，服务端兼容），
   * `format` 为富文本描述（图片/视频/投票等卡片都在 slateValue 内）。
   * format 为空时只提交旧三字段（纯文字帖）。
   *
   * @param format 富文本 JSON（可为空串）
   */
  static async createThread(title: string, fid: string, content: string, format: string): Promise<number> {
    const fields: string[] = [
      `"title":"${WriteApi.escapeJson(title)}"`,
      `"fid":"${fid}"`,
      `"content":"${WriteApi.escapeJson(content)}"`
    ];
    if (format.length > 0) {
      fields.push(`"format":"${WriteApi.escapeJson(format)}"`);
    }
    const body = `{${fields.join(',')}}`;
    return WriteApi.execute('https://bbs.hupu.com/pcmapi/pc/bbs/v1/createThread', body, true);
  }

  private static escapeJson(s: string): string {
    let r: string = s;
    r = r.replace(/\\/g, '\\\\');
    r = r.replace(/"/g, '\\"');
    r = r.replace(/\n/g, '\\n');
    r = r.replace(/\r/g, '');
    return r;
  }
}

interface WriteRespDto {
  code?: number;
  message?: string;
  msg?: string;
  internalCode?: string;
  data?: object | null;
}
