import { DeviceInfo, DeviceType } from '../../../../shared/src/main/ets/model/DeviceModel';

/**
 * 设备列表项组件
 */
@Component
export struct DeviceItem {
  @Prop device: DeviceInfo;
  @Prop onSelect?: (device: DeviceInfo) => void;

  build() {
    Row() {
      // 设备图标
      this.renderDeviceIcon()
      
      // 设备信息
      Column() {
        Text(this.device.deviceName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        
        Text(`${this.getDeviceTypeName(this.device.deviceType)} · ${this.device.isOnline ? '在线' : '离线'}`)
          .fontSize(12)
          .fontColor(this.device.isOnline ? '#4CAF50' : '#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 状态指示器和电池信息
      Column() {
        // 在线状态指示器
        Circle()
          .width(8)
          .height(8)
          .fill(this.device.isOnline ? '#4CAF50' : '#999999')
        
        // 电池信息
        if (this.device.batteryLevel !== undefined) {
          Text(`${this.device.batteryLevel}%`)
            .fontSize(10)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 8 })
    .onClick(() => {
      if (this.onSelect) {
        this.onSelect(this.device);
      }
    })
  }

  /**
   * 渲染设备类型图标
   */
  @Builder
  renderDeviceIcon() {
    Row() {
      switch (this.device.deviceType) {
        case DeviceType.PHONE:
          Text('📱')
            .fontSize(24)
          break;
        case DeviceType.CAR:
          Text('🚗')
            .fontSize(24)
          break;
        case DeviceType.WATCH:
          Text('⌚')
            .fontSize(24)
          break;
        default:
          Text('📱')
            .fontSize(24)
      }
    }
    .width(40)
    .height(40)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F5F5')
    .borderRadius(20)
    .margin({ right: 12 })
  }

  /**
   * 获取设备类型名称
   */
  private getDeviceTypeName(type: DeviceType): string {
    switch (type) {
      case DeviceType.PHONE: return '手机';
      case DeviceType.CAR: return '车机';
      case DeviceType.WATCH: return '手表';
      default: return '未知设备';
    }
  }
}