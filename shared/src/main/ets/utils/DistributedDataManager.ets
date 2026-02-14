/**
 * 分布式数据管理工具类
 * 
 * 功能描述：
 * 1. 封装分布式KV存储，实现单例模式
 * 2. 支持车辆状态数据的存储、读取、监听
 * 3. 处理设备连接断开时的数据同步逻辑
 * 4. 保证多端数据一致性
 * 
 * 适用场景：手机端、车机端、手表端统一调用
 * 开发环境：DevEco Studio 模拟器
 * 
 * @author 车载多设备协同助手项目组
 * @version 1.0.0
 * @since 2024-02-14
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { distributedObject } from '@kit.DistributedServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 车辆状态数据接口定义
 */
export interface VehicleStatusData {
  // 基础车辆信息
  fuelLevel: number;          // 油量百分比 (0-100)
  tirePressure: number;       // 胎压 (kPa)
  speed: number;             // 车速 (km/h)
  acTemperature: number;     // 空调温度 (℃)
  navigationDestination: string; // 导航目的地
  
  // 系统信息
  lastUpdateTime: number;    // 最后更新时间戳
  deviceId: string;          // 数据来源设备ID
  isSynced: boolean;         // 是否已同步
}

/**
 * 数据变更回调函数类型
 */
export type DataChangeListener = (data: VehicleStatusData) => void;

/**
 * 设备连接状态枚举
 */
export enum DeviceConnectionStatus {
  CONNECTED = 'connected',
  DISCONNECTED = 'disconnected',
  SYNCING = 'syncing'
}

/**
 * 分布式数据管理工具类
 * 单例模式实现，确保全局唯一实例
 */
export class DistributedDataManager {
  // 单例实例
  private static instance: DistributedDataManager | null = null;
  
  // 私有属性
  private readonly TAG: string = 'DistributedDataManager';
  private readonly APP_ID: string = 'com.example.wanwuhulian';
  private readonly SESSION_ID: string = 'vehicle_assistant_session';
  private readonly GROUP_NAME: string = 'vehicle_data_group';
  
  // 分布式对象引用
  private distributedObj: distributedObject.DistributedObject | null = null;
  
  // 数据缓存
  private localCache: VehicleStatusData = this.getDefaultVehicleData();
  
  // 监听器集合
  private dataChangeListeners: Set<DataChangeListener> = new Set();
  private connectionStatusListeners: Set<(status: DeviceConnectionStatus) => void> = new Set();
  
  // 连接状态
  private connectionStatus: DeviceConnectionStatus = DeviceConnectionStatus.DISCONNECTED;
  
  // 同步队列
  private syncQueue: VehicleStatusData[] = [];
  private isSyncing: boolean = false;
  
  /**
   * 私有构造函数，防止外部直接实例化
   */
  private constructor() {
    this.initializeDefaultData();
  }
  
  /**
   * 获取单例实例
   * @returns DistributedDataManager 单例实例
   */
  public static getInstance(): DistributedDataManager {
    if (!DistributedDataManager.instance) {
      DistributedDataManager.instance = new DistributedDataManager();
    }
    return DistributedDataManager.instance;
  }
  
  /**
   * 初始化分布式数据管理器
   * @param deviceId 设备ID
   * @returns Promise<boolean> 初始化结果
   */
  public async init(deviceId: string): Promise<boolean> {
    try {
      hilog.info(0x0000, this.TAG, 'Initializing DistributedDataManager for device: %{public}s', deviceId);
      
      // 创建分布式对象
      this.distributedObj = await distributedObject.createDistributedObject({
        sessionId: `${this.SESSION_ID}_${deviceId}`,
        groupName: this.GROUP_NAME,
        objectName: 'vehicle_status_object',
        fields: {
          fuelLevel: 80,
          tirePressure: 220,
          speed: 0,
          acTemperature: 22,
          navigationDestination: '',
          lastUpdateTime: Date.now(),
          deviceId: deviceId,
          isSynced: false
        }
      });
      
      // 注册数据变更监听
      this.registerDataListeners();
      
      // 设置初始连接状态
      this.updateConnectionStatus(DeviceConnectionStatus.CONNECTED);
      
      hilog.info(0x0000, this.TAG, 'DistributedDataManager initialized successfully');
      return true;
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to initialize DistributedDataManager: %{public}s', JSON.stringify(error));
      return false;
    }
  }
  
