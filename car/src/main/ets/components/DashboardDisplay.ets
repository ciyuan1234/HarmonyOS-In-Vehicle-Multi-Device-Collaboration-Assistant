import { VehicleStatus } from '../../../../shared/src/main/ets/model/DeviceModel';
import { formatSpeed, formatFuelLevel, formatTemperature } from '../../../../shared/src/main/ets/utils/CommonUtils';

/**
 * 车辆仪表盘组件
 * 显示核心驾驶信息
 */
@Component
export struct DashboardDisplay {
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
      // 速度表
      this.renderSpeedometer()
      
      // 状态指示器
      this.renderStatusIndicators()
      
      // 辅助信息
      this.renderAuxiliaryInfo()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .padding(20)
  }

  /**
   * 渲染速度表
   */
  @Builder
  renderSpeedometer() {
    Stack() {
      // 外圈
      Circle()
        .width(200)
        .height(200)
        .strokeWidth(8)
        .stroke(Color.Gray)
        .fill('#00000000')
      
      // 进度弧
      Circle()
        .width(200)
        .height(200)
        .strokeWidth(8)
        .stroke(this.getSpeedColor())
        .fill('#00000000')
        .strokeDashArray([Math.PI * 200 * (this.vehicleStatus.speed / 120), Math.PI * 200])
        .strokeDashOffset(0)
      
      // 速度数字
      Column() {
        Text(formatSpeed(this.vehicleStatus.speed))
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        
        Text('km/h')
          .fontSize(16)
          .fontColor('#AAAAAA')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width(220)
    .height(220)
    .margin({ bottom: 30 })
  }

  /**
   * 渲染状态指示器
   */
  @Builder
  renderStatusIndicators() {
    Row() {
      // 发动机状态
      this.renderIndicator(
        this.vehicleStatus.engineStatus ? '🟢' : '🔴',
        '发动机',
        this.vehicleStatus.engineStatus ? '运行中' : '已停止'
      )
      
      // 车门状态
      this.renderIndicator(
        this.vehicleStatus.doorLocked ? '🔒' : '🔓',
        '车门',
        this.vehicleStatus.doorLocked ? '已锁定' : '未锁定'
      )
      
      // 燃油状态
      this.renderIndicator(
        '⛽',
        '燃油',
        formatFuelLevel(this.vehicleStatus.fuelLevel)
      )
      
      // 温度状态
      this.renderIndicator(
        '🌡️',
        '温度',
        formatTemperature(this.vehicleStatus.temperature)
      )
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .margin({ bottom: 30 })
  }

  /**
   * 渲染单个指示器
   */
  @Builder
  renderIndicator(icon: string, label: string, value: string) {
    Column() {
      Text(icon)
        .fontSize(24)
        .margin({ bottom: 8 })
      
      Text(label)
        .fontSize(12)
        .fontColor('#AAAAAA')
        .margin({ bottom: 4 })
      
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
    }
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 渲染辅助信息
   */
  @Builder
  renderAuxiliaryInfo() {
    Row() {
      // GPS状态
      Row() {
        Text('📍')
          .fontSize(16)
          .margin({ right: 4 })
        
        Text('GPS定位')
          .fontSize(12)
          .fontColor('#AAAAAA')
      }
      .layoutWeight(1)
      
      // 时间显示
      Text(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
    }
    .width('100%')
  }

  /**
   * 根据速度获取颜色
   */
  private getSpeedColor(): Color {
    if (this.vehicleStatus.speed < 60) {
      return Color.Green;
    } else if (this.vehicleStatus.speed < 100) {
      return Color.Yellow;
    } else {
      return Color.Red;
    }
  }

  /**
   * 更新车辆状态
   */
  updateStatus(status: VehicleStatus): void {
    this.vehicleStatus = { ...status };
  }
}