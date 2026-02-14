/**
 * 车辆仪表盘组件
 * 
 * 功能描述：
 * 1. 实时显示车辆核心数据（油量、胎压、车速）
 * 2. 数据来自VehicleDataSimulator
 * 3. 支持数据订阅更新
 * 
 * @author 车载多设备协同助手项目组
 */

import { VehicleData } from '../utils/VehicleDataSimulator';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export struct DashboardPanel {
  @State vehicleData: VehicleData = {
    fuelLevel: 85,
    tirePressure: 2.35,
    speed: 60,
    engineStatus: true,
    updateTime: Date.now()
  };
  
  private readonly TAG: string = 'DashboardPanel';
  
  build() {
    Column() {
      // 面板标题
      Text('🚗 车辆仪表盘')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width('100%')
        .padding({ bottom: 20 })
      
      // 核心数据显示区
      Row() {
        // 车速显示
        this.renderSpeedGauge()
        
        // 油量和胎压显示
        Column() {
          this.renderFuelIndicator()
          this.renderTirePressureIndicator()
        }
        .layoutWeight(1)
        .padding({ left: 20 })
      }
      .width('100%')
      .padding({ bottom: 20 })
      
      // 详细数据列表
      Column() {
        this.renderDataItem('发动机状态', 
                          this.vehicleData.engineStatus ? '运行中' : '已停止',
                          this.vehicleData.engineStatus ? '#4CAF50' : '#F44336')
        
        this.renderDataItem('最后更新', 
                          new Date(this.vehicleData.updateTime).toLocaleTimeString(),
                          '#AAAAAA')
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor('#1E1E1E')
    .borderRadius(16)
    .padding(20)
  }
  
  /**
   * 渲染车速表
   */
  @Builder
  private renderSpeedGauge() {
    Column() {
      // 车速数字
      Text(`${this.vehicleData.speed}`)
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getSpeedColor())
        .margin({ bottom: 8 })
      
      // 单位和标签
      Text('km/h')
        .fontSize(16)
        .fontColor('#AAAAAA')
        .margin({ bottom: 20 })
      
      // 速度等级指示
      Row() {
        Text('低速')
          .fontSize(12)
          .fontColor('#4CAF50')
        
        Blank()
        
        Text('中速')
          .fontSize(12)
          .fontColor('#FFC107')
        
        Blank()
        
        Text('高速')
          .fontSize(12)
          .fontColor('#F44336')
      }
      .width('100%')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
  
  /**
   * 渲染油量指示器
   */
  @Builder
  private renderFuelIndicator() {
    Row() {
      Column() {
        // 油量图标
        Text('⛽')
          .fontSize(24)
          .margin({ bottom: 8 })
        
        // 油量百分比
        Text(`${this.vehicleData.fuelLevel.toFixed(1)}%`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getFuelColor())
          .margin({ bottom: 4 })
        
        // 油量状态文字
        Text(this.getFuelStatusText())
          .fontSize(12)
          .fontColor('#AAAAAA')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      
      // 油量进度条
      Column() {
        ProgressBar({ value: this.vehicleData.fuelLevel, total: 100 })
          .width(8)
          .height(60)
          .color(this.getFuelColor())
          .backgroundColor('#333333')
          .layoutWeight(1)
      }
      .width(20)
      .height(80)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding({ bottom: 20 })
  }
  
  /**
   * 渲染胎压指示器
   */
  @Builder
  private renderTirePressureIndicator() {
    Row() {
      Column() {
        // 胎压图标
        Text('🛞')
          .fontSize(24)
          .margin({ bottom: 8 })
        
        // 胎压数值
        Text(`${this.vehicleData.tirePressure.toFixed(2)}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTirePressureColor())
          .margin({ bottom: 4 })
        
        // 胎压单位和状态
        Text('bar')
          .fontSize(12)
          .fontColor('#AAAAAA')
          .margin({ bottom: 2 })
        
        Text(this.getTirePressureStatus())
          .fontSize(10)
          .fontColor(this.getTirePressureColor())
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      
      // 胎压状态指示
      Column() {
        ForEach([2.5, 2.4, 2.3, 2.2], (threshold: number) => {
          Circle()
            .width(8)
            .height(8)
            .fill(this.vehicleData.tirePressure >= threshold ? 
                  this.getTirePressureColor() : '#333333')
            .margin({ bottom: 4 })
        })
      }
      .width(20)
      .height(80)
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%')
  }
  
  /**
   * 渲染数据项
   */
  @Builder
  private renderDataItem(label: string, value: string, color: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#AAAAAA')
        .layoutWeight(1)
      
      Text(value)
        .fontSize(14)
        .fontColor(color)
    }
    .width('100%')
    .padding({ vertical: 8 })
  }
  
  /**
   * 根据车速获取颜色
   */
  private getSpeedColor(): string {
    if (this.vehicleData.speed < 60) {
      return '#4CAF50'; // 绿色 - 低速
    } else if (this.vehicleData.speed < 100) {
      return '#FFC107'; // 黄色 - 中速
    } else {
      return '#F44336'; // 红色 - 高速
    }
  }
  
  /**
   * 根据油量获取颜色
   */
  private getFuelColor(): string {
    if (this.vehicleData.fuelLevel > 50) {
      return '#4CAF50'; // 绿色 - 充足
    } else if (this.vehicleData.fuelLevel > 20) {
      return '#FFC107'; // 黄色 - 一般
    } else {
      return '#F44336'; // 红色 - 不足
    }
  }
  
  /**
   * 获取油量状态文字
   */
  private getFuelStatusText(): string {
    if (this.vehicleData.fuelLevel > 50) {
      return '充足';
    } else if (this.vehicleData.fuelLevel > 20) {
      return '一般';
    } else {
      return '不足';
    }
  }
  
  /**
   * 根据胎压获取颜色
   */
  private getTirePressureColor(): string {
    if (this.vehicleData.tirePressure >= 2.2 && this.vehicleData.tirePressure <= 2.5) {
      return '#4CAF50'; // 绿色 - 正常
    } else if (this.vehicleData.tirePressure >= 2.0 && this.vehicleData.tirePressure <= 2.7) {
      return '#FFC107'; // 黄色 - 警告
    } else {
      return '#F44336'; // 红色 - 危险
    }
  }
  
  /**
   * 获取胎压状态描述
   */
  private getTirePressureStatus(): string {
    if (this.vehicleData.tirePressure >= 2.2 && this.vehicleData.tirePressure <= 2.5) {
      return '正常';
    } else if (this.vehicleData.tirePressure < 2.2) {
      return '偏低';
    } else {
      return '偏高';
    }
  }
  
  /**
   * 更新车辆数据
   */
  updateVehicleData(data: VehicleData): void {
    this.vehicleData = { ...data };
    hilog.debug(0x0000, this.TAG, 'Dashboard updated with new vehicle data');
  }
}