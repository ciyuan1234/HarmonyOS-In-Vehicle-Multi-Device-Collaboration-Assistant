import { VehicleStatus } from '../../../../shared/src/main/ets/model/DeviceModel';
import { formatSpeed, formatFuelLevel, formatTemperature } from '../../../../shared/src/main/ets/utils/CommonUtils';

/**
 * 手表车辆状态概览组件
 */
@Component
export struct WatchVehicleStatus {
  @State vehicleStatus: VehicleStatus = {
    speed: 0,
    engineStatus: false,
    fuelLevel: 80,
    temperature: 22,
    doorLocked: true,
    latitude: 39.9042,
    longitude: 116.4074,
    updateTime: Date.now()
  };

  build() {
    Column() {
      // 标题
      Text('车辆状态')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .margin({ bottom: 8 })
      
      // 状态指标
      Grid() {
        GridItem() {
          this.renderStatusItem('🚀', '车速', formatSpeed(this.vehicleStatus.speed))
        }
        
        GridItem() {
          this.renderStatusItem(
            this.vehicleStatus.engineStatus ? '🟢' : '🔴',
            '发动机',
            this.vehicleStatus.engineStatus ? '运行' : '停止'
          )
        }
        
        GridItem() {
          this.renderStatusItem('⛽', '燃油', formatFuelLevel(this.vehicleStatus.fuelLevel))
        }
        
        GridItem() {
          this.renderStatusItem('🌡️', '温度', formatTemperature(this.vehicleStatus.temperature))
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
    }
    .width('100%')
    .backgroundColor('#000000')
    .borderRadius(12)
    .padding(12)
  }

  /**
   * 渲染状态项
   */
  @Builder
  renderStatusItem(icon: string, label: string, value: string) {
    Column() {
      Text(icon)
        .fontSize(16)
        .margin({ bottom: 2 })
      
      Text(value)
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ bottom: 2 })
      
      Text(label)
        .fontSize(8)
        .fontColor('#AAAAAA')
    }
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 更新车辆状态
   */
  updateStatus(status: VehicleStatus): void {
    this.vehicleStatus = { ...status };
  }
}