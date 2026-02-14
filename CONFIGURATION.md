# 项目配置说明

## 模块配置文件详解

### 1. build-profile.json5 (项目根目录)
```json
{
  "modules": [
    {
      "name": "phone",      // 手机端模块
      "srcPath": "./phone"
    },
    {
      "name": "car",        // 车机端模块
      "srcPath": "./car"
    },
    {
      "name": "watch",      // 手表端模块
      "srcPath": "./watch"
    },
    {
      "name": "shared",     // 共享库模块
      "srcPath": "./shared"
    }
  ]
}
```

### 2. 各模块module.json5配置要点

**Phone模块配置：**
- deviceTypes: ["phone"]
- mainElement: "PhoneAbility"
- type: "entry"

**Car模块配置：**
- deviceTypes: ["car"]
- mainElement: "CarAbility"
- type: "entry"

**Watch模块配置：**
- deviceTypes: ["wearable"]
- mainElement: "WatchAbility"
- type: "entry"

**Shared模块配置：**
- deviceTypes: ["phone", "car", "watch"]
- type: "har" (Harmony Archive)

## 权限配置

在各模块的module.json5中需要添加以下权限：

```json
{
  "requestPermissions": [
    {
      "name": "ohos.permission.DISTRIBUTED_DATASYNC",
      "reason": "用于分布式设备间数据同步"
    },
    {
      "name": "ohos.permission.GET_NETWORK_INFO",
      "reason": "用于网络状态检测"
    },
    {
      "name": "ohos.permission.LOCATION",
      "reason": "用于获取位置信息"
    }
  ]
}
```

## 环境变量配置

### 开发环境
```bash
# HarmonyOS SDK路径
HARMONY_SDK_PATH=/path/to/harmony/sdk

# Node.js版本要求
NODE_VERSION=16.0+

# DevEco Studio版本
DEVECO_STUDIO_VERSION=5.0+
```

## 模拟器配置建议

### Phone模拟器
- 屏幕尺寸: 6.1英寸
- 分辨率: 1080x2340
- API级别: 6.0.2(22)

### Car模拟器
- 屏幕尺寸: 12.3英寸
- 分辨率: 1920x720
- API级别: 6.0.2(22)

### Watch模拟器
- 屏幕尺寸: 1.64英寸
- 分辨率: 454x454
- API级别: 6.0.2(22)

## 调试配置

### 日志级别设置
```typescript
// 在各模块中设置日志输出
hilog.setLevel(hilog.LOG_DEBUG);
```

### 网络调试
```bash
# 启用网络调试
adb tcpip 5555
adb connect <device_ip>:5555
```

## 构建配置优化

### 编译选项
```json
{
  "buildOption": {
    "strictMode": {
      "caseSensitiveCheck": true,
      "useNormalizedOHMUrl": true
    },
    "arkOptions": {
      "optimize": {
        "enable": true,
        "level": "O2"
      }
    }
  }
}
```

## 性能监控配置

### 内存监控
```typescript
// 启用内存监控
perfMonitor.enableMemoryTracking(true);
```

### CPU使用率监控
```typescript
// 监控CPU使用情况
perfMonitor.setCPUMonitorInterval(1000);
```

## 版本管理

### 版本号规则
- 主版本号: 功能重大更新
- 次版本号: 功能新增和改进
- 修订号: Bug修复和小幅度优化

### 当前版本
```
版本: 1.0.0
发布日期: 2024-xx-xx
HarmonyOS SDK: 6.0.2(22)
```