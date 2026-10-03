/** 标签小胶囊 */
@Component
export struct TagChip {
  @Prop text: string = '';
  @Prop active: boolean = false;
  onTap: () => void = () => {
  };

  build() {
    Text(this.text)
      .fontSize(13)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 12, right: 12, top: 5, bottom: 5 })
      .borderRadius(14)
      .backgroundColor(this.active ? $r('app.color.brand_primary') : $r('app.color.tag_bg'))
      .fontColor(this.active ? Color.White : $r('app.color.text_secondary'))
      .onClick(() => {
        this.onTap();
      })
  }
}

/** 数字缩写：1200 -> 1.2k */
export function compactCount(n: number): string {
  if (n >= 10000) {
    return `${(n / 10000).toFixed(1)}w`;
  }
  if (n >= 1000) {
    return `${(n / 1000).toFixed(1)}k`;
  }
  return `${n}`;
}

/** 热度缩写：13738880 -> 1373.9万 */
export function formatHeat(n: number): string {
  if (n >= 100000000) {
    return `${(n / 100000000).toFixed(1)}亿`;
  }
  if (n >= 10000) {
    return `${(n / 10000).toFixed(1)}万`;
  }
  return `${n}`;
}
