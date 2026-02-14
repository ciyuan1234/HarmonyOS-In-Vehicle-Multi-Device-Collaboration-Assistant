import { DeviceInfo, DeviceType, ControlCommand } from '../../../../shared/src/main/ets/model/DeviceModel';

/**
 * 快捷操作卡片组件
 */
@Component
export struct QuickActionCard {
  @Prop title: string;
  @Prop icon: string;
  @Prop backgroundColor: string;
  @Prop targetDevice?: DeviceInfo;
  @Prop command?: ControlCommand;
  @Prop onAction?: (command: ControlCommand, device?: DeviceInfo) => void;

  build() {
    Column() {
      // 图标
      Text(this.icon)
        .fontSize(28)
      
      // 标题
      Text(this.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .margin({ top: 8 })
      
      // 目标设备信息
      if (this.targetDevice) {
        Text(this.targetDevice.deviceName)
          .fontSize(12)
          .fontColor('#EEEEEE')
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .height(100)
    .backgroundColor(this.backgroundColor)
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.onAction && this.command) {
        this.onAction(this.command, this.targetDevice);
      }
    })
    .shadow({ radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 })
  }
}