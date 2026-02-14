/**
 * 设备信息数据模型
 * 定义分布式设备的基本信息和状态
 */
export enum DeviceType {
  PHONE = 'phone',
  CAR = 'car', 
  WATCH = 'watch'
}

export interface DeviceInfo {
  deviceId: string;           // 设备唯一标识
  deviceName: string;         // 设备名称
  deviceType: DeviceType;     // 设备类型
  isOnline: boolean;          // 是否在线
  connectTime: number;        // 连接时间戳
  batteryLevel?: number;      // 电池电量(0-100)
  signalStrength?: number;    // 信号强度
}

/**
 * 车辆状态数据模型
 */
export interface VehicleStatus {
  speed: number;              // 车速(km/h)
  engineStatus: boolean;      // 发动机状态
  fuelLevel: number;          // 燃油量(0-100)
  temperature: number;        // 车内温度(℃)
  doorLocked: boolean;        // 车门锁定状态
  latitude: number;           // 纬度
  longitude: number;          // 经度
  updateTime: number;         // 更新时间戳
}

/**
 * 控制命令枚举
 */
export enum ControlCommand {
  START_ENGINE = 'start_engine',      // 启动发动机
  STOP_ENGINE = 'stop_engine',        // 停止发动机
  LOCK_DOOR = 'lock_door',            // 锁车门
  UNLOCK_DOOR = 'unlock_door',        // 解锁车门
  OPEN_AC = 'open_ac',                // 开启空调
  CLOSE_AC = 'close_ac',              // 关闭空调
  SET_TEMPERATURE = 'set_temperature', // 设置温度
  PLAY_MUSIC = 'play_music',          // 播放音乐
  STOP_MUSIC = 'stop_music',          // 停止音乐
  NAVIGATE_TO = 'navigate_to'         // 导航到指定位置
}

/**
 * 控制命令参数接口
 */
export interface CommandParams {
  command: ControlCommand;    // 命令类型
  deviceId?: string;          // 目标设备ID
  params?: any;               // 命令参数
  timestamp: number;          // 命令时间戳
}