import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { DeviceItem } from '../components/DeviceItem';
import { VehicleControlPanel } from '../components/VehicleControlPanel';
import { QuickActionCard } from '../components/QuickActionCard';
import { VehicleAssistantManager } from '../../../shared/src/main/ets/manager/VehicleAssistantManager';
import { DeviceInfo, DeviceType, ControlCommand, VehicleStatus } from '../../../shared/src/main/ets/model/DeviceModel';

@Entry
@Component
struct PhoneMain {
  @State deviceList: DeviceInfo[] = [];
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

  aboutToAppear(): void {
    this.initializeApp();
  }

  build() {
    Column() {
      // 顶部标题栏
      this.renderHeader()
      
      // 内容区域
      if (this.isLoading) {
        this.renderLoadingView()
      } else {
        Scroll() {
          Column() {
            // 快捷操作区域
            this.renderQuickActions()
            
            // 车辆控制面板
            this.renderVehicleControl()
            
            // 设备列表
            this.renderDeviceList()
          }
          .padding(16)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 渲染顶部标题栏
   */
  @Builder
  renderHeader() {
    Row() {
      Column() {
        Text('车载多设备协同助手')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        
        Text('手机控制中心')
          .fontSize(12)
          .fontColor('#EEEEEE')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 刷新按钮
      Button('🔄')
        .width(40)
        .height(40)
        .backgroundColor('#FFFFFF20')
        .borderRadius(20)
        .onClick(() => {
          this.refreshData();
        })
    }
    .width('100%')
    .height(80)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#2196F3')
    .justifyContent(FlexAlign.SpaceBetween)
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
      
      Text('正在初始化系统...')
        .fontSize(16)
        .fontColor('#666666')
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 渲染快捷操作区域
   */
  @Builder
  renderQuickActions() {
    Column() {
      Text('快捷操作')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 12 })
        .selfAlign(ItemAlign.Start)
      
      Grid() {
        // 启动发动机
        GridItem() {
          QuickActionCard({
            title: '启动车辆',
            icon: '🔑',
            backgroundColor: '#4CAF50',
            command: ControlCommand.START_ENGINE,
            onAction: this.handleQuickAction
          })
        }
        
        // 锁车
        GridItem() {
          QuickActionCard({
            title: '远程锁车',
            icon: '🔒',
            backgroundColor: '#FF9800',
            command: ControlCommand.LOCK_DOOR,
            onAction: this.handleQuickAction
          })
        }
        
        // 空调控制
        GridItem() {
          QuickActionCard({
            title: '开启空调',
            icon: '❄️',
            backgroundColor: '#2196F3',
            command: ControlCommand.OPEN_AC,
            onAction: this.handleQuickAction
          })
        }
        
        // 寻车
        GridItem() {
          QuickActionCard({
            title: '寻找车辆',
            icon: '🔍',
            backgroundColor: '#9C27B0',
            command: ControlCommand.NAVIGATE_TO,
            onAction: this.handleQuickAction
          })
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  /**
   * 渲染车辆控制面板
   */
  @Builder
  renderVehicleControl() {
    VehicleControlPanel({
      vehicleStatus: this.vehicleStatus,
      onSendCommand: this.handleVehicleCommand
    })
    .margin({ bottom: 20 })
  }

  /**
   * 渲染设备列表
   */
  @Builder
  renderDeviceList() {
    Column() {
      Row() {
        Text('连接设备')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Text(`${this.deviceList.length} 个设备`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 设备列表
      ForEach(this.deviceList, (device: DeviceInfo) => {
        DeviceItem({
          device: device,
          onSelect: this.handleDeviceSelect
        })
      }, (item: DeviceInfo) => item.deviceId)
      
      // 空状态
      if (this.deviceList.length === 0) {
        Column() {
          Text('📱')
            .fontSize(48)
            .margin({ bottom: 16 })
          
          Text('暂无连接设备')
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
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
        'phone_device_' + Date.now()
      );
      
      if (success) {
        // 设置回调监听
        this.setupListeners();
        
        // 获取初始数据
        this.refreshData();
        
        promptAction.showToast({
          message: '系统初始化成功'
        });
      } else {
        promptAction.showToast({
          message: '系统初始化失败'
        });
      }
    } catch (error) {
      console.error('App initialization failed:', error);
      promptAction.showToast({
        message: '初始化出错: ' + (error as Error).message
      });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 设置监听器
   */
  private setupListeners(): void {
    // 设备列表变化监听
    this.vehicleManager.setDeviceListListener((devices) => {
      this.deviceList = [...devices];
    });
    
    // 车辆状态变化监听
    this.vehicleManager.setVehicleStatusListener((status) => {
      this.vehicleStatus = { ...status };
    });
  }

  /**
   * 刷新数据
   */
  private refreshData(): void {
    // 获取最新设备列表
    const devices = this.vehicleManager.getDeviceList();
    this.deviceList = [...devices];
    
    // 获取最新车辆状态
    const status = this.vehicleManager.getCurrentVehicleStatus();
    this.vehicleStatus = { ...status };
    
    console.info('Data refreshed');
  }

  /**
   * 处理快捷操作
   */
  private handleQuickAction = (command: ControlCommand, device?: DeviceInfo): void => {
    console.info('Quick action triggered:', command);
    
    // 发送命令到目标设备
    this.vehicleManager.sendCommand(command, device?.deviceId)
      .then(success => {
        if (success) {
          promptAction.showToast({
            message: '命令发送成功'
          });
        } else {
          promptAction.showToast({
            message: '命令发送失败'
          });
        }
      })
      .catch(error => {
        console.error('Failed to send command:', error);
        promptAction.showToast({
          message: '发送命令时出错'
        });
      });
  }

  /**
   * 处理车辆控制命令
   */
  private handleVehicleCommand = (command: ControlCommand, params?: any): void => {
    console.info('Vehicle command triggered:', command, params);
    
    this.vehicleManager.sendCommand(command, undefined, params)
      .then(success => {
        if (success) {
          promptAction.showToast({
            message: '车辆控制命令已发送'
          });
        }
      });
  }

  /**
   * 处理设备选择
   */
  private handleDeviceSelect = (device: DeviceInfo): void => {
    console.info('Device selected:', device.deviceName);
    
    promptAction.showToast({
      message: `选择了设备: ${device.deviceName}`
    });
    
    // 可以在这里打开设备详情或执行设备特定操作
  }
}