  /**
   * 存储车辆状态数据
   * @param data 车辆状态数据
   * @returns Promise<boolean> 存储结果
   */
  public async storeVehicleData(data: Partial<VehicleStatusData>): Promise<boolean> {
    try {
      // 合并数据
      const mergedData: VehicleStatusData = {
        ...this.localCache,
        ...data,
        lastUpdateTime: Date.now(),
        isSynced: false
      };
      
      // 更新本地缓存
      this.localCache = mergedData;
      
      // 异步同步到分布式存储
      this.enqueueSync(mergedData);
      
      // 通知本地监听器
      this.notifyDataChangeListeners(mergedData);
      
      hilog.info(0x0000, this.TAG, 'Vehicle data stored locally: %{public}s', JSON.stringify({
        fuelLevel: mergedData.fuelLevel,
        speed: mergedData.speed,
        acTemperature: mergedData.acTemperature
      }));
      
      return true;
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to store vehicle data: %{public}s', JSON.stringify(error));
      return false;
    }
  }
  
  /**
   * 读取车辆状态数据
   * @returns Promise<VehicleStatusData> 车辆状态数据
   */
  public async readVehicleData(): Promise<VehicleStatusData> {
    try {
      // 优先从分布式对象读取最新数据
      if (this.distributedObj) {
        const remoteData = await this.distributedObj.get();
        if (remoteData && remoteData.lastUpdateTime > this.localCache.lastUpdateTime) {
          const syncedData: VehicleStatusData = {
            fuelLevel: remoteData.fuelLevel || 80,
            tirePressure: remoteData.tirePressure || 220,
            speed: remoteData.speed || 0,
            acTemperature: remoteData.acTemperature || 22,
            navigationDestination: remoteData.navigationDestination || '',
            lastUpdateTime: remoteData.lastUpdateTime || Date.now(),
            deviceId: remoteData.deviceId || '',
            isSynced: true
          };
          
          // 更新本地缓存
          this.localCache = syncedData;
          this.notifyDataChangeListeners(syncedData);
          
          hilog.info(0x0000, this.TAG, 'Vehicle data synchronized from remote storage');
          return syncedData;
        }
      }
      
      // 返回本地缓存数据
      hilog.info(0x0000, this.TAG, 'Returning local cached vehicle data');
      return { ...this.localCache };
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to read vehicle data: %{public}s', JSON.stringify(error));
      return { ...this.localCache };
    }
  }
  
  /**
   * 监听数据变更
   * @param listener 数据变更回调函数
   */
  public onDataChanged(listener: DataChangeListener): void {
    this.dataChangeListeners.add(listener);
    hilog.info(0x0000, this.TAG, 'Data change listener added, total listeners: %{public}d', this.dataChangeListeners.size);
  }
  
  /**
   * 移除数据变更监听
   * @param listener 数据变更回调函数
   */
  public removeDataListener(listener: DataChangeListener): void {
    this.dataChangeListeners.delete(listener);
    hilog.info(0x0000, this.TAG, 'Data change listener removed, remaining listeners: %{public}d', this.dataChangeListeners.size);
  }
  
  /**
   * 监听连接状态变更
   * @param listener 连接状态变更回调函数
   */
  public onConnectionStatusChanged(listener: (status: DeviceConnectionStatus) => void): void {
    this.connectionStatusListeners.add(listener);
    hilog.info(0x0000, this.TAG, 'Connection status listener added');
  }
  
  /**
   * 移除连接状态监听
   * @param listener 连接状态变更回调函数
   */
  public removeConnectionListener(listener: (status: DeviceConnectionStatus) => void): void {
    this.connectionStatusListeners.delete(listener);
    hilog.info(0x0000, this.TAG, 'Connection status listener removed');
  }
  
  /**
   * 获取当前连接状态
   * @returns DeviceConnectionStatus 当前连接状态
   */
  public getConnectionStatus(): DeviceConnectionStatus {
    return this.connectionStatus;
  }
  
  /**
   * 强制同步数据
   * @returns Promise<boolean> 同步结果
   */
  public async forceSync(): Promise<boolean> {
    try {
      hilog.info(0x0000, this.TAG, 'Forcing data synchronization');
      this.updateConnectionStatus(DeviceConnectionStatus.SYNCING);
      
      const currentData = await this.readVehicleData();
      const result = await this.syncToRemote(currentData);
      
      this.updateConnectionStatus(result ? DeviceConnectionStatus.CONNECTED : DeviceConnectionStatus.DISCONNECTED);
      return result;
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Force sync failed: %{public}s', JSON.stringify(error));
      this.updateConnectionStatus(DeviceConnectionStatus.DISCONNECTED);
      return false;
    }
  }
  
  /**
   * 清理资源
   */
  public async destroy(): Promise<void> {
    try {
      hilog.info(0x0000, this.TAG, 'Destroying DistributedDataManager');
      
      // 清理监听器
      this.dataChangeListeners.clear();
      this.connectionStatusListeners.clear();
      
      // 销毁分布式对象
      if (this.distributedObj) {
        await distributedObject.destroyDistributedObject(this.distributedObj);
        this.distributedObj = null;
      }
      
      // 清空同步队列
      this.syncQueue = [];
      this.isSyncing = false;
      
      // 重置连接状态
      this.updateConnectionStatus(DeviceConnectionStatus.DISCONNECTED);
      
      // 清空单例实例
      DistributedDataManager.instance = null;
      
      hilog.info(0x0000, this.TAG, 'DistributedDataManager destroyed successfully');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to destroy DistributedDataManager: %{public}s', JSON.stringify(error));
    }
  }
  
