/**
 * 链路健康度（熔断器模式）
 *
 * 每条数据链路（按 key 区分：如 detail-api / thread-list / pc-page）记录连续失败次数：
 * - 连续 FAIL_THRESHOLD 次失败 → 熔断 OPEN_MS 毫秒，期间 allow() 返回 false，调用方直接走兜底链路
 * - 熔断到期后进入半开态：放行一次真实请求，成功则恢复，失败则重新熔断
 * 目的：主链路失效时快速切换兜底，避免每个用户请求都先撞一遍失败超时。
 */
const FAIL_THRESHOLD: number = 3;
const OPEN_MS: number = 60000;

class LinkState {
  fails: number = 0;
  openAt: number = 0;
}

export class LinkHealth {
  private static states: Map<string, LinkState> = new Map();

  /** 上报一次请求结果 */
  static record(key: string, ok: boolean): void {
    let st: LinkState | undefined = LinkHealth.states.get(key);
    if (!st) {
      st = new LinkState();
      LinkHealth.states.set(key, st);
    }
    if (ok) {
      st.fails = 0;
      st.openAt = 0;
      return;
    }
    st.fails = st.fails + 1;
    if (st.fails >= FAIL_THRESHOLD) {
      st.openAt = Date.now();
    }
  }

  /** 是否放行走该链路（熔断中返回 false；到期后半开放行一次） */
  static allow(key: string): boolean {
    const st: LinkState | undefined = LinkHealth.states.get(key);
    if (!st || st.openAt === 0) {
      return true;
    }
    if (Date.now() - st.openAt >= OPEN_MS) {
      // 半开：放行一次，若本次成功 record(true) 会彻底恢复
      st.fails = FAIL_THRESHOLD - 1;
      st.openAt = 0;
      return true;
    }
    return false;
  }

  /** 监控信息：key -> fails/open 剩余秒 */
  static snapshot(): string[] {
    const lines: string[] = [];
    LinkHealth.states.forEach((st: LinkState, key: string) => {
      const openRemain: number = st.openAt === 0 ? 0 : Math.max(0, Math.floor((OPEN_MS - (Date.now() - st.openAt)) / 1000));
      const status: string = st.openAt === 0 ? 'ok' : `open(${openRemain}s)`;
      lines.push(`${key}: fails=${st.fails} ${status}`);
    });
    return lines;
  }
}
