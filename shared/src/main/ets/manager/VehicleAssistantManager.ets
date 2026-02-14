import { DistributedDeviceManager } from './DistributedDeviceManager';
import { VehicleSimulator } from './VehicleSimulator';
import { DistributedDataManager } from './DistributedDataManager';
import { CrossDeviceFlowManager } from './CrossDeviceFlowManager';
import { DeviceInfo, VehicleStatus, CommandParams, ControlCommand, DeviceType } from '../model/DeviceModel';

/**
 * 车载助手业务管理器
 * 统一管理分布式设备、车辆模拟和数据同步
 */
export class VehicleAssistantManager {
  private static instance: VehicleAssistantManager;
  
  private deviceManager: DistributedDeviceManager;
  private vehicleSimulator: VehicleSimulator;
  private dataManager: DistributedDataManager;
  private flowManager: CrossDeviceFlowManager;
  
  private isInitialized: boolean = false;
  private localDeviceId: string = '';

  // 业务回调
  private deviceListCallback: ((devices: DeviceInfo[]) => void) | null = null;
  private vehicleStatusCallback: ((status: VehicleStatus) => void) | null = null;
  private commandReceivedCallback: ((command: CommandParams) => void) | null = null;

  private constructor() {
    this.deviceManager = DistributedDeviceManager.getInstance();
    this.vehicleSimulator = VehicleSimulator.getInstance();
    this.dataManager = DistributedDataManager.getInstance();
    this.flowManager = CrossDeviceFlowManager.getInstance();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): VehicleAssistantManager {
    if (!VehicleAssistantManager.instance) {
      VehicleAssistantManager.instance = new VehicleAssistantManager();
    }
    return VehicleAssistantManager.instance;
  }

  /**
   * 初始化车载助手系统
   * @param appId 应用ID
   * @param localDeviceId 本地设备ID
   * @returns Promise<boolean> 初始化结果
   */
  public async init(appId: string, localDeviceId: string): Promise<boolean> {
    if (this.isInitialized) {
      console.warn('VehicleAssistantManager is already initialized');
      return true;
    }

    try {
      this.localDeviceId = localDeviceId;
      
      // 初始化各个子系统
      const deviceInit = await this.deviceManager.init(appId);
      const dataInit = await this.dataManager.init(localDeviceId);
      
      if (!deviceInit || !dataInit) {
        throw new Error('Failed to initialize subsystems');
      }

      // 初始化跨端流程管理
      await this.flowManager.init();
      
      // 设置回调监听
      this.setupCallbacks();
      
      // 启动车辆状态模拟（仅车机端）
      const localDevice = this.deviceManager.getLocalDevice();
      if (localDevice && localDevice.deviceType === DeviceType.CAR) {
        this.vehicleSimulator.startSimulation(2000); // 2秒更新一次
      }

      this.isInitialized = true;
      console.info('VehicleAssistantManager initialized successfully');
      return true;
    } catch (error) {
      console.error('Failed to initialize VehicleAssistantManager:', error);
      return false;
    }
  }

  /**
   * 设置各组件间的回调监听
   */
  private setupCallbacks(): void {
    // 设备列表变化回调
    this.deviceManager.setDeviceChangeListener((devices) => {
      console.info('Device list changed, updating distributed data');
      this.dataManager.updateDeviceInfo(devices);
      
      if (this.deviceListCallback) {
        this.deviceListCallback(devices);
      }
    });

    // 车辆状态变化回调
    this.vehicleSimulator.setStatusChangeListener((status) => {
      console.info('Vehicle status changed, syncing to distributed data');
      this.dataManager.updateVehicleStatus(status);
      
      if (this.vehicleStatusCallback) {
        this.vehicleStatusCallback(status);
      }
    });

    // 分布式命令接收回调
    this.dataManager.setCommandListener((command) => {
      console.info('Received command from distributed data:', command.command);
      this.handleReceivedCommand(command);
      
      if (this.commandReceivedCallback) {
        this.commandReceivedCallback(command);
      }
    });

    // 分布式车辆状态监听
    this.dataManager.setVehicleStatusListener((status) => {
      console.info('Vehicle status updated from distributed data');
      // 如果不是本机产生的状态更新，则更新本地显示
      if (this.vehicleStatusCallback) {
        this.vehicleStatusCallback(status);
      }
    });

    // 分布式设备信息监听
    this.dataManager.setDeviceInfoListener((devices) => {
      console.info('Device info updated from distributed data');
      if (this.deviceListCallback) {
        this.deviceListCallback(devices);
      }
    });
  }

