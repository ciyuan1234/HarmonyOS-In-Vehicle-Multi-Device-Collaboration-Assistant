/**
 * 设备发现面板组件
 * 
 * 功能描述：
 * 1. 显示可连接的设备列表
 * 2. 支持一键连接/断开设备
 * 3. 显示设备状态和信息
 * 
 * @author 车载多设备协同助手项目组
 */

import { DeviceInfo, DeviceDiscoveryManager } from '../utils/DeviceDiscoveryManager';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export struct DeviceDiscoveryPanel {
  @State devices: DeviceInfo[] = [];
  @State isScanning: boolean = false;
  
  private discoveryManager: DeviceDiscoveryManager = DeviceDiscoveryManager.getInstance();
  private readonly TAG: string = 'DeviceDiscoveryPanel';
  
  aboutToAppear(): void {
    this.initializePanel();
  }
  
  build() {
    Column() {
      // 面板标题和控制按钮
      this.renderHeader()
      
      // 设备列表
      this.renderDeviceList()
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
        Text('📱 设备发现')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        
        Text(`${this.devices.length} 个设备`)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 刷新按钮
      Button('🔄')
        .width(36)
        .height(36)
        .backgroundColor('#F5F5F5')
        .fontColor('#666666')
        .borderRadius(18)
        .margin({ right: 8 })
        .onClick(() => {
          this.refreshDevices();
        })
      
      // 扫描状态指示器
      If (this.isScanning) {
        LoadingProgress()
          .width(20)
          .height(20)
          .color('#2196F3')
      }
    }
    .width('100%')
    .margin({ bottom: 16 })
  }
  
  /**
   * 渲染设备列表
   */
  @Builder
  private renderDeviceList() {
    If (this.devices.length === 0) {
      this.renderEmptyState()
    } else {
      Column() {
        ForEach(this.devices, (device: DeviceInfo) => {
          this.renderDeviceItem(device)
        }, (item: DeviceInfo) => item.deviceId)
      }
    }
  }
  
  /**
   * 渲染空状态
   */
  @Builder
  private renderEmptyState() {
    Column() {
      Text('🔍')
        .fontSize(48)
        .margin({ bottom: 16 })
      
      Text('暂未发现可连接设备')
        .fontSize(14)
        .fontColor('#999999')
      
      Text('请确保设备在同一网络下')
        .fontSize(12)
        .fontColor('#CCCCCC')
        .margin({ top: 4 })
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
  }
  
  /**
   * 渲染设备项
   */
  @Builder
  private renderDeviceItem(device: DeviceInfo) {
    Row() {
      // 设备图标
      this.renderDeviceIcon(device.deviceType)
      
      // 设备信息
      Column() {
        Row() {
          Text(device.deviceName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .layoutWeight(1)
          
          // 设备类型标签
          Text(this.getDeviceTypeLabel(device.deviceType))
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor(this.getDeviceTypeColor(device.deviceType))
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        }
        .width('100%')
        .margin({ bottom: 4 })
        
        // 状态信息行
        Row() {
          // 在线状态
          Row() {
            Circle()
              .width(8)
              .height(8)
              .fill(device.isOnline ? '#4CAF50' : '#999999')
              .margin({ right: 4 })
            
            Text(device.isOnline ? '在线' : '离线')
              .fontSize(12)
              .fontColor(device.isOnline ? '#4CAF50' : '#999999')
          }
          .margin({ right: 12 })
          
          // 信号强度
          Row() {
            Text('📶')
              .fontSize(12)
              .margin({ right: 2 })
            
            Text(`${device.signalStrength}%`)
              .fontSize(12)
              .fontColor('#666666')
          }
          .margin({ right: 12 })
          
          // 电池电量
          Row() {
            Text('🔋')
              .fontSize(12)
              .margin({ right: 2 })
            
            Text(`${device.batteryLevel}%`)
              .fontSize(12)
              .fontColor('#666666')
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      
      // 连接按钮
      this.renderConnectButton(device)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
    .margin({ bottom: 8 })
  }
  
  /**
   * 渲染设备图标
   */
  @Builder
  private renderDeviceIcon(deviceType: string) {
    Row() {
      Switch (deviceType) {
        Case ('phone'):
          Text('📱')
            .fontSize(24)
        Case ('car'):
          Text('🚗')
            .fontSize(24)
        Case ('watch'):
          Text('⌚')
            .fontSize(24)
        default:
          Text('📱')
            .fontSize(24)
      }
    }
    .width(40)
    .height(40)
    .backgroundColor('#E3F2FD')
    .borderRadius(20)
    .justifyContent(FlexAlign.Center)
    .margin({ right: 12 })
  }
  
  /**
   * 渲染连接按钮
   */
  @Builder
  private renderConnectButton(device: DeviceInfo) {
    Button(device.isConnected ? '断开' : '连接')
      .width(60)
      .height(32)
      .fontSize(12)
      .backgroundColor(device.isConnected ? '#F44336' : '#2196F3')
      .fontColor('#FFFFFF')
      .borderRadius(16)
      .onClick(() => {
        if (device.isConnected) {
          this.disconnectDevice(device.deviceId);
        } else {
          this.connectDevice(device.deviceId);
        }
      })
  }
  
  /**
   * 初始化面板
   */
  private async initializePanel(): Promise<void> {
    try {
      // 注册设备状态变更监听
      this.discoveryManager.onDeviceStatusChange(this.handleDeviceListChange);
      
      // 获取初始设备列表
      this.refreshDevices();
      
      hilog.info(0x0000, this.TAG, 'DeviceDiscoveryPanel initialized');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to initialize panel: %{public}s', 
                 JSON.stringify(error));
    }
  }
  
  /**
   * 刷新设备列表
   */
  private async refreshDevices(): Promise<void> {
    this.isScanning = true;
    
    try {
      // 模拟扫描过程
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      const devices = this.discoveryManager.getOnlineDevices();
      this.devices = [...devices];
      
      hilog.info(0x0000, this.TAG, 'Devices refreshed, found %{public}d devices', 
                 this.devices.length);
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to refresh devices: %{public}s', 
                 JSON.stringify(error));
    } finally {
      this.isScanning = false;
    }
  }
  
  /**
   * 连接设备
   */
  private async connectDevice(deviceId: string): Promise<void> {
    try {
      const success = await this.discoveryManager.connectToDevice(deviceId);
      if (success) {
        // 更新本地状态
        const device = this.devices.find(d => d.deviceId === deviceId);
        if (device) {
          device.isConnected = true;
        }
        hilog.info(0x0000, this.TAG, 'Device connected successfully: %{public}s', deviceId);
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to connect device: %{public}s', 
                 JSON.stringify(error));
    }
  }
  
  /**
   * 断开设备连接
   */
  private async disconnectDevice(deviceId: string): Promise<void> {
    try {
      const success = await this.discoveryManager.disconnectDevice(deviceId);
      if (success) {
        // 更新本地状态
        const device = this.devices.find(d => d.deviceId === deviceId);
        if (device) {
          device.isConnected = false;
        }
        hilog.info(0x0000, this.TAG, 'Device disconnected successfully: %{public}s', deviceId);
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to disconnect device: %{public}s', 
                 JSON.stringify(error));
    }
  }
  
  /**
   * 处理设备列表变更
   */
  private handleDeviceListChange = (devices: DeviceInfo[]): void => {
    this.devices = [...devices.filter(device => device.isOnline)];
    hilog.debug(0x0000, this.TAG, 'Device list updated, %{public}d devices', this.devices.length);
  }
  
  /**
   * 获取设备类型标签
   */
  private getDeviceTypeLabel(deviceType: string): string {
    switch (deviceType) {
      case 'phone': return '手机';
      case 'car': return '车机';
      case 'watch': return '手表';
      default: return '未知';
    }
  }
  
  /**
   * 获取设备类型颜色
   */
  private getDeviceTypeColor(deviceType: string): string {
    switch (deviceType) {
      case 'phone': return '#2196F3';
      case 'car': return '#4CAF50';
      case 'watch': return '#FF9800';
      default: return '#9E9E9E';
    }
  }
  
  /**
   * 组件销毁时清理
   */
  aboutToDisappear(): void {
    this.discoveryManager.removeDeviceStatusCallback(this.handleDeviceListChange);
  }
}