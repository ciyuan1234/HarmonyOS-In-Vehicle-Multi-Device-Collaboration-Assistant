/**
 * 手表端主页 - 车载多设备协同助手
 * 
 * 核心功能：
 * 1. 连接车机模拟器，同步车辆状态数据（油量、胎压、续航里程）
 * 2. 快捷操作：一键寻车、空调控制、车门控制
 * 3. UI适配手表小屏：卡片式布局，大按钮易点击，数据展示简洁
 * 
 * @author 车载多设备协同助手项目组
 * @since 2024
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DistributedDataManager } from '../../../shared/src/main/ets/utils/DistributedDataManager';
import { DeviceDiscoveryManager } from '../../../shared/src/main/ets/utils/DeviceDiscoveryManager';

interface VehicleStatusData {
  fuelLevel: number;        // 油量百分比 (0-100)
  tirePressure: number;     // 胎压 (bar)
  mileage: number;          // 续航里程 (km)
  speed: number;            // 车速 (km/h)
  engineStatus: boolean;    // 发动机状态
  acStatus: boolean;        // 空调状态
  doorLocked: boolean;      // 车门锁定状态
  updateTime: number;       // 更新时间戳
}

@Component
struct QuickActionButton {
  @Prop icon: string;
  @Prop label: string;
  @Prop backgroundColor: string;
  @Prop onPress: () => void;

  build() {
    Column() {
      // 图标
      Text(this.icon)
        .fontSize(28)
        .margin({ bottom: 4 })
      
      // 标签
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
    .transition({ type: TransitionType.All, duration: 200 })
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
  // 状态管理
  @State currentTime: string = '';
  @State currentDate: string = '';
  @State isConnected: boolean = false;
  @State isLoading: boolean = true;
  
  // 车辆状态数据
  @State vehicleStatus: VehicleStatusData = {
    fuelLevel: 0,
    tirePressure: 0,
    mileage: 0,
    speed: 0,
    engineStatus: false,
    acStatus: false,
    doorLocked: true,
    updateTime: 0
  };
  
  // 工具类实例
  private dataManager: DistributedDataManager = DistributedDataManager.getInstance();
  private discoveryManager: DeviceDiscoveryManager = DeviceDiscoveryManager.getInstance();
  
  // 定时器
  private clockTimer: number = -1;
  private statusTimer: number = -1;
  
  // 设备ID
  private readonly DEVICE_ID: string = 'watch_device_' + Date.now().toString();
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
        // 顶部状态栏
        this.renderStatusBar();
        
        // 时间显示
        this.renderTimeDisplay();
        
        // 车辆状态卡片
        this.renderVehicleStatus();
        
        // 快捷操作按钮
        this.renderQuickActions();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .padding({ left: 16, right: 16, top: 20, bottom: 16 })
  }

  /**
   * 渲染加载视图
   */
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

  /**
   * 渲染状态栏
   */
  @Builder
  renderStatusBar() {
    Row() {
      // 连接状态指示器
      Circle()
        .width(8)
        .height(8)
        .fill(this.isConnected ? '#4CAF50' : '#F44336')
        .margin({ right: 8 })
      
      Text(this.isConnected ? '已连接' : '未连接')
        .fontSize(12)
        .fontColor(this.isConnected ? '#4CAF50' : '#F44336')
        .layoutWeight(1)
      
      // 刷新按钮
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

  /**
   * 渲染时间显示
   */
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

  /**
   * 渲染车辆状态卡片
   */
  @Builder
  renderVehicleStatus() {
    Column() {
      // 第一行：油量和胎压
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
      
      // 第二行：续航里程和车速
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

  /**
   * 渲染快捷操作按钮
   */
  @Builder
  renderQuickActions() {
    Grid() {
      // 一键寻车
      GridItem() {
        QuickActionButton({
          icon: '🔍',
          label: '寻车',
          backgroundColor: '#9C27B0',
          onPress: this.handleFindCar
        })
      }
      
      // 空调控制
      GridItem() {
        QuickActionButton({
          icon: this.vehicleStatus.acStatus ? '❄️' : '🧊',
          label: this.vehicleStatus.acStatus ? '关闭空调' : '开启空调',
          backgroundColor: this.vehicleStatus.acStatus ? '#2196F3' : '#607D8B',
          onPress: this.handleAcControl
        })
      }
      
      // 车门控制
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

  /**
   * 初始化应用程序
   */
  private async initializeApp(): Promise<void> {
    try {
      this.isLoading = true;
      
      // 初始化分布式数据管理器
      const dataSuccess = await this.dataManager.init(this.DEVICE_ID);
      
      // 初始化设备发现管理器
      const discoverySuccess = await this.discoveryManager.init('com.example.wanwuhulian');
      
      if (dataSuccess && discoverySuccess) {
        // 设置数据变更监听
        this.setupDataListeners();
        
        // 检查车机连接状态
        this.checkCarConnection();
        
        // 获取初始车辆状态
        await this.refreshVehicleStatus();
        
        hilog.info(0x0000, this.TAG, 'Watch app initialized successfully');
        promptAction.showToast({ message: '车载助手已就绪' });
      } else {
        throw new Error('Failed to initialize managers');
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to initialize watch app: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '初始化失败，请重试' });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 设置数据监听器
   */
  private setupDataListeners(): void {
    // 车辆数据变更监听
    this.dataManager.onDataChanged((data: any) => {
      this.handleVehicleDataUpdate(data);
    });
    
    // 连接状态变更监听
    this.dataManager.onConnectionStatusChanged((status: string) => {
      this.isConnected = status === 'connected';
      hilog.info(0x0000, this.TAG, 'Connection status changed: %{public}s', status);
    });
  }

  /**
   * 检查车机连接状态
   */
  private checkCarConnection(): void {
    // 检查是否存在车机设备
    const carDevices = this.discoveryManager.getDevicesByType('car');
    this.isConnected = carDevices.length > 0;
  }

  /**
   * 刷新车辆状态
   */
  private async refreshVehicleStatus(): Promise<void> {
    try {
      const data = await this.dataManager.readVehicleData();
      if (data) {
        this.vehicleStatus = {
          fuelLevel: data.fuelLevel || 0,
          tirePressure: data.tirePressure || 0,
          mileage: data.mileage || 0,
          speed: data.speed || 0,
          engineStatus: data.engineStatus || false,
          acStatus: data.acStatus || false,
          doorLocked: data.doorLocked !== undefined ? data.doorLocked : true,
          updateTime: data.lastUpdateTime || Date.now()
        };
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to refresh vehicle status: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 处理车辆数据更新
   */
  private handleVehicleDataUpdate(data: any): void {
    this.vehicleStatus = {
      fuelLevel: data.fuelLevel !== undefined ? data.fuelLevel : this.vehicleStatus.fuelLevel,
      tirePressure: data.tirePressure !== undefined ? data.tirePressure : this.vehicleStatus.tirePressure,
      mileage: data.mileage !== undefined ? data.mileage : this.vehicleStatus.mileage,
      speed: data.speed !== undefined ? data.speed : this.vehicleStatus.speed,
      engineStatus: data.engineStatus !== undefined ? data.engineStatus : this.vehicleStatus.engineStatus,
      acStatus: data.acStatus !== undefined ? data.acStatus : this.vehicleStatus.acStatus,
      doorLocked: data.doorLocked !== undefined ? data.doorLocked : this.vehicleStatus.doorLocked,
      updateTime: data.lastUpdateTime || Date.now()
    };
    
    hilog.debug(0x0000, this.TAG, 'Vehicle data updated from distributed storage');
  }

  /**
   * 启动时钟
   */
  private startClock(): void {
    this.updateDateTime();
    this.clockTimer = setInterval(() => {
      this.updateDateTime();
    }, 1000);
  }

  /**
   * 更新日期时间显示
   */
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

  /**
   * 启动状态更新定时器
   */
  private startStatusUpdates(): void {
    this.statusTimer = setInterval(async () => {
      if (this.isConnected) {
        await this.refreshVehicleStatus();
      }
    }, 3000); // 每3秒更新一次
  }

  /**
   * 刷新连接状态
   */
  private async refreshConnection(): Promise<void> {
    try {
      // 重新检查连接
      this.checkCarConnection();
      
      // 刷新车辆状态
      await this.refreshVehicleStatus();
      
      promptAction.showToast({ 
        message: this.isConnected ? '连接正常' : '未检测到车机设备' 
      });
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to refresh connection: %{public}s', JSON.stringify(error));
    }
  }

  // ==================== 核心跨端指令发送逻辑 ====================
  
  /**
   * 处理一键寻车指令 - 核心跨端通信逻辑
   * 通过分布式存储向车机端发送寻车指令
   */
  private async handleFindCar(): Promise<void> {
    if (!this.isConnected) {
      promptAction.showToast({ message: '未连接到车机设备' });
      return;
    }

    try {
      // 核心代码逻辑：通过分布式数据管理器发送寻车指令
      const success = await this.dataManager.storeVehicleData({
        findCarCommand: true,        // 寻车指令标志
        commandTimestamp: Date.now(), // 指令时间戳
        sourceDevice: this.DEVICE_ID  // 指令来源设备
      });

      if (success) {
        // 视觉反馈
        promptAction.showToast({ message: '寻车指令已发送' });
        hilog.info(0x0000, this.TAG, 'Find car command sent to car device via distributed storage');
        
        // 可以添加震动反馈
        // vibrator.vibrate({ type: 'short' });
      } else {
        throw new Error('Failed to send find car command');
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to send find car command: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '发送失败，请重试' });
    }
  }

  /**
   * 处理空调控制指令 - 核心跨端通信逻辑
   * 一键开启/关闭空调，默认温度25°C
   */
  private async handleAcControl(): Promise<void> {
    if (!this.isConnected) {
      promptAction.showToast({ message: '未连接到车机设备' });
      return;
    }

    try {
      const newAcStatus = !this.vehicleStatus.acStatus;
      const targetTemperature = 25; // 默认25°C
      
      // 核心代码逻辑：通过分布式存储发送空调控制指令
      const success = await this.dataManager.storeVehicleData({
        acStatus: newAcStatus,           // 空调开关状态
        acTemperature: targetTemperature, // 目标温度
        commandTimestamp: Date.now(),
        sourceDevice: this.DEVICE_ID
      });

      if (success) {
        // 更新本地状态
        this.vehicleStatus.acStatus = newAcStatus;
        
        const message = newAcStatus ? `空调已开启 (${targetTemperature}°C)` : '空调已关闭';
        promptAction.showToast({ message: message });
        hilog.info(0x0000, this.TAG, 'AC control command sent: %{public}s', newAcStatus ? 'ON' : 'OFF');
      } else {
        throw new Error('Failed to send AC control command');
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to send AC control command: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '操作失败，请重试' });
    }
  }

  /**
   * 处理车门控制指令 - 核心跨端通信逻辑
   * 一键解锁/上锁车门
   */
  private async handleDoorControl(): Promise<void> {
    if (!this.isConnected) {
      promptAction.showToast({ message: '未连接到车机设备' });
      return;
    }

    try {
      const newDoorStatus = !this.vehicleStatus.doorLocked;
      
      // 核心代码逻辑：通过分布式存储发送车门控制指令
      const success = await this.dataManager.storeVehicleData({
        doorLocked: newDoorStatus,       // 车门锁定状态
        commandTimestamp: Date.now(),
        sourceDevice: this.DEVICE_ID
      });

      if (success) {
        // 更新本地状态
        this.vehicleStatus.doorLocked = newDoorStatus;
        
        const message = newDoorStatus ? '车门已上锁' : '车门已解锁';
        promptAction.showToast({ message: message });
        hilog.info(0x0000, this.TAG, 'Door control command sent: %{public}s', newDoorStatus ? 'LOCKED' : 'UNLOCKED');
      } else {
        throw new Error('Failed to send door control command');
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to send door control command: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '操作失败，请重试' });
    }
  }

  // ==================== 辅助方法 ====================

  /**
   * 获取油量颜色状态
   */
  private getFuelColor(): string {
    if (this.vehicleStatus.fuelLevel > 50) return '#4CAF50';  // 绿色 - 充足
    if (this.vehicleStatus.fuelLevel > 20) return '#FFC107';  // 黄色 - 一般
    return '#F44336';                                         // 红色 - 不足
  }

  /**
   * 获取胎压颜色状态
   */
  private getTirePressureColor(): string {
    const pressure = this.vehicleStatus.tirePressure;
    if (pressure >= 2.2 && pressure <= 2.5) return '#4CAF50'; // 正常范围
    if (pressure >= 1.8 && pressure <= 2.8) return '#FFC107'; // 警告范围
    return '#F44336';                                         // 危险范围
  }

  /**
   * 获取车速颜色状态
   */
  private getSpeedColor(): string {
    if (this.vehicleStatus.speed === 0) return '#AAAAAA';     // 灰色 - 静止
    if (this.vehicleStatus.speed < 60) return '#4CAF50';      // 绿色 - 低速
    if (this.vehicleStatus.speed < 100) return '#FFC107';     // 黄色 - 中速
    return '#F44336';                                         // 红色 - 高速
  }

  /**
   * 清理资源
   */
  private cleanup(): void {
    // 清理定时器
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