  /**
   * 处理接收到的命令
   */
  private handleReceivedCommand(command: CommandParams): void {
    // 验证命令是否应该在本设备执行
    if (command.deviceId && command.deviceId !== this.localDeviceId) {
      console.info(`Command not for this device, ignoring: ${command.deviceId}`);
      return;
    }

    switch (command.command) {
      case ControlCommand.START_ENGINE:
        this.vehicleSimulator.startEngine();
        break;
      case ControlCommand.STOP_ENGINE:
        this.vehicleSimulator.stopEngine();
        break;
      case ControlCommand.LOCK_DOOR:
        this.vehicleSimulator.lockDoor();
        break;
      case ControlCommand.UNLOCK_DOOR:
        this.vehicleSimulator.unlockDoor();
        break;
      case ControlCommand.SET_TEMPERATURE:
        if (command.params && typeof command.params.temperature === 'number') {
          this.vehicleSimulator.setTemperature(command.params.temperature);
        }
        break;
      case ControlCommand.PLAY_MUSIC:
        console.info('Music play command received');
        // 音乐播放逻辑待实现
        break;
      case ControlCommand.STOP_MUSIC:
        console.info('Music stop command received');
        // 音乐停止逻辑待实现
        break;
      default:
        console.warn('Unknown command:', command.command);
    }
  }

  /**
   * 发送控制命令
   * @param command 命令类型
   * @param targetDeviceId 目标设备ID（可选）
   * @param params 命令参数（可选）
   * @returns Promise<boolean> 发送结果
   */
  public async sendCommand(
    command: ControlCommand, 
    targetDeviceId?: string, 
    params?: any
  ): Promise<boolean> {
    if (!this.isInitialized) {
      console.warn('VehicleAssistantManager not initialized');
      return false;
    }

    const commandParams: CommandParams = {
      command: command,
      deviceId: targetDeviceId,
      params: params,
      timestamp: Date.now()
    };

    console.info('Sending command:', command);
    return await this.dataManager.sendCommand(commandParams);
  }

  /**
   * 获取设备列表
   */
  public getDeviceList(): DeviceInfo[] {
    return this.deviceManager.getTrustedDevices();
  }

  /**
   * 根据类型获取设备
   */
  public getDevicesByType(deviceType: DeviceType): DeviceInfo[] {
    return this.deviceManager.getDevicesByType(deviceType);
  }

  /**
   * 获取当前车辆状态
   */
  public getCurrentVehicleStatus(): VehicleStatus {
    return this.vehicleSimulator.getCurrentStatus();
  }

  /**
   * 获取分布式车辆状态
   */
  public async getDistributedVehicleStatus(): Promise<VehicleStatus | null> {
    return await this.dataManager.getVehicleStatus();
  }

  /**
   * 设置设备列表变化回调
   */
  public setDeviceListListener(callback: (devices: DeviceInfo[]) => void): void {
    this.deviceListCallback = callback;
  }

  /**
   * 设置车辆状态变化回调
   */
  public setVehicleStatusListener(callback: (status: VehicleStatus) => void): void {
    this.vehicleStatusCallback = callback;
  }

  /**
   * 设置命令接收回调
   */
  public setCommandReceivedListener(callback: (command: CommandParams) => void): void {
    this.commandReceivedCallback = callback;
  }

  /**
   * 启动车辆模拟（手动控制）
   */
  public startVehicleSimulation(interval: number = 2000): void {
    if (this.isInitialized) {
      this.vehicleSimulator.startSimulation(interval);
    }
  }

  /**
   * 停止车辆模拟
   */
  public stopVehicleSimulation(): void {
    this.vehicleSimulator.stopSimulation();
  }

  /**
   * 重置系统状态
   */
  public reset(): void {
    this.vehicleSimulator.reset();
    console.info('VehicleAssistantManager reset');
  }

  /**
   * 检查系统是否已初始化
   */
  public isSystemReady(): boolean {
    return this.isInitialized;
  }

  /**
   * 获取本地设备信息
   */
  public getLocalDevice(): DeviceInfo | null {
    return this.deviceManager.getLocalDevice();
  }

  /**
   * 清理资源
   */
  public async destroy(): Promise<void> {
    try {
      // 停止车辆模拟
      this.vehicleSimulator.stopSimulation();
      
      // 销毁各子系统
      await this.dataManager.destroy();
      this.deviceManager.destroy();
      this.vehicleSimulator.destroy();
      
      this.isInitialized = false;
      this.deviceListCallback = null;
      this.vehicleStatusCallback = null;
      this.commandReceivedCallback = null;
      
      console.info('VehicleAssistantManager destroyed');
    } catch (error) {
      console.error('Failed to destroy VehicleAssistantManager:', error);
    }
  }
}