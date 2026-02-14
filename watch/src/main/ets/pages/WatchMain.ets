import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { WatchActionButton } from '../components/WatchActionButton';
import { WatchVehicleStatus } from '../components/WatchVehicleStatus';
import { VehicleAssistantManager } from '../../../shared/src/main/ets/manager/VehicleAssistantManager';
import { VehicleStatus, ControlCommand } from '../../../shared/src/main/ets/model/DeviceModel';

@Entry
@Component
struct WatchMain {
  @State currentTime: string = '';
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
  @State isLoading: boolean = true;
  
  private vehicleManager: VehicleAssistantManager = VehicleAssistantManager.getInstance();
  private statusRef: WatchVehicleStatus | null = null;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.initializeApp();
    this.startClock();
  }

  aboutToDisappear(): void {
    this.cleanup();
  }

  build() {
    Column() {
      if (this.isLoading) {
        this.renderLoadingView()
      } else {
        // 时间显示
        this.renderTimeDisplay()
        
        // 车辆状态概览
        this.renderVehicleOverview()
        
        // 快捷操作按钮
        this.renderQuickActions()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .padding(12)
  }

  /**
   * 渲染加载视图
   */
  @Builder
  renderLoadingView() {
    Column() {
      Text('⌚')
        .fontSize(32)
        .margin({ bottom: 8 })
      
      Text('初始化中...')
        .fontSize(12)
        .fontColor('#AAAAAA')
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 渲染时间显示
   */
  @Builder
  renderTimeDisplay() {
    Column() {
      Text(this.currentTime)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ bottom: 4 })
      
      Text('车载助手')
        .fontSize(12)
        .fontColor('#AAAAAA')
    }
    .width('100%')
    .margin({ bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 渲染车辆状态概览
   */
  @Builder
  renderVehicleOverview() {
    WatchVehicleStatus({
      vehicleStatus: this.vehicleStatus
    })
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 渲染快捷操作按钮
   */
  @Builder
  renderQuickActions() {
    Grid() {
      // 启动/停止发动机
      GridItem() {
        WatchActionButton({
          icon: this.vehicleStatus.engineStatus ? '⏹️' : '▶️',
          label: this.vehicleStatus.engineStatus ? '停止' : '启动',
          backgroundColor: this.vehicleStatus.engineStatus ? '#F44336' : '#4CAF50',
          command: this.vehicleStatus.engineStatus ? ControlCommand.STOP_ENGINE : ControlCommand.START_ENGINE,
          onPress: this.handleQuickAction
        })
      }
      
      // 锁车/解锁
      GridItem() {
        WatchActionButton({
          icon: this.vehicleStatus.doorLocked ? '🔓' : '🔒',
          label: this.vehicleStatus.doorLocked ? '解锁' : '锁车',
          backgroundColor: this.vehicleStatus.doorLocked ? '#4CAF50' : '#FF9800',
          command: this.vehicleStatus.doorLocked ? ControlCommand.UNLOCK_DOOR : ControlCommand.LOCK_DOOR,
          onPress: this.handleQuickAction
        })
      }
      
      // 空调控制
      GridItem() {
        WatchActionButton({
          icon: '❄️',
          label: '空调',
          backgroundColor: '#2196F3',
          command: ControlCommand.OPEN_AC,
          onPress: this.handleQuickAction
        })
      }
      
      // 寻车
      GridItem() {
        WatchActionButton({
          icon: '🔍',
          label: '寻车',
          backgroundColor: '#9C27B0',
          command: ControlCommand.NAVIGATE_TO,
          onPress: this.handleQuickAction
        })
      }
      
      // 音乐控制
      GridItem() {
        WatchActionButton({
          icon: '🎵',
          label: '音乐',
          backgroundColor: '#FF5722',
          command: ControlCommand.PLAY_MUSIC,
          onPress: this.handleQuickAction
        })
      }
      
      // 刷新状态
      GridItem() {
        WatchActionButton({
          icon: '🔄',
          label: '刷新',
          backgroundColor: '#607D8B',
          command: ControlCommand.NAVIGATE_TO, // 使用占位命令
          onPress: this.refreshStatus
        })
      }
    }
    .columnsTemplate('1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
    .layoutWeight(1)
  }

  /**
   * 初始化应用程序
   */
  private async initializeApp(): Promise<void> {
    try {
      this.isLoading = true;
      
      // 初始化车辆助手管理器
      const success = await this.vehicleManager.init(
        'com.example.wanwuhulian',
        'watch_device_' + Date.now()
      );
      
      if (success) {
        // 设置回调监听
        this.setupListeners();
        
        // 获取初始状态
        this.refreshStatus();
        
        console.info('Watch app initialized successfully');
      }
    } catch (error) {
      console.error('Watch app initialization failed:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 设置监听器
   */
  private setupListeners(): void {
    // 车辆状态变化监听
    this.vehicleManager.setVehicleStatusListener((status) => {
      this.vehicleStatus = { ...status };
      // 更新状态显示
      if (this.statusRef) {
        this.statusRef.updateStatus(status);
      }
    });
  }

  /**
   * 启动时钟
   */
  private startClock(): void {
    this.updateTime();
    this.timerId = setInterval(() => {
      this.updateTime();
    }, 1000);
  }

  /**
   * 更新时间显示
   */
  private updateTime(): void {
    const now = new Date();
    this.currentTime = now.toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  }

  /**
   * 处理快捷操作
   */
  private handleQuickAction = (command: ControlCommand): void => {
    console.info('Watch quick action:', command);
    
    // 发送命令
    this.vehicleManager.sendCommand(command)
      .then(success => {
        if (success) {
          // 震动反馈
          // 这里可以添加震动反馈
          console.info('Command sent successfully');
        }
      })
      .catch(error => {
        console.error('Failed to send command:', error);
      });
  }

  /**
   * 刷新车辆状态
   */
  private refreshStatus = (): void => {
    // 获取最新车辆状态
    const status = this.vehicleManager.getCurrentVehicleStatus();
    this.vehicleStatus = { ...status };
    
    console.info('Vehicle status refreshed');
  }

  /**
   * 清理资源
   */
  private cleanup(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }
}