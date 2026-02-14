import { DeviceInfo, ControlCommand, CommandParams } from '../../model/DeviceModel';
import { VehicleAssistantManager } from '../manager/VehicleAssistantManager';
import { generateUUID } from '../utils/CommonUtils';

/**
 * 跨端任务流转管理器
 * 负责协调不同设备间的任务分发和状态同步
 */
export class CrossDeviceFlowManager {
  private static instance: CrossDeviceFlowManager;
  private vehicleManager: VehicleAssistantManager;
  
  // 任务队列
  private taskQueue: CommandParams[] = [];
  private pendingTasks: Map<string, CommandParams> = new Map();
  
  // 设备能力映射
  private deviceCapabilities: Map<string, string[]> = new Map();
  
  // 回调函数
  private taskCompleteListener: ((taskId: string, success: boolean) => void) | null = null;
  private deviceConnectListener: ((device: DeviceInfo) => void) | null = null;

  private constructor() {
    this.vehicleManager = VehicleAssistantManager.getInstance();
    this.initializeDeviceCapabilities();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): CrossDeviceFlowManager {
    if (!CrossDeviceFlowManager.instance) {
      CrossDeviceFlowManager.instance = new CrossDeviceFlowManager();
    }
    return CrossDeviceFlowManager.instance;
  }

  /**
   * 初始化设备能力映射
   */
  private initializeDeviceCapabilities(): void {
    // 手机端能力
    this.deviceCapabilities.set('phone', [
      'control_engine',
      'control_doors',
      'control_ac',
      'navigation',
      'music_control',
      'device_management'
    ]);
    
    // 车机端能力
    this.deviceCapabilities.set('car', [
      'display_dashboard',
      'control_media',
      'control_climate',
      'execute_commands',
      'status_monitoring'
    ]);
    
    // 手表端能力
    this.deviceCapabilities.set('watch', [
      'quick_actions',
      'status_display',
      'emergency_commands'
    ]);
  }

  /**
   * 初始化跨端流程管理
   */
  public async init(): Promise<boolean> {
    try {
      // 设置车辆管理器回调
      this.setupVehicleManagerCallbacks();
      
      console.info('CrossDeviceFlowManager initialized successfully');
      return true;
    } catch (error) {
      console.error('Failed to initialize CrossDeviceFlowManager:', error);
      return false;
    }
  }

  /**
   * 设置车辆管理器回调
   */
  private setupVehicleManagerCallbacks(): void {
    // 命令接收回调
    this.vehicleManager.setCommandReceivedListener((command) => {
      this.handleIncomingCommand(command);
    });
    
    // 设备列表变化回调
    this.vehicleManager.setDeviceListListener((devices) => {
      this.handleDeviceListChange(devices);
    });
  }

  /**
   * 处理传入命令
   */
  private handleIncomingCommand(command: CommandParams): void {
    console.info('Handling incoming command:', command.command);
    
    // 验证命令有效性
    if (!this.validateCommand(command)) {
      console.warn('Invalid command received:', command);
      return;
    }
    
    // 生成任务ID
    const taskId = generateUUID();
    command.params = command.params || {};
    command.params.taskId = taskId;
    
    // 添加到任务队列
    this.taskQueue.push(command);
    this.pendingTasks.set(taskId, command);
    
    // 执行任务路由
    this.routeTask(command);
    
    console.info('Command routed successfully, taskId:', taskId);
  }

  /**
   * 验证命令有效性
   */
  private validateCommand(command: CommandParams): boolean {
    // 检查必需字段
    if (!command.command || !command.timestamp) {
      return false;
    }
    
    // 检查时间戳是否合理（防止重放攻击）
    const now = Date.now();
    if (Math.abs(now - command.timestamp) > 300000) { // 5分钟内有效
      console.warn('Command timestamp expired:', command.timestamp);
      return false;
    }
    
    return true;
  }

  /**
   * 任务路由分发
   */
  private routeTask(command: CommandParams): void {
    const localDevice = this.vehicleManager.getLocalDevice();
    if (!localDevice) {
      console.warn('Local device not available');
      return;
    }
    
    // 根据命令类型和目标设备进行路由
    switch (command.command) {
      case ControlCommand.START_ENGINE:
      case ControlCommand.STOP_ENGINE:
      case ControlCommand.LOCK_DOOR:
      case ControlCommand.UNLOCK_DOOR:
        // 这些命令应该发送到车机端执行
        this.sendToCarDevice(command);
        break;
        
      case ControlCommand.OPEN_AC:
      case ControlCommand.CLOSE_AC:
      case ControlCommand.SET_TEMPERATURE:
        // 空调控制命令
        this.sendToCarDevice(command);
        break;
        
      case ControlCommand.PLAY_MUSIC:
      case ControlCommand.STOP_MUSIC:
        // 音乐控制命令
        this.sendToCarDevice(command);
        break;
        
      case ControlCommand.NAVIGATE_TO:
        // 导航命令可以发送到车机或手机
        if (localDevice.deviceType === 'car') {
          // 车机端直接处理
          this.executeOnCar(command);
        } else {
          // 其他设备转发到车机
          this.sendToCarDevice(command);
        }
        break;
        
      default:
        // 默认情况下广播到所有设备
        this.broadcastCommand(command);
    }
  }

