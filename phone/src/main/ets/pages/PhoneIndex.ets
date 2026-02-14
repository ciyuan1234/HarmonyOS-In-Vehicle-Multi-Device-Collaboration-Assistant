/**
 * 手机端主页
 * 
 * 核心功能：
 * 1. 分布式设备发现和连接管理
 * 2. 车辆远程控制功能
 * 3. 实时车辆状态监控
 * 4. 简洁直观的手机UI适配
 * 
 * @author 车载多设备协同助手项目组
 * @version 1.0.0
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 导入自定义组件
import { DeviceDiscoveryPanel } from '../components/DeviceDiscoveryPanel';
import { VehicleControlPanel } from '../components/VehicleControlPanel';
import { VehicleStatusPanel } from '../components/VehicleStatusPanel';

// 导入工具类
import { DeviceDiscoveryManager } from '../utils/DeviceDiscoveryManager';
import { DistributedDataManager } from '../../../shared/src/main/ets/utils/DistributedDataManager';

@Entry
@Component
struct PhoneIndex {
  // 状态管理
  @State currentTab: string = 'control'; // control, status, devices
  @State isConnected: boolean = false;   // 分布式连接状态
  @State deviceName: string = '我的手机'; // 设备名称
  
  // 组件引用
  @Provide() devicePanel: DeviceDiscoveryPanel = new DeviceDiscoveryPanel();
  @Provide() controlPanel: VehicleControlPanel = new VehicleControlPanel();
  @Provide() statusPanel: VehicleStatusPanel = new VehicleStatusPanel();
  
  // 工具类实例
  private discoveryManager: DeviceDiscoveryManager = DeviceDiscoveryManager.getInstance();
  private dataManager: DistributedDataManager = DistributedDataManager.getInstance();
  
  // 私有属性
  private readonly TAG: string = 'PhoneIndex';
  private deviceId: string = 'phone_device_' + Date.now().toString();
  
  aboutToAppear(): void {
    this.initializeApp();
  }
  
  aboutToDisappear(): void {
    this.cleanup();
  }
  
  build() {
    Column() {
      // 顶部状态栏
      this.renderStatusBar()
      
      // 主要内容区域
      this.renderMainContent()
      
      // 底部导航栏
      this.renderBottomNavigation()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  /**
   * 渲染状态栏
   */
  @Builder
  private renderStatusBar() {
    Row() {
      Column() {
        Text(this.deviceName)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        
        Text(this.isConnected ? '已连接车机系统' : '未连接')
          .fontSize(12)
          .fontColor(this.isConnected ? '#C8E6C9' : '#FFCDD2')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 系统时间和连接指示器
      Row() {
        If (this.isConnected) {
          Circle()
            .width(8)
            .height(8)
            .fill('#4CAF50')
            .margin({ right: 8 })
        }
        
        Text(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }))
          .fontSize(14)
          .fontColor('#FFFFFF')
      }
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#2196F3')
    .justifyContent(FlexAlign.SpaceBetween)
  }
  
  /**
   * 渲染主要内容区域
   */
  @Builder
  private renderMainContent() {
    Scroll() {
      Column() {
        // 根据当前标签显示不同面板
        If (this.currentTab === 'control') {
          // 车辆控制面板
          this.controlPanel
            .width('100%')
            .margin({ bottom: 16 })
        }
        
        If (this.currentTab === 'status') {
          // 车辆状态面板
          this.statusPanel
            .width('100%')
            .margin({ bottom: 16 })
        }
        
        If (this.currentTab === 'devices') {
          // 设备发现面板
          this.devicePanel
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
  private renderBottomNavigation() {
    Row() {
      this.renderNavButton('control', '控制', '🎮')
      this.renderNavButton('status', '状态', '📊')
      this.renderNavButton('devices', '设备', '📱')
    }
    .width('100%')
    .height(70)
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#E0E0E0' })
    .justifyContent(FlexAlign.SpaceAround)
  }
  
  /**
   * 渲染导航按钮
   */
  @Builder
  private renderNavButton(tab: string, label: string, icon: string) {
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
      this.switchTab(tab);
    })
  }
  
  /**
   * 初始化应用程序
   */
  private async initializeApp(): Promise<void> {
    try {
      hilog.info(0x0000, this.TAG, 'Initializing phone application');
      
      // 初始化设备发现管理器
      const discoverySuccess = await this.discoveryManager.init();
      
      // 初始化分布式数据管理
      const dataSuccess = await this.dataManager.init(this.deviceId);
      
      if (discoverySuccess && dataSuccess) {
        this.isConnected = true;
        
        // 注册连接状态监听
        this.dataManager.onConnectionStatusChanged(this.handleConnectionStatusChange);
        
        promptAction.showToast({
          message: '手机端系统启动成功'
        });
        
        hilog.info(0x0000, this.TAG, 'Phone application initialized successfully');
      } else {
        promptAction.showToast({
          message: '系统初始化部分失败'
        });
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to initialize application: %{public}s', 
                 JSON.stringify(error));
      promptAction.showToast({
        message: '系统初始化错误'
      });
    }
  }
  
  /**
   * 处理连接状态变更
   */
  private handleConnectionStatusChange = (status: any): void => {
    this.isConnected = status === 'connected';
    hilog.info(0x0000, this.TAG, 'Connection status changed to: %{public}s', status);
  }
  
  /**
   * 切换页面标签
   */
  private switchTab(tab: string): void {
    this.currentTab = tab;
    hilog.info(0x0000, this.TAG, 'Switched to tab: %{public}s', tab);
  }
  
  /**
   * 清理资源
   */
  private cleanup(): void {
    try {
      // 停止设备发现
      this.discoveryManager.stopScanning();
      
      // 移除监听器
      this.dataManager.removeConnectionListener(this.handleConnectionStatusChange);
      
      hilog.info(0x0000, this.TAG, 'Application cleanup completed');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Error during cleanup: %{public}s', JSON.stringify(error));
    }
  }
}