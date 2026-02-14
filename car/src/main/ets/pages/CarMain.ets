import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { DashboardDisplay } from '../components/DashboardDisplay';
import { MediaControlPanel } from '../components/MediaControlPanel';
import { ClimateControlPanel } from '../components/ClimateControlPanel';
import { VehicleAssistantManager } from '../../../shared/src/main/ets/manager/VehicleAssistantManager';
import { VehicleStatus, CommandParams, ControlCommand } from '../../../shared/src/main/ets/model/DeviceModel';

@Entry
@Component
struct CarMain {
  @State currentTab: string = 'dashboard'; // dashboard, media, climate
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
  private dashboardRef: DashboardDisplay | null = null;

  aboutToAppear(): void {
    this.initializeApp();
  }

  build() {
    Column() {
      if (this.isLoading) {
        this.renderLoadingView()
      } else {
        // 主内容区域
        this.renderMainContent()
        
        // 底部导航栏
        this.renderBottomNavigation()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 渲染加载视图
   */
  @Builder
  renderLoadingView() {
    Column() {
      Text('🚗')
        .fontSize(48)
        .margin({ bottom: 16 })
      
      Text('车辆系统启动中...')
        .fontSize(16)
        .fontColor('#666666')
      
      // 启动进度条
      Progress({ value: 60, total: 100 })
        .width(200)
        .height(4)
        .margin({ top: 20 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 渲染主内容区域
   */
  @Builder
  renderMainContent() {
    Column() {
      // 顶部状态栏
      this.renderStatusBar()
      
      // 内容区域
      this.renderContentArea()
    }
    .layoutWeight(1)
  }

  /**
   * 渲染状态栏
   */
  @Builder
  renderStatusBar() {
    Row() {
      Text('车载信息系统')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .layoutWeight(1)
      
      // 系统时间
      Text(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }))
        .fontSize(14)
        .fontColor('#EEEEEE')
    }
    .width('100%')
    .height(50)
    .padding({ left: 20, right: 20 })
    .backgroundColor('#2196F3')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  /**
   * 渲染内容区域
   */
  @Builder
  renderContentArea() {
    Scroll() {
      Column() {
        if (this.currentTab === 'dashboard') {
          // 仪表盘视图
          DashboardDisplay({
            vehicleStatus: this.vehicleStatus
          })
          .width('100%')
          .height(400)
          .margin({ bottom: 16 })
        } else if (this.currentTab === 'media') {
          // 多媒体控制
          MediaControlPanel()
            .width('100%')
            .margin({ bottom: 16 })
        } else if (this.currentTab === 'climate') {
          // 空调控制
          ClimateControlPanel()
            .width('100%')
            .margin({ bottom: 16 })
        }
      }
      .padding(16)
    }
    .layoutWeight(1)
  }

  /**
   * 渲染底部导航栏
   */
  @Builder
  renderBottomNavigation() {
    Row() {
      this.renderNavItem('dashboard', '仪表盘', '🚗')
      this.renderNavItem('media', '多媒体', '🎵')
      this.renderNavItem('climate', '空调', '❄️')
    }
    .width('100%')
    .height(70)
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#E0E0E0' })
    .justifyContent(FlexAlign.SpaceAround)
  }

  /**
   * 渲染导航项
   */
  @Builder
  renderNavItem(tab: string, label: string, icon: string) {
    Column() {
      Text(icon)
        .fontSize(20)
        .fontColor(this.currentTab === tab ? '#2196F3' : '#999999')
        .margin({ bottom: 4 })
      
      Text(label)
        .fontSize(12)
        .fontColor(this.currentTab === tab ? '#2196F3' : '#999999')
    }
    .onClick(() => {
      this.currentTab = tab;
      console.info('Switched to tab:', tab);
    })
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
        'car_device_' + Date.now()
      );
      
      if (success) {
        // 设置回调监听
        this.setupListeners();
        
        // 启动车辆状态模拟
        this.vehicleManager.startVehicleSimulation(1000);
        
        promptAction.showToast({
          message: '车辆系统启动成功'
        });
      } else {
        promptAction.showToast({
          message: '车辆系统启动失败'
        });
      }
    } catch (error) {
      console.error('Car app initialization failed:', error);
      promptAction.showToast({
        message: '系统初始化错误'
      });
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
      // 更新仪表盘显示
      if (this.dashboardRef) {
        this.dashboardRef.updateStatus(status);
      }
    });
    
    // 命令接收监听
    this.vehicleManager.setCommandReceivedListener((command) => {
      this.handleReceivedCommand(command);
    });
  }

  /**
   * 处理接收到的命令
   */
  private handleReceivedCommand(command: CommandParams): void {
    console.info('Received command in car:', command.command);
    
    switch (command.command) {
      case ControlCommand.START_ENGINE:
        promptAction.showToast({
          message: '收到启动发动机指令'
        });
        break;
      case ControlCommand.STOP_ENGINE:
        promptAction.showToast({
          message: '收到停止发动机指令'
        });
        break;
      case ControlCommand.LOCK_DOOR:
        promptAction.showToast({
          message: '收到锁车指令'
        });
        break;
      case ControlCommand.UNLOCK_DOOR:
        promptAction.showToast({
          message: '收到解锁指令'
        });
        break;
      case ControlCommand.OPEN_AC:
        this.currentTab = 'climate';
        promptAction.showToast({
          message: '空调已开启'
        });
        break;
      case ControlCommand.PLAY_MUSIC:
        this.currentTab = 'media';
        promptAction.showToast({
          message: '音乐播放已启动'
        });
        break;
      default:
        console.info('Unhandled command:', command.command);
    }
  }
}