  // ==================== 私有方法 ====================
  
  /**
   * 初始化默认数据
   */
  private initializeDefaultData(): void {
    this.localCache = this.getDefaultVehicleData();
    hilog.info(0x0000, this.TAG, 'Default vehicle data initialized');
  }
  
  /**
   * 获取默认车辆数据
   * @returns VehicleStatusData 默认数据
   */
  private getDefaultVehicleData(): VehicleStatusData {
    return {
      fuelLevel: 80,
      tirePressure: 220,
      speed: 0,
      acTemperature: 22,
      navigationDestination: '',
      lastUpdateTime: Date.now(),
      deviceId: 'unknown',
      isSynced: false
    };
  }
  
  /**
   * 注册数据监听器
   */
  private registerDataListeners(): void {
    if (!this.distributedObj) return;
    
    try {
      this.distributedObj.on('dataChange', (data) => {
        hilog.info(0x0000, this.TAG, 'Remote data changed detected');
        const vehicleData: VehicleStatusData = {
          fuelLevel: data.fuelLevel || 80,
          tirePressure: data.tirePressure || 220,
          speed: data.speed || 0,
          acTemperature: data.acTemperature || 22,
          navigationDestination: data.navigationDestination || '',
          lastUpdateTime: data.lastUpdateTime || Date.now(),
          deviceId: data.deviceId || '',
          isSynced: true
        };
        
        this.localCache = vehicleData;
        this.notifyDataChangeListeners(vehicleData);
      });
      
      hilog.info(0x0000, this.TAG, 'Data listeners registered successfully');
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to register data listeners: %{public}s', JSON.stringify(error));
    }
  }
  
  /**
   * 通知数据变更监听器
   * @param data 变更后的数据
   */
  private notifyDataChangeListeners(data: VehicleStatusData): void {
    this.dataChangeListeners.forEach(listener => {
      try {
        listener(data);
      } catch (error) {
        hilog.error(0x0000, this.TAG, 'Error in data change listener: %{public}s', JSON.stringify(error));
      }
    });
  }
  
  /**
   * 更新连接状态
   * @param status 新的连接状态
   */
  private updateConnectionStatus(status: DeviceConnectionStatus): void {
    if (this.connectionStatus !== status) {
      this.connectionStatus = status;
      hilog.info(0x0000, this.TAG, 'Connection status updated to: %{public}s', status);
      
      // 通知连接状态监听器
      this.connectionStatusListeners.forEach(listener => {
        try {
          listener(status);
        } catch (error) {
          hilog.error(0x0000, this.TAG, 'Error in connection status listener: %{public}s', JSON.stringify(error));
        }
      });
    }
  }
  
  /**
   * 将数据加入同步队列
   * @param data 待同步的数据
   */
  private enqueueSync(data: VehicleStatusData): void {
    this.syncQueue.push(data);
    this.processSyncQueue();
  }
  
  /**
   * 处理同步队列
   */
  private async processSyncQueue(): Promise<void> {
    if (this.isSyncing || this.syncQueue.length === 0) {
      return;
    }
    
    this.isSyncing = true;
    
    try {
      while (this.syncQueue.length > 0) {
        const data = this.syncQueue.shift();
        if (data) {
          await this.syncToRemote(data);
        }
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Sync queue processing failed: %{public}s', JSON.stringify(error));
    } finally {
      this.isSyncing = false;
    }
  }
  
  /**
   * 同步数据到远程存储
   * @param data 待同步的数据
   * @returns Promise<boolean> 同步结果
   */
  private async syncToRemote(data: VehicleStatusData): Promise<boolean> {
    try {
      if (!this.distributedObj) {
        hilog.warn(0x0000, this.TAG, 'Distributed object not available for sync');
        return false;
      }
      
      await this.distributedObj.set({
        fuelLevel: data.fuelLevel,
        tirePressure: data.tirePressure,
        speed: data.speed,
        acTemperature: data.acTemperature,
        navigationDestination: data.navigationDestination,
        lastUpdateTime: data.lastUpdateTime,
        deviceId: data.deviceId,
        isSynced: true
      });
      
      hilog.info(0x0000, this.TAG, 'Data synced to remote storage successfully');
      return true;
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to sync data to remote: %{public}s', JSON.stringify(error));
      return false;
    }
  }
}

// ==================== 导出类型定义 ====================
export { VehicleStatusData, DataChangeListener, DeviceConnectionStatus };