  /**
   * 发送到车机设备
   */
  private sendToCarDevice(command: CommandParams): void {
    const carDevices = this.vehicleManager.getDevicesByType('car');
    
    if (carDevices.length > 0) {
      // 选择在线的车机设备
      const targetDevice = carDevices.find(device => device.isOnline);
      if (targetDevice) {
        command.deviceId = targetDevice.deviceId;
        this.vehicleManager.sendCommand(command.command, targetDevice.deviceId, command.params);
        console.info('Command sent to car device:', targetDevice.deviceName);
      } else {
        console.warn('No online car device available');
        this.handleTaskFailure(command, 'No online car device');
      }
    } else {
      console.warn('No car devices found');
      this.handleTaskFailure(command, 'No car devices available');
    }
  }

  /**
   * 在车机端执行命令
   */
  private executeOnCar(command: CommandParams): void {
    // 这里应该调用车机端的具体执行逻辑
    console.info('Executing command on car:', command.command);
    
    // 模拟执行结果
    setTimeout(() => {
      this.handleTaskCompletion(command, true);
    }, 1000);
  }

  /**
   * 广播命令到所有设备
   */
  private broadcastCommand(command: CommandParams): void {
    const allDevices = this.vehicleManager.getDeviceList();
    const localDevice = this.vehicleManager.getLocalDevice();
    
    allDevices.forEach(device => {
      // 不向自己发送命令
      if (localDevice && device.deviceId !== localDevice.deviceId) {
        this.vehicleManager.sendCommand(
          command.command, 
          device.deviceId, 
          { ...command.params, broadcast: true }
        );
      }
    });
    
    console.info('Command broadcasted to all devices');
  }

  /**
   * 处理设备列表变化
   */
  private handleDeviceListChange(devices: DeviceInfo[]): void {
    console.info('Device list changed, updating capabilities');
    
    devices.forEach(device => {
      if (device.isOnline && this.deviceConnectListener) {
        this.deviceConnectListener(device);
      }
    });
    
    // 清理离线设备的任务
    this.cleanupOfflineTasks(devices);
  }

  /**
   * 清理离线设备的任务
   */
  private cleanupOfflineTasks(currentDevices: DeviceInfo[]): void {
    const onlineDeviceIds = new Set(currentDevices
      .filter(device => device.isOnline)
      .map(device => device.deviceId));
    
    // 移除指向离线设备的待处理任务
    this.pendingTasks.forEach((command, taskId) => {
      if (command.deviceId && !onlineDeviceIds.has(command.deviceId)) {
        console.info('Cleaning up task for offline device:', taskId);
        this.handleTaskFailure(command, 'Target device offline');
        this.pendingTasks.delete(taskId);
      }
    });
  }

  /**
   * 处理任务完成
   */
  private handleTaskCompletion(command: CommandParams, success: boolean): void {
    const taskId = command.params?.taskId;
    if (taskId) {
      this.pendingTasks.delete(taskId);
      
      if (this.taskCompleteListener) {
        this.taskCompleteListener(taskId, success);
      }
      
      console.info('Task completed:', taskId, success ? 'SUCCESS' : 'FAILED');
    }
  }

  /**
   * 处理任务失败
   */
  private handleTaskFailure(command: CommandParams, reason: string): void {
    console.warn('Task failed:', command.command, reason);
    this.handleTaskCompletion(command, false);
  }

  /**
   * 获取设备能力
   */
  public getDeviceCapabilities(deviceType: string): string[] {
    return this.deviceCapabilities.get(deviceType) || [];
  }

  /**
   * 检查设备是否支持特定功能
   */
  public isDeviceCapable(deviceType: string, capability: string): boolean {
    const capabilities = this.deviceCapabilities.get(deviceType) || [];
    return capabilities.includes(capability);
  }

  /**
   * 获取待处理任务数量
   */
  public getPendingTaskCount(): number {
    return this.pendingTasks.size;
  }

  /**
   * 获取任务队列状态
   */
  public getTaskQueueStatus(): { 
    total: number; 
    pending: number; 
    queue: CommandParams[] 
  } {
    return {
      total: this.taskQueue.length,
      pending: this.pendingTasks.size,
      queue: [...this.taskQueue]
    };
  }

  /**
   * 设置任务完成监听器
   */
  public setTaskCompleteListener(listener: (taskId: string, success: boolean) => void): void {
    this.taskCompleteListener = listener;
  }

  /**
   * 设置设备连接监听器
   */
  public setDeviceConnectListener(listener: (device: DeviceInfo) => void): void {
    this.deviceConnectListener = listener;
  }

  /**
   * 清理资源
   */
  public destroy(): void {
    this.taskQueue = [];
    this.pendingTasks.clear();
    this.taskCompleteListener = null;
    this.deviceConnectListener = null;
    console.info('CrossDeviceFlowManager destroyed');
  }
}