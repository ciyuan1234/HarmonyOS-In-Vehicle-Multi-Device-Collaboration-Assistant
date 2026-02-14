/**
 * 空调面板组件
 * 
 * 功能描述：
 * 1. 显示当前空调温度
 * 2. 响应温度调节指令
 * 3. 模拟空调工作状态
 * 
 * @author 车载多设备协同助手项目组
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 空调状态接口
 */
interface ClimateState {
  targetTemperature: number;    // 目标温度
  currentTemperature: number;   // 当前车内温度
  isAcOn: boolean;             // 空调开关状态
  fanSpeed: number;            // 风速等级 (1-7)
  isAutoMode: boolean;         // 自动模式
  isRecirculation: boolean;    // 内循环模式
}

@Component
export struct ClimatePanel {
  @State climateState: ClimateState = {
    targetTemperature: 25,
    currentTemperature: 23,
    isAcOn: false,
    fanSpeed: 3,
    isAutoMode: true,
    isRecirculation: false
  };
  
  private temperatureAdjustTimer: number | null = null;
  private readonly TAG: string = 'ClimatePanel';
  
  build() {
    Column() {
      // 面板标题
      Row() {
        Text('❄️ 空调控制')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        
        Blank()
        
        // 空调状态指示器
        If (this.climateState.isAcOn) {
          Row() {
            Circle()
              .width(12)
              .height(12)
              .fill('#4CAF50')
              .margin({ right: 8 })
            
            Text('运行中')
              .fontSize(14)
              .fontColor('#4CAF50')
          }
        }
      }
      .width('100%')
      .padding({ bottom: 16 })
      
      // 温度显示区域
      Column() {
        // 目标温度大字显示
        Text(`${this.climateState.targetTemperature}°C`)
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.climateState.isAcOn ? '#4CAF50' : '#FFFFFF')
          .margin({ bottom: 8 })
        
        // 当前车内温度
        Text(`车内: ${this.climateState.currentTemperature}°C`)
          .fontSize(16)
          .fontColor('#AAAAAA')
          .margin({ bottom: 20 })
        
        // 温度调节按钮
        Row() {
          Button('-')
            .width(50)
            .height(50)
            .backgroundColor('#333333')
            .fontColor('#FFFFFF')
            .borderRadius(25)
            .margin({ right: 20 })
            .enabled(this.climateState.isAcOn)
            .onClick(() => {
              this.decreaseTemperature();
            })
          
          Text('温度调节')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          
          Button('+')
            .width(50)
            .height(50)
            .backgroundColor('#333333')
            .fontColor('#FFFFFF')
            .borderRadius(25)
            .margin({ left: 20 })
            .enabled(this.climateState.isAcOn)
            .onClick(() => {
              this.increaseTemperature();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ bottom: 20 })
      }
      .width('100%')
      .padding({ bottom: 20 })
      
      // 风速控制
      Column() {
        Row() {
          Text('风速控制')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
          
          Text(`等级 ${this.climateState.fanSpeed}`)
            .fontSize(14)
            .fontColor('#AAAAAA')
        }
        .width('100%')
        .padding({ bottom: 12 })
        
        // 风速滑块
        Slider({
          value: this.climateState.fanSpeed,
          min: 1,
          max: 7,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .enabled(this.climateState.isAcOn)
        .onChange((value: number) => {
          this.setFanSpeed(Math.round(value));
        })
        .padding({ bottom: 12 })
        
        // 风速等级显示
        Row() {
          ForEach([1, 2, 3, 4, 5, 6, 7], (level: number) => {
            Column() {
              Circle()
                .width(8)
                .height(8)
                .fill(level <= this.climateState.fanSpeed && this.climateState.isAcOn ? 
                      '#4CAF50' : '#333333')
              
              Text(level.toString())
                .fontSize(10)
                .fontColor(level <= this.climateState.fanSpeed && this.climateState.isAcOn ? 
                          '#4CAF50' : '#666666')
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ bottom: 20 })
      
      // 模式选择
      Column() {
        // 自动模式开关
        Row() {
          Text('自动模式')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
          
          Toggle({ type: ToggleType.Switch, isOn: this.climateState.isAutoMode })
            .enabled(this.climateState.isAcOn)
            .onChange((isOn: boolean) => {
              this.setAutoMode(isOn);
            })
        }
        .width('100%')
        .padding({ bottom: 16 })
        
        // 内循环开关
        Row() {
          Text('内循环')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
          
          Toggle({ type: ToggleType.Switch, isOn: this.climateState.isRecirculation })
            .enabled(this.climateState.isAcOn)
            .onChange((isOn: boolean) => {
              this.setRecirculation(isOn);
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ bottom: 20 })
      
      // 主控制按钮
      Row() {
        Button(this.climateState.isAcOn ? '关闭空调' : '开启空调')
          .backgroundColor(this.climateState.isAcOn ? '#F44336' : '#4CAF50')
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .height(45)
          .onClick(() => {
            this.toggleAc();
          })
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor('#1E1E1E')
    .borderRadius(16)
    .padding(20)
  }
  
  /**
   * 开关空调
   */
  toggleAc(): void {
    this.climateState = {
      ...this.climateState,
      isAcOn: !this.climateState.isAcOn
    };
    
    if (this.climateState.isAcOn) {
      this.startTemperatureAdjustment();
      hilog.info(0x0000, this.TAG, 'Air conditioning turned ON');
    } else {
      this.stopTemperatureAdjustment();
      hilog.info(0x0000, this.TAG, 'Air conditioning turned OFF');
    }
  }
  
  /**
   * 增加温度
   */
  private increaseTemperature(): void {
    if (this.climateState.targetTemperature < 30) {
      this.climateState = {
        ...this.climateState,
        targetTemperature: this.climateState.targetTemperature + 1
      };
      hilog.info(0x0000, this.TAG, 'Temperature increased to: %{public}d°C', 
                this.climateState.targetTemperature);
    }
  }
  
  /**
   * 降低温度
   */
  private decreaseTemperature(): void {
    if (this.climateState.targetTemperature > 16) {
      this.climateState = {
        ...this.climateState,
        targetTemperature: this.climateState.targetTemperature - 1
      };
      hilog.info(0x0000, this.TAG, 'Temperature decreased to: %{public}d°C', 
                this.climateState.targetTemperature);
    }
  }
  
  /**
   * 设置风速
   */
  private setFanSpeed(speed: number): void {
    this.climateState = {
      ...this.climateState,
      fanSpeed: speed
    };
    hilog.info(0x0000, this.TAG, 'Fan speed set to: %{public}d', speed);
  }
  
  /**
   * 设置自动模式
   */
  private setAutoMode(isAuto: boolean): void {
    this.climateState = {
      ...this.climateState,
      isAutoMode: isAuto
    };
    hilog.info(0x0000, this.TAG, 'Auto mode set to: %{public}s', isAuto.toString());
  }
  
  /**
   * 设置内循环
   */
  private setRecirculation(isRecirculation: boolean): void {
    this.climateState = {
      ...this.climateState,
      isRecirculation: isRecirculation
    };
    hilog.info(0x0000, this.TAG, 'Recirculation set to: %{public}s', isRecirculation.toString());
  }
  
  /**
   * 开始温度调节
   */
  private startTemperatureAdjustment(): void {
    this.temperatureAdjustTimer = setInterval(() => {
      const diff = this.climateState.targetTemperature - this.climateState.currentTemperature;
      if (Math.abs(diff) > 0.1) {
        // 逐渐调整到目标温度
        const adjustment = diff > 0 ? 0.1 : -0.1;
        this.climateState = {
          ...this.climateState,
          currentTemperature: parseFloat(
            (this.climateState.currentTemperature + adjustment).toFixed(1)
          )
        };
      }
    }, 1000);
  }
  
  /**
   * 停止温度调节
   */
  private stopTemperatureAdjustment(): void {
    if (this.temperatureAdjustTimer) {
      clearInterval(this.temperatureAdjustTimer);
      this.temperatureAdjustTimer = null;
    }
  }
  
  /**
   * 外部设置温度（响应手机端指令）
   */
  setTargetTemperature(temperature: number): void {
    const clampedTemp = Math.max(16, Math.min(30, temperature));
    this.climateState = {
      ...this.climateState,
      targetTemperature: clampedTemp
    };
    
    hilog.info(0x0000, this.TAG, 'Target temperature set to: %{public}d°C', clampedTemp);
  }
  
  /**
   * 外部控制空调开关
   */
  setAcState(isOn: boolean): void {
    if (isOn !== this.climateState.isAcOn) {
      this.climateState = {
        ...this.climateState,
        isAcOn: isOn
      };
      
      if (isOn) {
        this.startTemperatureAdjustment();
      } else {
        this.stopTemperatureAdjustment();
      }
      
      hilog.info(0x0000, this.TAG, 'AC state set to: %{public}s', isOn.toString());
    }
  }
  
  /**
   * 组件销毁时清理资源
   */
  aboutToDisappear(): void {
    this.stopTemperatureAdjustment();
  }
}