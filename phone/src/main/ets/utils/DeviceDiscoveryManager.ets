/**
 * 设备发现管理器
 * 
 * 功能描述：
 * 1. 扫描局域网内可连接的HarmonyOS设备
 * 2. 管理设备连接状态
 * 3. 提供设备列表和状态查询接口
 * 
 * @author 车载多设备协同助手项目组
 * @version 1.0.0
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 设备信息接口
 */
export interface DeviceInfo {
  deviceId: string;           // 设备唯一标识
  deviceName: string;         // 设备名称
  deviceType: 'phone' | 'car' | 'watch'; // 设备类型
  isOnline: boolean;          // 是否在线
  isConnected: boolean;       // 是否已连接
  signalStrength: number;     // 信号强度 (0-100)
  batteryLevel: number;       // 电池电量 (0-100)
  lastSeen: number;           // 最后发现时间戳
}

/**
 * 设备状态变更回调
 */
export type DeviceStatusCallback = (devices: DeviceInfo[]) => void;

/**
 * 设备发现管理器类
 */
export class DeviceDiscoveryManager {
  // 单例实例
  private static instance: DeviceDiscoveryManager | null = null;
  
  // 私有属性
  private readonly TAG: string = 'DeviceDiscoveryManager';
  private readonly APP_ID: string = 'com.example.wanwuhulian';
  
  // 设备管理器实例
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  
  // 设备列表
  private discoveredDevices: Map<string, DeviceInfo> = new Map();
  private connectedDevices: Set<string> = new Set();
  
  // 回调函数
  private deviceStatusCallbacks: Set<DeviceStatusCallback> = new Set();
  
  // 扫描相关
  private scanTimer: number | null = null;
  private isScanning: boolean = false;
  private readonly SCAN_INTERVAL: number = 5000; // 5秒扫描一次
  
  /**
   * 私有构造函数
   */
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  public static getInstance(): DeviceDiscoveryManager {
    if (!DeviceDiscoveryManager.instance) {
      DeviceDiscoveryManager.instance = new DeviceDiscoveryManager();
    }
    return DeviceDiscoveryManager.instance;
  }
  
