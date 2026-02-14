/**
 * 车辆数据模拟器
 * 
 * 功能描述：
 * 1. 定时生成车辆状态数据（油量、胎压、车速）
 * 2. 提供数据订阅和通知机制
 * 3. 支持外部控制指令响应
 * 
 * @author 车载多设备协同助手项目组
 * @version 1.0.0
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 车辆状态数据接口
 */
export interface VehicleData {
  fuelLevel: number;        // 油量百分比 (0-100)
  tirePressure: number;     // 胎压 (bar)
  speed: number;           // 车速 (km/h)
  engineStatus: boolean;   // 发动机状态
  updateTime: number;      // 更新时间戳
}

/**
 * 数据变更回调函数类型
 */
export type DataUpdateCallback = (data: VehicleData) => void;

/**
 * 车辆数据模拟器类
 */
export class VehicleDataSimulator {
  // 单例实例
  private static instance: VehicleDataSimulator | null = null;
  
  // 私有属性
  private readonly TAG: string = 'VehicleDataSimulator';
  private vehicleData: VehicleData = this.getDefaultData();
  private callbacks: Set<DataUpdateCallback> = new Set();
  private simulationTimer: number | null = null;
  private isSimulating: boolean = false;
  
  // 模拟参数
  private readonly SIMULATION_INTERVAL: number = 1000; // 1秒更新间隔
  private readonly FUEL_CONSUMPTION_RATE: number = 0.01; // 每秒油耗
  private readonly SPEED_VARIATION: number = 5; // 速度随机变化范围
  
  /**
   * 私有构造函数
   */
  private constructor() {
    this.initializeSimulation();
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): VehicleDataSimulator {
    if (!VehicleDataSimulator.instance) {
      VehicleDataSimulator.instance = new VehicleDataSimulator();
    }
    return VehicleDataSimulator.instance;
  }
  
  /**
   * 初始化模拟数据
   */
  private initializeSimulation(): void {
    this.vehicleData = this.getDefaultData();
    hilog.info(0x0000, this.TAG, 'Vehicle data simulator initialized');
  }
  
  /**
   * 获取默认车辆数据
   */
  private getDefaultData(): VehicleData {
    return {
      fuelLevel: 85,        // 85%油量
      tirePressure: 2.35,   // 2.35bar胎压
      speed: 60,            // 60km/h车速
      engineStatus: true,   // 发动机开启
      updateTime: Date.now()
    };
  }
  
  /**
   * 开始数据模拟
   */
  public startSimulation(): void {
    if (this.isSimulating) {
      hilog.warn(0x0000, this.TAG, 'Simulation already running');
      return;
    }
    
    this.isSimulating = true;
    this.simulationTimer = setInterval(() => {
      this.generateNextData();
    }, this.SIMULATION_INTERVAL);
    
    hilog.info(0x0000, this.TAG, 'Vehicle data simulation started');
  }
  
  /**
   * 停止数据模拟
   */
  public stopSimulation(): void {
    if (this.simulationTimer) {
      clearInterval(this.simulationTimer);
      this.simulationTimer = null;
    }
    this.isSimulating = false;
    hilog.info(0x0000, this.TAG, 'Vehicle data simulation stopped');
  }
  
  /**
   * 生成下一帧数据
   */
  private generateNextData(): void {
    // 模拟油量消耗
    if (this.vehicleData.engineStatus && this.vehicleData.fuelLevel > 0) {
      this.vehicleData.fuelLevel = Math.max(0, 
        this.vehicleData.fuelLevel - this.FUEL_CONSUMPTION_RATE);
    }
    
    // 模拟车速变化
    const speedChange = (Math.random() - 0.5) * this.SPEED_VARIATION;
    this.vehicleData.speed = Math.max(0, Math.min(120, 
      this.vehicleData.speed + speedChange));
    
    // 模拟胎压微小波动
    const pressureChange = (Math.random() - 0.5) * 0.02;
    this.vehicleData.tirePressure = Math.max(2.2, Math.min(2.5, 
      this.vehicleData.tirePressure + pressureChange));
    
    // 更新时间戳
    this.vehicleData.updateTime = Date.now();
    
    // 通知所有订阅者
    this.notifySubscribers();
  }
  
  /**
   * 通知数据订阅者
   */
  private notifySubscribers(): void {
    this.callbacks.forEach(callback => {
      try {
        callback({...this.vehicleData}); // 传递副本避免外部修改
      } catch (error) {
        hilog.error(0x0000, this.TAG, 'Error in data callback: %{public}s', JSON.stringify(error));
      }
    });
  }
  
  /**
   * 订阅数据更新
   */
  public subscribe(callback: DataUpdateCallback): void {
    this.callbacks.add(callback);
    hilog.info(0x0000, this.TAG, 'Subscription added, total subscribers: %{public}d', this.callbacks.size);
  }
  
  /**
   * 取消订阅
   */
  public unsubscribe(callback: DataUpdateCallback): void {
    this.callbacks.delete(callback);
    hilog.info(0x0000, this.TAG, 'Subscription removed, remaining subscribers: %{public}d', this.callbacks.size);
  }
  
  /**
   * 获取当前车辆数据
   */
  public getCurrentData(): VehicleData {
    return {...this.vehicleData};
  }
  
  /**
   * 手动更新车辆数据（响应外部指令）
   */
  public updateData(updates: Partial<VehicleData>): void {
    this.vehicleData = {
      ...this.vehicleData,
      ...updates,
      updateTime: Date.now()
    };
    
    // 立即通知更新
    this.notifySubscribers();
    hilog.info(0x0000, this.TAG, 'Vehicle data manually updated: %{public}s', JSON.stringify(updates));
  }
  
  /**
   * 重置车辆数据
   */
  public reset(): void {
    this.stopSimulation();
    this.vehicleData = this.getDefaultData();
    this.notifySubscribers();
    hilog.info(0x0000, this.TAG, 'Vehicle data reset to default values');
  }
  
  /**
   * 检查是否正在模拟
   */
  public isRunning(): boolean {
    return this.isSimulating;
  }
  
  /**
   * 清理资源
   */
  public destroy(): void {
    this.stopSimulation();
    this.callbacks.clear();
    VehicleDataSimulator.instance = null;
    hilog.info(0x0000, this.TAG, 'Vehicle data simulator destroyed');
  }
}