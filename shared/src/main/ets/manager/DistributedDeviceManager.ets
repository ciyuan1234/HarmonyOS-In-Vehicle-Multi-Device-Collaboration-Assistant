import { BusinessError } from '@kit.BasicServicesKit';
import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { DeviceInfo, DeviceType } from '../model/DeviceModel';

/**
 * 分布式设备管理器
 * 负责设备发现、连接管理和状态监控
 */
export class DistributedDeviceManager {
  private static instance: DistributedDeviceManager;
  private ddmInstance: distributedDeviceManager.DeviceManager | null = null;
  private localDeviceInfo: DeviceInfo | null = null;
  private trustedDevices: DeviceInfo[] = [];
  private deviceChangeCallback: ((devices: DeviceInfo[]) => void) | null = null;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): DistributedDeviceManager {
    if (!DistributedDeviceManager.instance) {
      DistributedDeviceManager.instance = new DistributedDeviceManager();
    }
    return DistributedDeviceManager.instance;
  }

  /**
   * 初始化分布式设备管理器
   * @param appId 应用ID
   * @returns Promise<boolean> 初始化结果
   */
  public async init(appId: string): Promise<boolean> {
    try {
      // 创建设备管理器实例
      this.ddmInstance = distributedDeviceManager.createDeviceManager(appId);
      
      // 获取本地设备信息
      await this.getLocalDeviceInfo();
      
      // 注册设备状态变化监听
      this.registerDeviceListener();
      
      // 获取可信设备列表
      await this.refreshTrustedDevices();
      
      console.info('DistributedDeviceManager initialized successfully');
      return true;
    } catch (error) {
      console.error('Failed to initialize DistributedDeviceManager:', error);
      return false;
    }
  }

  /**
   * 获取本地设备信息
   */
  private async getLocalDeviceInfo(): Promise<void> {
    if (!this.ddmInstance) {
      throw new Error('DeviceManager not initialized');
    }

    try {
      const localDevice = this.ddmInstance.getLocalDevice();
      this.localDeviceInfo = {
        deviceId: localDevice.deviceId,
        deviceName: localDevice.deviceName,
        deviceType: this.mapDeviceType(localDevice.deviceType),
        isOnline: true,
        connectTime: Date.now(),
        batteryLevel: 80, // 模拟值
        signalStrength: 90 // 模拟值
      };
      console.info('Local device info:', this.localDeviceInfo);
    } catch (error) {
      console.error('Failed to get local device info:', error);
      throw error;
    }
  }

  /**
   * 映射设备类型
   */
  private mapDeviceType(deviceType: distributedDeviceManager.DeviceType): DeviceType {
    switch (deviceType) {
      case distributedDeviceManager.DeviceType.LOCAL:
        return DeviceType.PHONE; // 默认映射为PHONE
      case distributedDeviceManager.DeviceType.UNKNOWN:
      default:
        return DeviceType.PHONE;
    }
  }

  /**
   * 注册设备状态变化监听
   */
  private registerDeviceListener(): void {
    if (!this.ddmInstance) return;

    try {
      // 监听可信设备上线
      this.ddmInstance.on('trustDeviceOnline', (data) => {
        console.info('Device online:', data);
        this.handleDeviceOnline(data);
      });

      // 监听可信设备下线
      this.ddmInstance.on('trustDeviceOffline', (data) => {
        console.info('Device offline:', data);
        this.handleDeviceOffline(data);
      });

      // 监听设备信息变化
      this.ddmInstance.on('deviceChanged', (data) => {
        console.info('Device changed:', data);
        this.handleDeviceChanged(data);
      });
    } catch (error) {
      console.error('Failed to register device listener:', error);
    }
  }

  /**
   * 刷新可信设备列表
   */
  private async refreshTrustedDevices(): Promise<void> {
    if (!this.ddmInstance) return;

    try {
      const devices = this.ddmInstance.getTrustedDeviceListSync();
      this.trustedDevices = devices.map(device => ({
        deviceId: device.deviceId,
        deviceName: device.deviceName,
        deviceType: this.mapDeviceType(device.deviceType),
        isOnline: device.isOnline,
        connectTime: Date.now(),
        batteryLevel: Math.floor(Math.random() * 40) + 60, // 60-100%
        signalStrength: Math.floor(Math.random() * 30) + 70 // 70-100%
      }));
      
      console.info('Trusted devices refreshed:', this.trustedDevices.length);
      
      // 通知设备列表变化
      if (this.deviceChangeCallback) {
        this.deviceChangeCallback(this.trustedDevices);
      }
    } catch (error) {
      console.error('Failed to refresh trusted devices:', error);
    }
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
      connectTime: Date.now(),
      batteryLevel: Math.floor(Math.random() * 40) + 60,
      signalStrength: Math.floor(Math.random() * 30) + 70
    };

    // 添加到可信设备列表
    const existingIndex = this.trustedDevices.findIndex(d => d.deviceId === deviceInfo.deviceId);
    if (existingIndex >= 0) {
      this.trustedDevices[existingIndex] = deviceInfo;
    } else {
      this.trustedDevices.push(deviceInfo);
    }

    // 通知回调
    if (this.deviceChangeCallback) {
      this.deviceChangeCallback(this.trustedDevices);
    }
  }

  /**
   * 处理设备下线事件
   */
  private handleDeviceOffline(device: distributedDeviceManager.DeviceBasicInfo): void {
    const index = this.trustedDevices.findIndex(d => d.deviceId === device.deviceId);
    if (index >= 0) {
      this.trustedDevices[index].isOnline = false;
      
      if (this.deviceChangeCallback) {
        this.deviceChangeCallback(this.trustedDevices);
      }
    }
  }

  /**
   * 处理设备信息变化
   */
  private handleDeviceChanged(device: distributedDeviceManager.DeviceBasicInfo): void {
    const index = this.trustedDevices.findIndex(d => d.deviceId === device.deviceId);
    if (index >= 0) {
      this.trustedDevices[index].deviceName = device.deviceName;
      this.trustedDevices[index].isOnline = device.isOnline;
      
      if (this.deviceChangeCallback) {
        this.deviceChangeCallback(this.trustedDevices);
      }
    }
  }

  /**
   * 获取本地设备信息
   */
  public getLocalDevice(): DeviceInfo | null {
    return this.localDeviceInfo;
  }

  /**
   * 获取可信设备列表
   */
  public getTrustedDevices(): DeviceInfo[] {
    return [...this.trustedDevices];
  }

  /**
   * 根据设备类型筛选设备
   */
  public getDevicesByType(deviceType: DeviceType): DeviceInfo[] {
    return this.trustedDevices.filter(device => device.deviceType === deviceType);
  }

  /**
   * 查找特定设备
   */
  public findDevice(deviceId: string): DeviceInfo | undefined {
    return this.trustedDevices.find(device => device.deviceId === deviceId);
  }

  /**
   * 设置设备列表变化回调
   */
  public setDeviceChangeListener(callback: (devices: DeviceInfo[]) => void): void {
    this.deviceChangeCallback = callback;
  }

  /**
   * 清理资源
   */
  public destroy(): void {
    if (this.ddmInstance) {
      try {
        // 移除监听器
        this.ddmInstance.off('trustDeviceOnline');
        this.ddmInstance.off('trustDeviceOffline');
        this.ddmInstance.off('deviceChanged');
        
        // 销毁实例
        distributedDeviceManager.destroyDeviceManager(this.ddmInstance);
        this.ddmInstance = null;
      } catch (error) {
        console.error('Failed to destroy DeviceManager:', error);
      }
    }
    
    this.localDeviceInfo = null;
    this.trustedDevices = [];
    this.deviceChangeCallback = null;
    console.info('DistributedDeviceManager destroyed');
  }
}