  /**
   * 初始化设备发现管理器
   */
  public async init(): Promise<boolean> {
    try {
      hilog.info(0x0000, this.TAG, 'Initializing DeviceDiscoveryManager');
      
      // 创建设备管理器实例
      this.deviceManager = distributedDeviceManager.createDeviceManager(this.APP_ID);
      
      // 注册设备状态监听
      this.registerDeviceListeners();
      
      // 开始定期扫描
      this.startPeriodicScan();
      
      hilog.info(0x0000, this.TAG, 'DeviceDiscoveryManager initialized successfully');
      return true;
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to initialize DeviceDiscoveryManager: %{public}s', 
                 JSON.stringify(error));
      return false;
    }
  }
  
  /**
   * 注册设备状态监听器
   */
  private registerDeviceListeners(): void {
    if (!this.deviceManager) return;
    
    try {
      // 监听可信设备上线
      this.deviceManager.on('trustDeviceOnline', (data) => {
        hilog.info(0x0000, this.TAG, 'Device online: %{public}s', data.deviceId);
        this.handleDeviceOnline(data);
      });
      
      // 监听可信设备下线
      this.deviceManager.on('trustDeviceOffline', (data) => {
        hilog.info(0x0000, this.TAG, 'Device offline: %{public}s', data.deviceId);
        this.handleDeviceOffline(data);
      });
      
      // 监听设备信息变化
      this.deviceManager.on('deviceChanged', (data) => {
        hilog.info(0x0000, this.TAG, 'Device changed: %{public}s', data.deviceId);
        this.handleDeviceChanged(data);
      });
      
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to register device listeners: %{public}s', 
                 JSON.stringify(error));
    }
  }
  
  /**
   * 开始定期扫描
   */
  private startPeriodicScan(): void {
    if (this.isScanning) return;
    
    this.isScanning = true;
    this.scanTimer = setInterval(() => {
      this.scanForDevices();
    }, this.SCAN_INTERVAL);
    
    // 立即执行一次扫描
    this.scanForDevices();
    
    hilog.info(0x0000, this.TAG, 'Periodic device scanning started');
  }
  
  /**
   * 扫描设备
   */
  private async scanForDevices(): Promise<void> {
    if (!this.deviceManager) return;
    
    try {
      // 获取可信设备列表
      const trustedDevices = this.deviceManager.getTrustedDeviceListSync();
      
      // 更新设备列表
      for (const device of trustedDevices) {
        const deviceInfo: DeviceInfo = {
          deviceId: device.deviceId,
          deviceName: device.deviceName,
          deviceType: this.mapDeviceType(device.deviceType),
          isOnline: device.isOnline,
          isConnected: this.connectedDevices.has(device.deviceId),
          signalStrength: this.generateSignalStrength(),
          batteryLevel: this.generateBatteryLevel(),
          lastSeen: Date.now()
        };
        
        this.discoveredDevices.set(device.deviceId, deviceInfo);
      }
      
      // 清理离线设备（超过30秒未见）
      this.cleanupOfflineDevices();
      
      // 通知状态变更
      this.notifyDeviceStatusChange();
      
      hilog.debug(0x0000, this.TAG, 'Device scan completed, found %{public}d devices', 
                 this.discoveredDevices.size);
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Device scan failed: %{public}s', JSON.stringify(error));
    }
  }
  
  /**
   * 映射设备类型
   */
  private mapDeviceType(deviceType: distributedDeviceManager.DeviceType): 'phone' | 'car' | 'watch' {
    switch (deviceType) {
      case distributedDeviceManager.DeviceType.CAR:
        return 'car';
      case distributedDeviceManager.DeviceType.WATCH:
        return 'watch';
      case distributedDeviceManager.DeviceType.PHONE:
      default:
        return 'phone';
    }
  }
  
  /**
   * 生成模拟信号强度
   */
  private generateSignalStrength(): number {
    return Math.floor(Math.random() * 40) + 60; // 60-100
  }
  
  /**
   * 生成模拟电池电量
   */
  private generateBatteryLevel(): number {
    return Math.floor(Math.random() * 50) + 30; // 30-80
  }
  
  /**
   * 处理设备上线事件
   */
  private handleDeviceOnline(device: distributedDeviceManager.DeviceBasicInfo): void {
    const deviceInfo: DeviceInfo = {
      deviceId: device.deviceId,
      deviceName: device.deviceName,
      deviceType: this.mapDeviceType(device.deviceType),
      isOnline: true,
      isConnected: this.connectedDevices.has(device.deviceId),
      signalStrength: this.generateSignalStrength(),
      batteryLevel: this.generateBatteryLevel(),
      lastSeen: Date.now()
    };
    
    this.discoveredDevices.set(device.deviceId, deviceInfo);
    this.notifyDeviceStatusChange();
  }
  
  /**
   * 处理设备下线事件
   */
  private handleDeviceOffline(device: distributedDeviceManager.DeviceBasicInfo): void {
    const existingDevice = this.discoveredDevices.get(device.deviceId);
    if (existingDevice) {
      existingDevice.isOnline = false;
      existingDevice.lastSeen = Date.now();
      this.notifyDeviceStatusChange();
    }
  }
  
  /**
   * 处理设备信息变更
   */
  private handleDeviceChanged(device: distributedDeviceManager.DeviceBasicInfo): void {
    const existingDevice = this.discoveredDevices.get(device.deviceId);
    if (existingDevice) {
      existingDevice.deviceName = device.deviceName;
      existingDevice.isOnline = device.isOnline;
      existingDevice.lastSeen = Date.now();
      this.notifyDeviceStatusChange();
    }
  }
  
  /**
   * 清理离线设备
   */
  private cleanupOfflineDevices(): void {
    const now = Date.now();
    const timeout = 30000; // 30秒超时
    
    for (const [deviceId, deviceInfo] of this.discoveredDevices.entries()) {
      if (now - deviceInfo.lastSeen > timeout && !deviceInfo.isOnline) {
        this.discoveredDevices.delete(deviceId);
        this.connectedDevices.delete(deviceId);
      }
    }
  }
  
  /**
   * 连接设备
   */
  public async connectToDevice(deviceId: string): Promise<boolean> {
    try {
      // 模拟连接过程
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      this.connectedDevices.add(deviceId);
      
      const device = this.discoveredDevices.get(deviceId);
      if (device) {
        device.isConnected = true;
      }
      
      this.notifyDeviceStatusChange();
      hilog.info(0x0000, this.TAG, 'Device connected: %{public}s', deviceId);
      return true;
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to connect device: %{public}s', JSON.stringify(error));
      return false;
    }
  }
  
  /**
   * 断开设备连接
   */
  public async disconnectDevice(deviceId: string): Promise<boolean> {
    try {
      this.connectedDevices.delete(deviceId);
      
      const device = this.discoveredDevices.get(deviceId);
      if (device) {
        device.isConnected = false;
      }
      
      this.notifyDeviceStatusChange();
      hilog.info(0x0000, this.TAG, 'Device disconnected: %{public}s', deviceId);
      return true;
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to disconnect device: %{public}s', JSON.stringify(error));
      return false;
    }
  }
  
  /**
   * 获取所有发现的设备
   */
  public getAllDevices(): DeviceInfo[] {
    return Array.from(this.discoveredDevices.values());
  }
  
  /**
   * 获取在线设备
   */
  public getOnlineDevices(): DeviceInfo[] {
    return Array.from(this.discoveredDevices.values())
      .filter(device => device.isOnline);
  }
  
  /**
   * 获取已连接设备
   */
  public getConnectedDevices(): DeviceInfo[] {
    return Array.from(this.discoveredDevices.values())
      .filter(device => device.isConnected);
  }
  
  /**
   * 根据类型筛选设备
   */
  public getDevicesByType(deviceType: 'phone' | 'car' | 'watch'): DeviceInfo[] {
    return Array.from(this.discoveredDevices.values())
      .filter(device => device.deviceType === deviceType);
  }
  
  /**
   * 查找特定设备
   */
  public findDevice(deviceId: string): DeviceInfo | undefined {
    return this.discoveredDevices.get(deviceId);
  }
  
  /**
   * 注册设备状态变更回调
   */
  public onDeviceStatusChange(callback: DeviceStatusCallback): void {
    this.deviceStatusCallbacks.add(callback);
    hilog.info(0x0000, this.TAG, 'Device status callback registered');
  }
  
  /**
   * 移除设备状态变更回调
   */
  public removeDeviceStatusCallback(callback: DeviceStatusCallback): void {
    this.deviceStatusCallbacks.delete(callback);
    hilog.info(0x0000, this.TAG, 'Device status callback removed');
  }
  
  /**
   * 通知设备状态变更
   */
  private notifyDeviceStatusChange(): void {
    const devices = this.getAllDevices();
    this.deviceStatusCallbacks.forEach(callback => {
      try {
        callback([...devices]); // 传递副本
      } catch (error) {
        hilog.error(0x0000, this.TAG, 'Error in device status callback: %{public}s', 
                   JSON.stringify(error));
      }
    });
  }
  
  /**
   * 停止扫描
   */
  public stopScanning(): void {
    if (this.scanTimer) {
      clearInterval(this.scanTimer);
      this.scanTimer = null;
    }
    this.isScanning = false;
    hilog.info(0x0000, this.TAG, 'Device scanning stopped');
  }
  
  /**
   * 销毁资源
   */
  public async destroy(): Promise<void> {
    try {
      this.stopScanning();
      
      // 移除监听器
      if (this.deviceManager) {
        this.deviceManager.off('trustDeviceOnline');
        this.deviceManager.off('trustDeviceOffline');
        this.deviceManager.off('deviceChanged');
        distributedDeviceManager.destroyDeviceManager(this.deviceManager);
      }
      
      // 清理数据
      this.discoveredDevices.clear();
      this.connectedDevices.clear();
      this.deviceStatusCallbacks.clear();
      
      DeviceDiscoveryManager.instance = null;
      hilog.info(0x0000, this.TAG, 'DeviceDiscoveryManager destroyed');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to destroy DeviceDiscoveryManager: %{public}s', 
                 JSON.stringify(error));
    }
  }
}