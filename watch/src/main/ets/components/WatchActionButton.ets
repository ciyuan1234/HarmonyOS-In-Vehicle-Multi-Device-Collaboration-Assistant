import { ControlCommand } from '../../../../shared/src/main/ets/model/DeviceModel';

/**
 * 手表快捷操作按钮组件
 */
@Component
export struct WatchActionButton {
  @Prop icon: string;
  @Prop label: string;
  @Prop backgroundColor: string;
  @Prop command: ControlCommand;
  @Prop onPress?: (command: ControlCommand) => void;

  build() {
    Column() {
      // 图标
      Text(this.icon)
        .fontSize(24)
      
      // 标签
      Text(this.label)
        .fontSize(10)
        .fontColor('#FFFFFF')
        .margin({ top: 4 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(60)
    .height(60)
    .backgroundColor(this.backgroundColor)
    .borderRadius(30)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.onPress) {
        this.onPress(this.command);
      }
    })
    .shadow({ radius: 4, color: '#00000030', offsetX: 0, offsetY: 2 })
  }
}