/**
 * 车机端主页
 * 
 * 核心功能：
 * 1. 初始化分布式数据管理模块
 * 2. 接收手机端控制指令
 * 3. 模拟车辆数据生成
 * 4. 响应手表端寻车指令
 * 5. 整合各功能面板
 * 
 * @author 车载多设备协同助手项目组
 * @version 1.0.0
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 导入自定义组件
import { NavigationPanel } from '../components/NavigationPanel';
import { MusicPanel } from '../components/MusicPanel';
import { ClimatePanel } from '../components/ClimatePanel';
import { DashboardPanel } from '../components/DashboardPanel';

// 导入工具类
import { VehicleDataSimulator, VehicleData } from '../utils/VehicleDataSimulator';
import { DistributedDataManager } from '../../../shared/src/main/ets/utils/DistributedDataManager';

@Entry
@Component
struct CarMachineIndex {
  // 状态管理
  @State currentTab: string = 'dashboard'; // 当前页面标签
  @State isConnected: boolean = false;     // 分布式连接状态
  @State deviceName: string = '车机系统';   // 设备名称
  
  // 组件引用
  @Provide() navPanel: NavigationPanel = new NavigationPanel();
  @Provide() musicPanel: MusicPanel = new MusicPanel();
  @Provide() climatePanel: ClimatePanel = new ClimatePanel();
  @Provide() dashboardPanel: DashboardPanel = new DashboardPanel();
  
  // 工具类实例
  private vehicleSimulator: VehicleDataSimulator = VehicleDataSimulator.getInstance();
  private dataManager: DistributedDataManager = DistributedDataManager.getInstance();
  
  // 私有属性
  private readonly TAG: string = 'CarMachineIndex';
  private deviceId: string = 'car_device_' + Date.now().toString();
  
  // ===== 核心逻辑位置标注 =====
  // 位置1: 页面初始化逻辑
  aboutToAppear(): void {
    this.initializeApp();
  }
  
  // 位置2: 页面销毁清理逻辑
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
    .backgroundColor('#000000')
  }
  
  /**
   * 渲染状态栏
   */
  @Builder
  private renderStatusBar() {
    Row() {
      // 设备信息
      Column() {
        Text(this.deviceName)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        
        Text(this.isConnected ? '已连接' : '未连接')
          .fontSize(12)
          .fontColor(this.isConnected ? '#4CAF50' : '#F44336')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 系统时间
      Text(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }))
        .fontSize(16)
        .fontColor('#FFFFFF')
    }
    .width('100%')
    .height(60)
    .padding({ left: 20, right: 20 })
    .backgroundColor('#1E1E1E')
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
        If (this.currentTab === 'dashboard') {
          // ===== 核心逻辑位置3: 仪表盘数据更新 =====
          this.dashboardPanel
            .width('100%')
            .margin({ bottom: 16 })
        }
        
        If (this.currentTab === 'navigation') {
          this.navPanel
            .width('100%')
            .margin({ bottom: 16 })
        }
        
        If (this.currentTab === 'music') {
          this.musicPanel
            .width('100%')
            .margin({ bottom: 16 })
        }
        
        If (this.currentTab === 'climate') {
          this.climatePanel
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
      this.renderNavButton('dashboard', '仪表盘', '🚗')
      this.renderNavButton('navigation', '导航', '🧭')
      this.renderNavButton('music', '音乐', '🎵')
      this.renderNavButton('climate', '空调', '❄️')
    }
    .width('100%')
    .height(70)
    .backgroundColor('#1E1E1E')
    .border({ width: { top: 1 }, color: '#333333' })
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
        .fontColor(this.currentTab === tab ? '#4CAF50' : '#AAAAAA')
        .margin({ bottom: 4 })
      
      Text(label)
        .fontSize(12)
        .fontColor(this.currentTab === tab ? '#4CAF50' : '#AAAAAA')
    }
    .onClick(() => {
      this.switchTab(tab);
    })
  }
  
  // ===== 核心逻辑位置4: 应用初始化 =====
  /**
   * 初始化应用程序
   */
  private async initializeApp(): Promise<void> {
    try {
      hilog.info(0x0000, this.TAG, 'Initializing car machine application');
      
      // 初始化分布式数据管理
      await this.initializeDistributedData();
      
      // 启动车辆数据模拟
      this.startVehicleSimulation();
      
      // 设置数据监听
      this.setupDataListeners();
      
      // 显示初始化成功提示
      promptAction.showToast({
        message: '车机系统启动成功'
      });
      
      hilog.info(0x0000, this.TAG, 'Car machine application initialized successfully');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to initialize application: %{public}s', 
                 JSON.stringify(error));
      promptAction.showToast({
        message: '系统初始化失败'
      });
    }
  }
  
  // ===== 核心逻辑位置5: 分布式数据初始化 =====
  /**
   * 初始化分布式数据管理
   */
  private async initializeDistributedData(): Promise<void> {
    const success = await this.dataManager.init(this.deviceId);
    if (success) {
      this.isConnected = true;
      
      // 注册数据变更监听
      this.dataManager.onDataChanged(this.handleRemoteDataChange);
      
      // 注册连接状态监听
      this.dataManager.onConnectionStatusChanged(this.handleConnectionStatusChange);
      
      hilog.info(0x0000, this.TAG, 'Distributed data manager initialized');
    } else {
      hilog.error(0x0000, this.TAG, 'Failed to initialize distributed data manager');
    }
  }
  
  // ===== 核心逻辑位置6: 车辆数据模拟启动 =====
  /**
   * 启动车辆数据模拟
   */
  private startVehicleSimulation(): void {
    // 订阅车辆数据更新
    this.vehicleSimulator.subscribe(this.handleVehicleDataUpdate);
    
    // 开始模拟
    this.vehicleSimulator.startSimulation();
    
    hilog.info(0x0000, this.TAG, 'Vehicle data simulation started');
  }
  
  // ===== 核心逻辑位置7: 数据监听设置 =====
  /**
   * 设置数据监听器
   */
  private setupDataListeners(): void {
    // 设置定时同步到分布式存储
    setInterval(() => {
      const currentData = this.vehicleSimulator.getCurrentData();
      this.syncVehicleData(currentData);
    }, 2000); // 每2秒同步一次
  }
  
  // ===== 核心逻辑位置8: 车辆数据更新处理 =====
  /**
   * 处理车辆数据更新
   */
  private handleVehicleDataUpdate = (data: VehicleData): void => {
    // 更新仪表盘显示
    this.dashboardPanel.updateVehicleData(data);
    
    hilog.debug(0x0000, this.TAG, 'Vehicle data updated: speed=%{public}d, fuel=%{public}d%%', 
               data.speed, data.fuelLevel);
  }
  
  // ===== 核心逻辑位置9: 远程数据变更处理 =====
  /**
   * 处理远程数据变更（接收手机端指令）
   */
  private handleRemoteDataChange = (data: any): void => {
    hilog.info(0x0000, this.TAG, 'Received remote data change: %{public}s', JSON.stringify(data));
    
    // 处理导航指令
    if (data.navigationDestination) {
      this.navPanel.updateNavigation(data.navigationDestination);
      this.switchTab('navigation');
    }
    
    // 处理音乐控制指令
    if (data.hasOwnProperty('isMusicPlaying')) {
      this.musicPanel.setPlayState(data.isMusicPlaying);
      this.switchTab('music');
    }
    
    // 处理空调控制指令
    if (data.acTemperature) {
      this.climatePanel.setTargetTemperature(data.acTemperature);
      this.switchTab('climate');
    }
    
    if (data.hasOwnProperty('isAcOn')) {
      this.climatePanel.setAcState(data.isAcOn);
    }
    
    // 处理寻车指令（手表端）
    if (data.findCarCommand) {
      this.handleFindCarCommand();
    }
  }
  
  // ===== 核心逻辑位置10: 连接状态变更处理 =====
  /**
   * 处理连接状态变更
   */
  private handleConnectionStatusChange = (status: any): void => {
    this.isConnected = status === 'connected';
    hilog.info(0x0000, this.TAG, 'Connection status changed to: %{public}s', status);
  }
  
  // ===== 核心逻辑位置11: 数据同步到分布式存储 =====
  /**
   * 同步车辆数据到分布式存储
   */
  private async syncVehicleData(data: VehicleData): Promise<void> {
    try {
      await this.dataManager.storeVehicleData({
        fuelLevel: data.fuelLevel,
        tirePressure: data.tirePressure,
        speed: data.speed
      });
      hilog.debug(0x0000, this.TAG, 'Vehicle data synced to distributed storage');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to sync vehicle data: %{public}s', 
                 JSON.stringify(error));
    }
  }
  
  // ===== 核心逻辑位置12: 寻车指令处理 =====
  /**
   * 处理寻车指令（响应手表端"一键寻车"）
   */
  private handleFindCarCommand(): void {
    hilog.info(0x0000, this.TAG, 'Find car command received');
    
    // 显示寻车提示
    promptAction.showDialog({
      title: '寻车提醒',
      message: '车辆鸣笛+双闪开启\n请前往车辆位置',
      buttons: [
        {
          text: '确定',
          color: '#4CAF50'
        }
      ]
    });
    
    // 模拟车辆响应效果
    setTimeout(() => {
      promptAction.showToast({
        message: '车辆已在响铃和闪烁' 
      });
    }, 1000);
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
      // 停止车辆模拟
      this.vehicleSimulator.stopSimulation();
      this.vehicleSimulator.unsubscribe(this.handleVehicleDataUpdate);
      
      // 移除数据监听
      this.dataManager.removeDataListener(this.handleRemoteDataChange);
      this.dataManager.removeConnectionListener(this.handleConnectionStatusChange);
      
      hilog.info(0x0000, this.TAG, 'Application cleanup completed');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Error during cleanup: %{public}s', JSON.stringify(error));
    }
  }
}