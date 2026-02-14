# 车载多设备协同助手

基于HarmonyOS Next的分布式车载助手系统，支持手机、车机、手表三端协同控制。

## 🚗 项目概述

这是一个完整的HarmonyOS Next车载多设备协同助手项目，实现了：
- **分布式设备发现与连接**
- **跨端数据实时同步**
- **车辆状态模拟与监控**
- **多端协同控制功能**

## 📱 支持设备

| 设备类型 | 模块名 | 主要功能 |
|---------|--------|----------|
| 手机端 | phone | 控制中心、设备管理、远程控制 |
| 车机端 | car | 仪表盘显示、车辆控制、多媒体系统 |
| 手表端 | watch | 快捷操作、状态查看、紧急控制 |

## 🏗️ 项目架构

```
wanwuhulian/
├── shared/                 # 共享模块
│   ├── manager/           # 核心管理器
│   │   ├── DistributedDeviceManager.ets    # 分布式设备管理
│   │   ├── VehicleSimulator.ets           # 车辆数据模拟
│   │   ├── DistributedDataManager.ets     # 数据同步管理
│   │   ├── VehicleAssistantManager.ets    # 业务总管理器
│   │   └── CrossDeviceFlowManager.ets     # 跨端任务流转
│   ├── model/             # 数据模型
│   │   └── DeviceModel.ets               # 设备和车辆数据模型
│   └── utils/             # 工具函数
│       └── CommonUtils.ets               # 通用工具函数
├── phone/                 # 手机端模块
│   └── src/main/ets/
│       ├── components/    # UI组件
│       │   ├── DeviceItem.ets            # 设备列表项
│       │   ├── VehicleControlPanel.ets   # 车辆控制面板
│       │   └── QuickActionCard.ets       # 快捷操作卡片
│       └── pages/
│           └── PhoneMain.ets             # 手机主页
├── car/                   # 车机端模块
│   └── src/main/ets/
│       ├── components/    # UI组件
│       │   ├── DashboardDisplay.ets      # 仪表盘显示
│       │   ├── MediaControlPanel.ets     # 多媒体控制
│       │   └── ClimateControlPanel.ets   # 空调控制
│       └── pages/
│           └── CarMain.ets               # 车机主页
└── watch/                 # 手表端模块
    └── src/main/ets/
        ├── components/    # UI组件
        │   ├── WatchActionButton.ets     # 快捷按钮
        │   └── WatchVehicleStatus.ets    # 状态概览
        └── pages/
            └── WatchMain.ets             # 手表主页
```

## 🔧 核心功能

### 1. 分布式设备管理
- 自动发现局域网内的HarmonyOS设备
- 实时监控设备连接状态
- 设备类型识别和分类管理

### 2. 车辆状态模拟
- 实时车速、燃油、温度等数据模拟
- 发动机状态、车门锁状态控制
- GPS位置信息模拟

### 3. 跨端数据同步
- 基于分布式对象的状态同步
- 实时命令分发和执行
- 设备间状态一致性保证

### 4. 多端协同控制
- 手机端远程控制车辆功能
- 车机端执行具体控制指令
- 手表端快捷操作和状态查看

## 🚀 运行配置

### 环境要求
- DevEco Studio 5.0+
- HarmonyOS SDK 6.0.2(22)+
- 支持HarmonyOS的设备模拟器

### 配置步骤

1. **导入项目**
   ```
   在DevEco Studio中打开项目目录
   ```

2. **模块配置**
   - 确保`build-profile.json5`中包含所有四个模块
   - 检查各模块的`module.json5`配置正确

3. **依赖安装**
   ```bash
   # 在项目根目录执行
   npm install
   ```

4. **模拟器设置**
   - 创建三个模拟器实例（Phone、Car、Wearable）
   - 确保模拟器在同一网络环境下

5. **运行应用**
   - 分别在三个模拟器上安装对应模块
   - 启动顺序：先启动车机端，再启动手机端和手表端

### 关键API说明

#### 分布式设备管理
```typescript
// 初始化设备管理器
const deviceManager = DistributedDeviceManager.getInstance();
await deviceManager.init('com.example.wanwuhulian');

// 获取设备列表
const devices = deviceManager.getTrustedDevices();

// 监听设备变化
deviceManager.setDeviceChangeListener((devices) => {
  // 处理设备列表变化
});
```

#### 车辆状态控制
```typescript
// 发送控制命令
const success = await vehicleManager.sendCommand(
  ControlCommand.START_ENGINE,  // 命令类型
  targetDeviceId,               // 目标设备（可选）
  params                        // 命令参数（可选）
);
```

#### 数据同步
```typescript
// 监听车辆状态变化
vehicleManager.setVehicleStatusListener((status) => {
  // 更新UI显示
});

// 监听命令接收
vehicleManager.setCommandReceivedListener((command) => {
  // 处理接收到的命令
});
```

## 📊 测试验证

### 功能测试清单

- [ ] 设备发现和连接测试
- [ ] 车辆状态同步测试
- [ ] 跨端命令执行测试
- [ ] UI交互响应测试
- [ ] 异常情况处理测试

### 性能指标

- 设备发现延迟：< 2秒
- 命令执行延迟：< 1秒
- 状态同步频率：1-2秒
- 内存占用：< 50MB

## ⚠️ 注意事项

1. **模拟器限制**：所有功能基于模拟器实现，实际硬件可能需要额外适配
2. **网络环境**：确保所有设备在同一局域网内才能正常通信
3. **权限配置**：需要相应的位置、网络、分布式权限
4. **API兼容性**：基于HarmonyOS 6.0.2开发，请确保SDK版本匹配

## 📚 参考资料

- [HarmonyOS官方文档](https://developer.harmonyos.com/)
- [分布式数据管理指南](https://developer.harmonyos.com/docs/)
- [ArkTS语言规范](https://developer.harmonyos.com/docs/)

## 🤝 贡献说明

本项目为参赛作品，欢迎提出改进建议和bug报告。

---
**项目状态**：✅ 开发完成 | 🚀 可运行测试