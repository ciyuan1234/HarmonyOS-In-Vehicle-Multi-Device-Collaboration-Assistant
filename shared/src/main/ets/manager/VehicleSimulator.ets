import { VehicleStatus } from '../model/DeviceModel';

/**
 * 车辆数据模拟引擎
 * 模拟真实的车辆状态数据，包括速度、燃油、温度等
 */
export class VehicleSimulator {
  private static instance: VehicleSimulator;
  private vehicleStatus: VehicleStatus = {
    speed: 0,
    engineStatus: false,
    fuelLevel: 80,
    temperature: 22,
    doorLocked: true,
    latitude: 39.9042,    // 北京坐标
    longitude: 116.4074,
    updateTime: Date.now()
  };

  private simulationTimer: number | null = null;
  private statusChangeCallback: ((status: VehicleStatus) => void) | null = null;
  private isSimulating: boolean = false;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): VehicleSimulator {
    if (!VehicleSimulator.instance) {
      VehicleSimulator.instance = new VehicleSimulator();
    }
    return VehicleSimulator.instance;
  }

  /**
   * 开始车辆状态模拟
   * @param interval 更新间隔(ms)，默认1000ms
   */
  public startSimulation(interval: number = 1000): void {
    if (this.isSimulating) {
      console.warn('Vehicle simulation is already running');
      return;
    }

    this.isSimulating = true;
    
    // 立即更新一次状态
    this.updateVehicleStatus();
    
    // 启动定时器
    this.simulationTimer = setInterval(() => {
      this.updateVehicleStatus();
    }, interval);

    console.info(`Vehicle simulation started with interval ${interval}ms`);
  }

  /**
   * 停止车辆状态模拟
   */
  public stopSimulation(): void {
    if (this.simulationTimer) {
      clearInterval(this.simulationTimer);
      this.simulationTimer = null;
    }
    this.isSimulating = false;
    console.info('Vehicle simulation stopped');
  }

  /**
   * 更新车辆状态
   */
  private updateVehicleStatus(): void {
    // 模拟车速变化（0-120 km/h）
    if (this.vehicleStatus.engineStatus) {
      const speedChange = (Math.random() - 0.5) * 10;
      this.vehicleStatus.speed = Math.max(0, Math.min(120, this.vehicleStatus.speed + speedChange));
    } else {
      this.vehicleStatus.speed = 0;
    }

    // 模拟燃油消耗
    if (this.vehicleStatus.engineStatus && this.vehicleStatus.speed > 0) {
      this.vehicleStatus.fuelLevel = Math.max(0, this.vehicleStatus.fuelLevel - 0.01);
    }

    // 模拟车内温度变化
    const tempChange = (Math.random() - 0.5) * 2;
    this.vehicleStatus.temperature = Math.max(15, Math.min(35, this.vehicleStatus.temperature + tempChange));

    // 模拟地理位置微小移动
    if (this.vehicleStatus.speed > 0) {
      const latChange = (Math.random() - 0.5) * 0.0001;
      const lonChange = (Math.random() - 0.5) * 0.0001;
      this.vehicleStatus.latitude += latChange;
      this.vehicleStatus.longitude += lonChange;
    }

    // 更新时间戳
    this.vehicleStatus.updateTime = Date.now();

    // 通知状态变化
    if (this.statusChangeCallback) {
      this.statusChangeCallback({...this.vehicleStatus});
    }
  }

  /**
   * 获取当前车辆状态
   */
  public getCurrentStatus(): VehicleStatus {
    return {...this.vehicleStatus};
  }

  /**
   * 设置车辆状态变化回调
   */
  public setStatusChangeListener(callback: (status: VehicleStatus) => void): void {
    this.statusChangeCallback = callback;
  }

  /**
   * 启动发动机
   */
  public startEngine(): void {
    this.vehicleStatus.engineStatus = true;
    this.vehicleStatus.updateTime = Date.now();
    console.info('Engine started');
    
    if (this.statusChangeCallback) {
      this.statusChangeCallback({...this.vehicleStatus});
    }
  }

  /**
   * 停止发动机
   */
  public stopEngine(): void {
    this.vehicleStatus.engineStatus = false;
    this.vehicleStatus.speed = 0;
    this.vehicleStatus.updateTime = Date.now();
    console.info('Engine stopped');
    
    if (this.statusChangeCallback) {
      this.statusChangeCallback({...this.vehicleStatus});
    }
  }

  /**
   * 锁车门
   */
  public lockDoor(): void {
    this.vehicleStatus.doorLocked = true;
    this.vehicleStatus.updateTime = Date.now();
    console.info('Door locked');
    
    if (this.statusChangeCallback) {
      this.statusChangeCallback({...this.vehicleStatus});
    }
  }

  /**
   * 解锁车门
   */
  public unlockDoor(): void {
    this.vehicleStatus.doorLocked = false;
    this.vehicleStatus.updateTime = Date.now();
    console.info('Door unlocked');
    
    if (this.statusChangeCallback) {
      this.statusChangeCallback({...this.vehicleStatus});
    }
  }

  /**
   * 设置空调温度
   */
  public setTemperature(temp: number): void {
    this.vehicleStatus.temperature = Math.max(15, Math.min(35, temp));
    this.vehicleStatus.updateTime = Date.now();
    console.info(`Temperature set to ${temp}°C`);
    
    if (this.statusChangeCallback) {
      this.statusChangeCallback({...this.vehicleStatus});
    }
  }

  /**
   * 补充燃油
   */
  public refuel(amount: number = 20): void {
    this.vehicleStatus.fuelLevel = Math.min(100, this.vehicleStatus.fuelLevel + amount);
    this.vehicleStatus.updateTime = Date.now();
    console.info(`Refueled ${amount}%, current fuel: ${this.vehicleStatus.fuelLevel}%`);
    
    if (this.statusChangeCallback) {
      this.statusChangeCallback({...this.vehicleStatus});
    }
  }

  /**
   * 检查是否正在模拟
   */
  public isRunning(): boolean {
    return this.isSimulating;
  }

  /**
   * 重置车辆状态
   */
  public reset(): void {
    this.stopSimulation();
    this.vehicleStatus = {
      speed: 0,
      engineStatus: false,
      fuelLevel: 80,
      temperature: 22,
      doorLocked: true,
      latitude: 39.9042,
      longitude: 116.4074,
      updateTime: Date.now()
    };
    
    if (this.statusChangeCallback) {
      this.statusChangeCallback({...this.vehicleStatus});
    }
    
    console.info('Vehicle status reset');
  }

  /**
   * 清理资源
   */
  public destroy(): void {
    this.stopSimulation();
    this.statusChangeCallback = null;
    console.info('VehicleSimulator destroyed');
  }
}