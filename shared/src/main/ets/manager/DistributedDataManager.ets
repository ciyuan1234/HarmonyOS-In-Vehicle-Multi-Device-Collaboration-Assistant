import { BusinessError } from '@kit.BasicServicesKit';
import { distributedObject } from '@kit.DistributedServiceKit';
import { VehicleStatus, DeviceInfo, CommandParams } from '../model/DeviceModel';

/**
 * 分布式对象同步管理器
 * 负责跨设备的数据同步和状态共享
 */
export class DistributedDataManager {
  private static instance: DistributedDataManager;
  private sessionId: string = '';
  private appId: string = 'com.example.wanwuhulian';
  private groupName: string = 'vehicle_assistant_group';
  
  // 分布式对象引用
  private vehicleStatusObj: distributedObject.DistributedObject | null = null;
  private deviceInfoObj: distributedObject.DistributedObject | null = null;
  private commandQueueObj: distributedObject.DistributedObject | null = null;
  
  // 回调函数
  private vehicleStatusCallback: ((status: VehicleStatus) => void) | null = null;
  private deviceInfoCallback: ((devices: DeviceInfo[]) => void) | null = null;
  private commandCallback: ((command: CommandParams) => void) | null = null;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): DistributedDataManager {
    if (!DistributedDataManager.instance) {
      DistributedDataManager.instance = new DistributedDataManager();
    }
    return DistributedDataManager.instance;
  }

  /**
   * 初始化分布式数据同步
   * @param localDeviceId 本地设备ID
   * @returns Promise<boolean> 初始化结果
   */
  public async init(localDeviceId: string): Promise<boolean> {
    try {
      // 生成会话ID
      this.sessionId = `${this.appId}_${localDeviceId}_${Date.now()}`;
      
      // 创建分布式对象组
      await this.createDistributedObjects();
      
      console.info('DistributedDataManager initialized successfully');
      return true;
    } catch (error) {
      console.error('Failed to initialize DistributedDataManager:', error);
      return false;
    }
  }

  /**
   * 创建分布式对象
   */
  private async createDistributedObjects(): Promise<void> {
    try {
      // 创建车辆状态分布式对象
      this.vehicleStatusObj = await distributedObject.createDistributedObject({
        sessionId: this.sessionId,
        groupName: this.groupName,
        objectName: 'vehicle_status',
        fields: {
          speed: 0,
          engineStatus: false,
          fuelLevel: 80,
          temperature: 22,
          doorLocked: true,
          latitude: 39.9042,
          longitude: 116.4074,
          updateTime: Date.now()
        }
      });

      // 创建设备信息分布式对象
      this.deviceInfoObj = await distributedObject.createDistributedObject({
        sessionId: this.sessionId,
        groupName: this.groupName,
        objectName: 'device_info',
        fields: {
          devices: [] as DeviceInfo[]
        }
      });

      // 创建命令队列分布式对象
      this.commandQueueObj = await distributedObject.createDistributedObject({
        sessionId: this.sessionId,
        groupName: this.groupName,
        objectName: 'command_queue',
        fields: {
          commands: [] as CommandParams[]
        }
      });

      // 注册数据变化监听
      this.registerDataListeners();
      
      console.info('Distributed objects created successfully');
    } catch (error) {
      console.error('Failed to create distributed objects:', error);
      throw error;
    }
  }

  /**
   * 注册数据变化监听器
   */
  private registerDataListeners(): void {
    if (this.vehicleStatusObj) {
      this.vehicleStatusObj.on('dataChange', (data) => {
        console.info('Vehicle status changed:', data);
        if (this.vehicleStatusCallback) {
          const status: VehicleStatus = {
            speed: data.speed || 0,
            engineStatus: data.engineStatus || false,
            fuelLevel: data.fuelLevel || 80,
            temperature: data.temperature || 22,
            doorLocked: data.doorLocked !== undefined ? data.doorLocked : true,
            latitude: data.latitude || 39.9042,
            longitude: data.longitude || 116.4074,
            updateTime: data.updateTime || Date.now()
          };
          this.vehicleStatusCallback(status);
        }
      });
    }

    if (this.deviceInfoObj) {
      this.deviceInfoObj.on('dataChange', (data) => {
        console.info('Device info changed:', data);
        if (this.deviceInfoCallback && data.devices) {
          this.deviceInfoCallback(data.devices as DeviceInfo[]);
        }
      });
    }

    if (this.commandQueueObj) {
      this.commandQueueObj.on('dataChange', (data) => {
        console.info('Command queue changed:', data);
        if (this.commandCallback && data.commands && data.commands.length > 0) {
          const latestCommand = data.commands[data.commands.length - 1] as CommandParams;
          this.commandCallback(latestCommand);
          
          // 清空已处理的命令
          this.clearProcessedCommands();
        }
      });
    }
  }

  /**
   * 更新车辆状态到分布式对象
   */
  public async updateVehicleStatus(status: VehicleStatus): Promise<void> {
    if (!this.vehicleStatusObj) {
      console.warn('Vehicle status object not initialized');
      return;
    }

    try {
      await this.vehicleStatusObj.set({
        speed: status.speed,
        engineStatus: status.engineStatus,
        fuelLevel: status.fuelLevel,
        temperature: status.temperature,
        doorLocked: status.doorLocked,
        latitude: status.latitude,
        longitude: status.longitude,
        updateTime: status.updateTime
      });
      console.info('Vehicle status updated to distributed object');
    } catch (error) {
      console.error('Failed to update vehicle status:', error);
    }
  }

  /**
   * 获取当前车辆状态
   */
  public async getVehicleStatus(): Promise<VehicleStatus | null> {
    if (!this.vehicleStatusObj) {
      console.warn('Vehicle status object not initialized');
      return null;
    }

    try {
      const data = await this.vehicleStatusObj.get();
      return {
        speed: data.speed || 0,
        engineStatus: data.engineStatus || false,
        fuelLevel: data.fuelLevel || 80,
        temperature: data.temperature || 22,
        doorLocked: data.doorLocked !== undefined ? data.doorLocked : true,
        latitude: data.latitude || 39.9042,
        longitude: data.longitude || 116.4074,
        updateTime: data.updateTime || Date.now()
      };
    } catch (error) {
      console.error('Failed to get vehicle status:', error);
      return null;
    }
  }

  /**
   * 更新设备信息列表
   */
  public async updateDeviceInfo(devices: DeviceInfo[]): Promise<void> {
    if (!this.deviceInfoObj) {
      console.warn('Device info object not initialized');
      return;
    }

    try {
      await this.deviceInfoObj.set({
        devices: devices
      });
      console.info('Device info updated to distributed object');
    } catch (error) {
      console.error('Failed to update device info:', error);
    }
  }

  /**
   * 获取设备信息列表
   */
  public async getDeviceInfo(): Promise<DeviceInfo[]> {
    if (!this.deviceInfoObj) {
      console.warn('Device info object not initialized');
      return [];
    }

    try {
      const data = await this.deviceInfoObj.get();
      return data.devices || [];
    } catch (error) {
      console.error('Failed to get device info:', error);
      return [];
    }
  }

  /**
   * 发送控制命令到分布式队列
   */
  public async sendCommand(command: CommandParams): Promise<boolean> {
    if (!this.commandQueueObj) {
      console.warn('Command queue object not initialized');
      return false;
    }

    try {
      // 获取现有命令队列
      const data = await this.commandQueueObj.get();
      const commands: CommandParams[] = data.commands || [];
      
      // 添加新命令
      commands.push(command);
      
      // 限制队列长度，只保留最近的10条命令
      if (commands.length > 10) {
        commands.splice(0, commands.length - 10);
      }
      
      // 更新分布式对象
      await this.commandQueueObj.set({
        commands: commands
      });
      
      console.info('Command sent to distributed queue:', command.command);
      return true;
    } catch (error) {
      console.error('Failed to send command:', error);
      return false;
    }
  }

  /**
   * 清空已处理的命令
   */
  private async clearProcessedCommands(): Promise<void> {
    if (!this.commandQueueObj) return;

    try {
      await this.commandQueueObj.set({
        commands: []
      });
    } catch (error) {
      console.error('Failed to clear processed commands:', error);
    }
  }

  /**
   * 设置车辆状态变化回调
   */
  public setVehicleStatusListener(callback: (status: VehicleStatus) => void): void {
    this.vehicleStatusCallback = callback;
  }

  /**
   * 设置设备信息变化回调
   */
  public setDeviceInfoListener(callback: (devices: DeviceInfo[]) => void): void {
    this.deviceInfoCallback = callback;
  }

  /**
   * 设置命令接收回调
   */
  public setCommandListener(callback: (command: CommandParams) => void): void {
    this.commandCallback = callback;
  }

  /**
   * 加入分布式组
   */
  public async joinGroup(groupId: string): Promise<boolean> {
    try {
      // 这里应该是加入分布式组的逻辑
      // 在实际实现中需要根据HarmonyOS的具体API调整
      console.info(`Joined distributed group: ${groupId}`);
      return true;
    } catch (error) {
      console.error('Failed to join group:', error);
      return false;
    }
  }

  /**
   * 离开分布式组
   */
  public async leaveGroup(groupId: string): Promise<boolean> {
    try {
      // 这里应该是离开分布式组的逻辑
      console.info(`Left distributed group: ${groupId}`);
      return true;
    } catch (error) {
      console.error('Failed to leave group:', error);
      return false;
    }
  }

  /**
   * 清理资源
   */
  public async destroy(): Promise<void> {
    try {
      // 移除监听器
      if (this.vehicleStatusObj) {
        this.vehicleStatusObj.off('dataChange');
      }
      if (this.deviceInfoObj) {
        this.deviceInfoObj.off('dataChange');
      }
      if (this.commandQueueObj) {
        this.commandQueueObj.off('dataChange');
      }

      // 销毁分布式对象
      if (this.vehicleStatusObj) {
        await distributedObject.destroyDistributedObject(this.vehicleStatusObj);
      }
      if (this.deviceInfoObj) {
        await distributedObject.destroyDistributedObject(this.deviceInfoObj);
      }
      if (this.commandQueueObj) {
        await distributedObject.destroyDistributedObject(this.commandQueueObj);
      }

      this.vehicleStatusObj = null;
      this.deviceInfoObj = null;
      this.commandQueueObj = null;
      this.vehicleStatusCallback = null;
      this.deviceInfoCallback = null;
      this.commandCallback = null;

      console.info('DistributedDataManager destroyed');
    } catch (error) {
      console.error('Failed to destroy DistributedDataManager:', error);
    }
  }
}