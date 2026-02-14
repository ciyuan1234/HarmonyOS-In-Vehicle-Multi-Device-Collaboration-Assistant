/**
 * 手表端主页 - 车载多设备协同助手（简化版本）
 * 
 * 核心功能：
 * 1. 连接车机模拟器，同步车辆状态数据
 * 2. 快捷操作：一键寻车、空调控制、车门控制
 * 3. UI适配手表小屏
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

interface VehicleStatusData {
  fuelLevel: number;
  tirePressure: number;
  mileage: number;
  speed: number;
  engineStatus: boolean;
  acStatus: boolean;
  doorLocked: boolean;
  updateTime: number;
}

@Component
struct QuickActionButton {
  @Prop icon: string;
  @Prop label: string;
  @Prop backgroundColor: string;
  @Prop onPress: () => void;

  build() {
    Column() {
      Text(this.icon)
        .fontSize(28)
        .margin({ bottom: 4 })
      
      Text(this.label)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width(70)
    .height(70)
    .backgroundColor(this.backgroundColor)
    .borderRadius(35)
    .justifyContent(FlexAlign.Center)
    .onClick(this.onPress)
    .shadow({ radius: 6, color: '#00000040', offsetX: 0, offsetY: 3 })
  }
}

@Component
struct StatusCard {
  @Prop title: string;
  @Prop value: string;
  @Prop unit: string;
  @Prop icon: string;
  @Prop statusColor: string;

  build() {
    Column() {
      Row() {
        Text(this.icon)
          .fontSize(20)
          .margin({ right: 8 })
        
        Text(this.title)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      Row() {
        Text(this.value)
          .fontSize(24)
          .fontColor(this.statusColor)
          .fontWeight(FontWeight.Bold)
        
        Text(this.unit)
          .fontSize(12)
          .fontColor('#AAAAAA')
          .margin({ left: 4 })
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .backgroundColor('#1E1E1E')
    .borderRadius(12)
    .padding(12)
    .shadow({ radius: 4, color: '#00000030', offsetX: 0, offsetY: 2 })
  }
}

@Entry
@Component
struct WatchIndex {
  @State currentTime: string = '';
  @State currentDate: string = '';
  @State isConnected: boolean = false;
  @State isLoading: boolean = true;
  
  @State vehicleStatus: VehicleStatusData = {
    fuelLevel: 75,
    tirePressure: 2.3,
    mileage: 320,
    speed: 0,
    engineStatus: false,
    acStatus: false,
    doorLocked: true,
    updateTime: Date.now()
  };

  private clockTimer: number = -1;
  private statusTimer: number = -1;
  private readonly TAG: string = 'WatchIndex';

  aboutToAppear(): void {
    this.initializeApp();
    this.startClock();
    this.startStatusUpdates();
  }

  aboutToDisappear(): void {
    this.cleanup();
  }

  build() {
    Column() {
      if (this.isLoading) {
        this.renderLoadingView();
      } else {
        this.renderStatusBar();
        this.renderTimeDisplay();
        this.renderVehicleStatus();
        this.renderQuickActions();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .padding({ left: 16, right: 16, top: 20, bottom: 16 })
  }

  @Builder
  renderLoadingView() {
    Column() {
      Text('⌚')
        .fontSize(40)
        .margin({ bottom: 12 })
      
      Text('车载助手')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ bottom: 8 })
      
      Text('正在连接车机...')
        .fontSize(12)
        .fontColor('#AAAAAA')
      
      LoadingProgress()
        .width(24)
        .height(24)
        .color('#2196F3')
        .margin({ top: 16 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  renderStatusBar() {
    Row() {
      Circle()
        .width(8)
        .height(8)
        .fill(this.isConnected ? '#4CAF50' : '#F44336')
        .margin({ right: 8 })
      
      Text(this.isConnected ? '已连接' : '未连接')
        .fontSize(12)
        .fontColor(this.isConnected ? '#4CAF50' : '#F44336')
        .layoutWeight(1)
      
      Button('🔄')
        .width(28)
        .height(28)
        .fontSize(14)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')
        .borderRadius(14)
        .onClick(() => {
          this.refreshConnection();
        })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  @Builder
  renderTimeDisplay() {
    Column() {
      Text(this.currentTime)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ bottom: 4 })
      
      Text(this.currentDate)
        .fontSize(12)
        .fontColor('#AAAAAA')
    }
    .width('100%')
    .margin({ bottom: 20 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  renderVehicleStatus() {
    Column() {
      Row() {
        StatusCard({
          title: '油量',
          value: this.vehicleStatus.fuelLevel.toString(),
          unit: '%',
          icon: '⛽',
          statusColor: this.getFuelColor()
        })
        .layoutWeight(1)
        .margin({ right: 8 })
        
        StatusCard({
          title: '胎压',
          value: this.vehicleStatus.tirePressure.toFixed(1),
          unit: 'bar',
          icon: '🛞',
          statusColor: this.getTirePressureColor()
        })
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      Row() {
        StatusCard({
          title: '续航',
          value: this.vehicleStatus.mileage.toString(),
          unit: 'km',
          icon: '🔋',
          statusColor: '#4CAF50'
        })
        .layoutWeight(1)
        .margin({ right: 8 })
        
        StatusCard({
          title: '车速',
          value: this.vehicleStatus.speed.toString(),
          unit: 'km/h',
          icon: '🚀',
          statusColor: this.getSpeedColor()
        })
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 24 })
  }

  @Builder
  renderQuickActions() {
    Grid() {
      GridItem() {
        QuickActionButton({
          icon: '🔍',
          label: '寻车',
          backgroundColor: '#9C27B0',
          onPress: this.handleFindCar
        })
      }
      
      GridItem() {
        QuickActionButton({
          icon: this.vehicleStatus.acStatus ? '❄️' : '🧊',
          label: this.vehicleStatus.acStatus ? '关闭空调' : '开启空调',
          backgroundColor: this.vehicleStatus.acStatus ? '#2196F3' : '#607D8B',
          onPress: this.handleAcControl
        })
      }
      
      GridItem() {
        QuickActionButton({
          icon: this.vehicleStatus.doorLocked ? '🔒' : '🔓',
          label: this.vehicleStatus.doorLocked ? '解锁' : '上锁',
          backgroundColor: this.vehicleStatus.doorLocked ? '#4CAF50' : '#FF9800',
          onPress: this.handleDoorControl
        })
      }
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(12)
    .rowsGap(12)
  }

  private async initializeApp(): Promise<void> {
    try {
      this.isLoading = true;
      await new Promise(resolve => setTimeout(resolve, 2000));
      this.isConnected = true;
      this.isLoading = false;
      promptAction.showToast({ message: '车载助手已就绪' });
      hilog.info(0x0000, this.TAG, 'Watch app initialized successfully');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to initialize watch app');
    }
  }

  private startClock(): void {
    this.updateDateTime();
    this.clockTimer = setInterval(() => {
      this.updateDateTime();
    }, 1000);
  }

  private updateDateTime(): void {
    const now = new Date();
    this.currentTime = now.toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
    this.currentDate = now.toLocaleDateString([], {
      month: 'short',
      day: 'numeric',
      weekday: 'short'
    });
  }

  private startStatusUpdates(): void {
    this.statusTimer = setInterval(() => {
      if (this.isConnected) {
        this.simulateStatusUpdate();
      }
    }, 5000);
  }

  private simulateStatusUpdate(): void {
    this.vehicleStatus = {
      ...this.vehicleStatus,
      fuelLevel: Math.max(0, this.vehicleStatus.fuelLevel - Math.random() * 0.1),
      speed: this.vehicleStatus.engineStatus ? Math.floor(Math.random() * 80) : 0,
      updateTime: Date.now()
    };
  }

  private async refreshConnection(): Promise<void> {
    promptAction.showToast({ 
      message: this.isConnected ? '连接正常' : '未检测到车机设备' 
    });
  }

  // 核心跨端指令发送逻辑
  private async handleFindCar(): Promise<void> {
    if (!this.isConnected) {
      promptAction.showToast({ message: '未连接到车机设备' });
      return;
    }

    try {
      // 模拟发送寻车指令
      await new Promise(resolve => setTimeout(resolve, 500));
      promptAction.showToast({ message: '寻车指令已发送' });
      hilog.info(0x0000, this.TAG, 'Find car command sent to car device');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to send find car command');
      promptAction.showToast({ message: '发送失败，请重试' });
    }
  }

  private async handleAcControl(): Promise<void> {
    if (!this.isConnected) {
      promptAction.showToast({ message: '未连接到车机设备' });
      return;
    }

    try {
      const newAcStatus = !this.vehicleStatus.acStatus;
      this.vehicleStatus.acStatus = newAcStatus;
      
      const message = newAcStatus ? '空调已开启 (25°C)' : '空调已关闭';
      promptAction.showToast({ message: message });
      hilog.info(0x0000, this.TAG, 'AC control command sent');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to send AC control command');
      promptAction.showToast({ message: '操作失败，请重试' });
    }
  }

  private async handleDoorControl(): Promise<void> {
    if (!this.isConnected) {
      promptAction.showToast({ message: '未连接到车机设备' });
      return;
    }

    try {
      const newDoorStatus = !this.vehicleStatus.doorLocked;
      this.vehicleStatus.doorLocked = newDoorStatus;
      
      const message = newDoorStatus ? '车门已上锁' : '车门已解锁';
      promptAction.showToast({ message: message });
      hilog.info(0x0000, this.TAG, 'Door control command sent');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to send door control command');
      promptAction.showToast({ message: '操作失败，请重试' });
    }
  }

  private getFuelColor(): string {
    if (this.vehicleStatus.fuelLevel > 50) return '#4CAF50';
    if (this.vehicleStatus.fuelLevel > 20) return '#FFC107';
    return '#F44336';
  }

  private getTirePressureColor(): string {
    const pressure = this.vehicleStatus.tirePressure;
    if (pressure >= 2.2 && pressure <= 2.5) return '#4CAF50';
    if (pressure >= 1.8 && pressure <= 2.8) return '#FFC107';
    return '#F44336';
  }

  private getSpeedColor(): string {
    if (this.vehicleStatus.speed === 0) return '#AAAAAA';
    if (this.vehicleStatus.speed < 60) return '#4CAF50';
    if (this.vehicleStatus.speed < 100) return '#FFC107';
    return '#F44336';
  }

  private cleanup(): void {
    if (this.clockTimer !== -1) {
      clearInterval(this.clockTimer);
      this.clockTimer = -1;
    }
    
    if (this.statusTimer !== -1) {
      clearInterval(this.statusTimer);
      this.statusTimer = -1;
    }
    
    hilog.info(0x0000, this.TAG, 'Watch app cleaned up');
  }
}