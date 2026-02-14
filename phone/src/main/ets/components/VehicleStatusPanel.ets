/**
 * 车辆状态面板组件
 * 
 * 功能描述：
 * 1. 实时显示车机端同步的车辆状态
 * 2. 油量、胎压、车速等核心数据展示
 * 3. 1秒刷新频率更新数据
 * 
 * @author 车载多设备协同助手项目组
 */

import { DistributedDataManager } from '../../../shared/src/main/ets/utils/DistributedDataManager';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export struct VehicleStatusPanel {
  // 车辆状态数据
  @State fuelLevel: number = 85;        // 油量百分比
  @State tirePressure: number = 2.35;   // 胎压 bar
  @State speed: number = 60;            // 车速 km/h
  @State lastUpdateTime: number = Date.now(); // 最后更新时间
  
  private dataManager: DistributedDataManager = DistributedDataManager.getInstance();
  private refreshTimer: number | null = null;
  private readonly TAG: string = 'VehicleStatusPanel';
  private readonly REFRESH_INTERVAL: number = 1000; // 1秒刷新
  
  aboutToAppear(): void {
    this.startDataRefresh();
  }
  
  aboutToDisappear(): void {
    this.stopDataRefresh();
  }
  
  build() {
    Column() {
      // 面板标题和刷新状态
      this.renderHeader()
      
      // 核心状态指标
      this.renderStatusIndicators()
      
      // 详细数据展示
      this.renderDetailedData()
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding(16)
    .shadow({ radius: 6, color: '#00000010', offsetX: 0, offsetY: 2 })
  }
  
  /**
   * 渲染面板头部
   */
  @Builder
  private renderHeader() {
    Row() {
      Column() {
        Text('📊 车辆状态')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        
        Text(`更新时间: ${new Date(this.lastUpdateTime).toLocaleTimeString()}`)
          .fontSize(10)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 刷新指示器
      LoadingProgress()
        .width(16)
        .height(16)
        .color('#2196F3')
    }
    .width('100%')
    .margin({ bottom: 16 })
  }
  
  /**
   * 渲染状态指标
   */
  @Builder
  private renderStatusIndicators() {
    Row() {
      // 油量指示器
      Column() {
        Stack() {
          // 背景圆环
          Circle()
            .width(80)
            .height(80)
            .strokeWidth(8)
            .stroke('#E0E0E0')
            .fill('#FFFFFF')
          
          // 进度圆环
          Circle()
            .width(80)
            .height(80)
            .strokeWidth(8)
            .stroke(this.getFuelColor())
            .fill('#FFFFFF')
            .strokeDashArray([Math.PI * 80 * (this.fuelLevel / 100), Math.PI * 80])
          
          // 油量文本
          Column() {
            Text(`${this.fuelLevel}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getFuelColor())
            
            Text('%')
              .fontSize(10)
              .fontColor('#999999')
          }
        }
        .width(90)
        .height(90)
        
        Text('油量')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      
      // 胎压指示器
      Column() {
        Stack() {
          // 背景圆环
          Circle()
            .width(80)
            .height(80)
            .strokeWidth(8)
            .stroke('#E0E0E0')
            .fill('#FFFFFF')
          
          // 进度圆环
          Circle()
            .width(80)
            .height(80)
            .strokeWidth(8)
            .stroke(this.getTirePressureColor())
            .fill('#FFFFFF')
            .strokeDashArray([
              Math.PI * 80 * ((this.tirePressure - 2.0) / 1.0), 
              Math.PI * 80
            ])
          
          // 胎压文本
          Column() {
            Text(`${this.tirePressure.toFixed(2)}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getTirePressureColor())
            
            Text('bar')
              .fontSize(10)
              .fontColor('#999999')
          }
        }
        .width(90)
        .height(90)
        
        Text('胎压')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      
      // 车速指示器
      Column() {
        Stack() {
          // 背景圆环
          Circle()
            .width(80)
            .height(80)
            .strokeWidth(8)
            .stroke('#E0E0E0')
            .fill('#FFFFFF')
          
          // 进度圆环
          Circle()
            .width(80)
            .height(80)
            .strokeWidth(8)
            .stroke(this.getSpeedColor())
            .fill('#FFFFFF')
            .strokeDashArray([Math.PI * 80 * (this.speed / 120), Math.PI * 80])
          
          // 车速文本
          Column() {
            Text(`${this.speed}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getSpeedColor())
            
            Text('km/h')
              .fontSize(10)
              .fontColor('#999999')
          }
        }
        .width(90)
        .height(90)
        
        Text('车速')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .margin({ bottom: 20 })
  }
  
  /**
   * 渲染详细数据
   */
  @Builder
  private renderDetailedData() {
    Column() {
      Text('详细信息')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
        .margin({ bottom: 12 })
        .selfAlign(ItemAlign.Start)
      
      // 数据行
      Column() {
        this.renderDataItem('油量状态', this.getFuelStatusText(), this.getFuelColor())
        this.renderDataItem('胎压状态', this.getTirePressureStatus(), this.getTirePressureColor())
        this.renderDataItem('行驶状态', this.getSpeedStatusText(), this.getSpeedColor())
        this.renderDataItem('数据延迟', this.getDataDelayText(), '#666666')
      }
      .width('100%')
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
        .fontSize(12)
        .fontColor('#666666')
        .layoutWeight(1)
      
      Text(value)
        .fontSize(12)
        .fontColor(color)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({ vertical: 6 })
  }
  
  /**
   * 开始数据刷新
   */
  private startDataRefresh(): void {
    // 注册数据变更监听
    this.dataManager.onDataChanged(this.handleDataUpdate);
    
    // 启动定时刷新
    this.refreshTimer = setInterval(() => {
      this.refreshVehicleData();
    }, this.REFRESH_INTERVAL);
    
    // 立即获取一次数据
    this.refreshVehicleData();
    
    hilog.info(0x0000, this.TAG, 'Vehicle data refresh started');
  }
  
  /**
   * 停止数据刷新
   */
  private stopDataRefresh(): void {
    // 移除数据监听
    this.dataManager.removeDataListener(this.handleDataUpdate);
    
    // 停止定时器
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = null;
    }
    
    hilog.info(0x0000, this.TAG, 'Vehicle data refresh stopped');
  }
  
  /**
   * 刷新车辆数据
   */
  private async refreshVehicleData(): Promise<void> {
    try {
      const data = await this.dataManager.readVehicleData();
      
      this.fuelLevel = data.fuelLevel || 85;
      this.tirePressure = data.tirePressure || 2.35;
      this.speed = data.speed || 60;
      this.lastUpdateTime = data.lastUpdateTime || Date.now();
      
      hilog.debug(0x0000, this.TAG, 'Vehicle data refreshed: fuel=%{public}d%%, speed=%{public}d', 
                 this.fuelLevel, this.speed);
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to refresh vehicle data: %{public}s', 
                 JSON.stringify(error));
    }
  }
  
  /**
   * 处理数据更新
   */
  private handleDataUpdate = (data: any): void => {
    this.fuelLevel = data.fuelLevel !== undefined ? data.fuelLevel : this.fuelLevel;
    this.tirePressure = data.tirePressure !== undefined ? data.tirePressure : this.tirePressure;
    this.speed = data.speed !== undefined ? data.speed : this.speed;
    this.lastUpdateTime = data.lastUpdateTime || Date.now();
    
    hilog.debug(0x0000, this.TAG, 'Vehicle data updated from remote');
  }
  
  /**
   * 获取油量颜色
   */
  private getFuelColor(): string {
    if (this.fuelLevel > 50) return '#4CAF50';  // 绿色 - 充足
    if (this.fuelLevel > 20) return '#FFC107';  // 黄色 - 一般
    return '#F44336';                           // 红色 - 不足
  }
  
  /**
   * 获取油量状态文字
   */
  private getFuelStatusText(): string {
    if (this.fuelLevel > 50) return '充足';
    if (this.fuelLevel > 20) return '一般';
    return '不足';
  }
  
  /**
   * 获取胎压颜色
   */
  private getTirePressureColor(): string {
    if (this.tirePressure >= 2.2 && this.tirePressure <= 2.5) return '#4CAF50'; // 正常
    if (this.tirePressure >= 2.0 && this.tirePressure <= 2.7) return '#FFC107'; // 警告
    return '#F44336';                                                           // 危险
  }
  
  /**
   * 获取胎压状态文字
   */
  private getTirePressureStatus(): string {
    if (this.tirePressure >= 2.2 && this.tirePressure <= 2.5) return '正常';
    if (this.tirePressure < 2.2) return '偏低';
    return '偏高';
  }
  
  /**
   * 获取车速颜色
   */
  private getSpeedColor(): string {
    if (this.speed < 60) return '#4CAF50';   // 绿色 - 低速
    if (this.speed < 100) return '#FFC107';  // 黄色 - 中速
    return '#F44336';                        // 红色 - 高速
  }
  
  /**
   * 获取车速状态文字
   */
  private getSpeedStatusText(): string {
    if (this.speed === 0) return '静止';
    if (this.speed < 60) return '低速行驶';
    if (this.speed < 100) return '中速行驶';
    return '高速行驶';
  }
  
  /**
   * 获取数据延迟文字
   */
  private getDataDelayText(): string {
    const delay = Date.now() - this.lastUpdateTime;
    if (delay < 2000) return '实时';
    if (delay < 5000) return '稍有延迟';
    return '延迟较大';
  }
}