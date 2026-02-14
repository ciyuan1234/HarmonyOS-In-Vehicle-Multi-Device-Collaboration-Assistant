import { VehicleStatus, ControlCommand } from '../../../../shared/src/main/ets/model/DeviceModel';
import { formatSpeed, formatFuelLevel, formatTemperature } from '../../../../shared/src/main/ets/utils/CommonUtils';

/**
 * 车辆控制面板组件
 */
@Component
export struct VehicleControlPanel {
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
  
  @Prop onSendCommand?: (command: ControlCommand, params?: any) => void;

  build() {
    Column() {
      // 车辆状态概览
      this.renderStatusOverview()
      
      // 控制按钮区域
      this.renderControlButtons()
      
      // 详细信息区域
      this.renderDetailedInfo()
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding(16)
    .shadow({ radius: 6, color: '#00000010', offsetX: 0, offsetY: 2 })
  }

  /**
   * 渲染状态概览
   */
  @Builder
  renderStatusOverview() {
    Row() {
      // 车辆图标和基本信息
      Column() {
        Text('🚗')
          .fontSize(32)
        
        Text('我的爱车')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ right: 16 })
      
      // 状态指标
      Column() {
        Row() {
          this.renderStatusIndicator('车速', formatSpeed(this.vehicleStatus.speed), '#2196F3')
          this.renderStatusIndicator('燃油', formatFuelLevel(this.vehicleStatus.fuelLevel), '#FF9800')
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .margin({ bottom: 8 })
        
        Row() {
          this.renderStatusIndicator('温度', formatTemperature(this.vehicleStatus.temperature), '#4CAF50')
          this.renderStatusIndicator('状态', this.vehicleStatus.engineStatus ? '运行中' : '已熄火', 
            this.vehicleStatus.engineStatus ? '#F44336' : '#9E9E9E')
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  /**
   * 渲染状态指标
   */
  @Builder
  renderStatusIndicator(label: string, value: string, color: string) {
    Column() {
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 渲染控制按钮区域
   */
  @Builder
  renderControlButtons() {
    Grid() {
      // 启动/停止发动机
      GridItem() {
        this.renderControlButton(
          this.vehicleStatus.engineStatus ? '⏹️' : '▶️',
          this.vehicleStatus.engineStatus ? '停止' : '启动',
          this.vehicleStatus.engineStatus ? '#F44336' : '#4CAF50',
          () => this.handleEngineToggle()
        )
      }
      
      // 锁车/解锁
      GridItem() {
        this.renderControlButton(
          this.vehicleStatus.doorLocked ? '🔓' : '🔒',
          this.vehicleStatus.doorLocked ? '解锁' : '锁车',
          this.vehicleStatus.doorLocked ? '#4CAF50' : '#FF9800',
          () => this.handleDoorToggle()
        )
      }
      
      // 空调控制
      GridItem() {
        this.renderControlButton(
          '❄️',
          '空调',
          '#2196F3',
          () => this.handleAcControl()
        )
      }
      
      // 导航
      GridItem() {
        this.renderControlButton(
          '🧭',
          '导航',
          '#9C27B0',
          () => this.handleNavigation()
        )
      }
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(12)
    .rowsGap(12)
    .margin({ bottom: 20 })
  }

  /**
   * 渲染控制按钮
   */
  @Builder
  renderControlButton(icon: string, label: string, bgColor: string, onClick: () => void) {
    Column() {
      Text(icon)
        .fontSize(24)
      
      Text(label)
        .fontSize(12)
        .fontColor('#333333')
        .margin({ top: 4 })
    }
    .width('100%')
    .height(80)
    .backgroundColor(bgColor)
    .borderRadius(8)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (onClick) onClick();
    })
  }

  /**
   * 渲染详细信息
   */
  @Builder
  renderDetailedInfo() {
    Column() {
      Text('详细信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 12 })
      
      // 位置信息
      Row() {
        Text('📍 位置:')
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
        
        Text(`${this.vehicleStatus.latitude.toFixed(6)}, ${this.vehicleStatus.longitude.toFixed(6)}`)
          .fontSize(14)
          .fontColor('#333333')
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      // 更新时间
      Row() {
        Text('🕒 更新时间:')
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
        
        Text(new Date(this.vehicleStatus.updateTime).toLocaleTimeString())
          .fontSize(14)
          .fontColor('#333333')
      }
      .width('100%')
    }
    .width('100%')
  }

  /**
   * 处理发动机开关
   */
  private handleEngineToggle(): void {
    const command = this.vehicleStatus.engineStatus ? 
      ControlCommand.STOP_ENGINE : ControlCommand.START_ENGINE;
    if (this.onSendCommand) {
      this.onSendCommand(command);
    }
  }

  /**
   * 处理车门锁控制
   */
  private handleDoorToggle(): void {
    const command = this.vehicleStatus.doorLocked ? 
      ControlCommand.UNLOCK_DOOR : ControlCommand.LOCK_DOOR;
    if (this.onSendCommand) {
      this.onSendCommand(command);
    }
  }

  /**
   * 处理空调控制
   */
  private handleAcControl(): void {
    // 这里可以打开空调设置弹窗
    if (this.onSendCommand) {
      this.onSendCommand(ControlCommand.OPEN_AC);
    }
  }

  /**
   * 处理导航
   */
  private handleNavigation(): void {
    // 这里可以打开导航设置
    if (this.onSendCommand) {
      this.onSendCommand(ControlCommand.NAVIGATE_TO, {
        destination: '公司'
      });
    }
  }

  /**
   * 更新车辆状态
   */
  updateStatus(status: VehicleStatus): void {
    this.vehicleStatus = { ...status };
  }
}