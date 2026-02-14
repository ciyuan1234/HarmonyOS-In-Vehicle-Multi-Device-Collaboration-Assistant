import { formatTemperature } from '../../../../shared/src/main/ets/utils/CommonUtils';

/**
 * 空调控制组件
 */
@Component
export struct ClimateControlPanel {
  @State isAcOn: boolean = false;
  @State targetTemperature: number = 22;
  @State fanSpeed: number = 3;
  @State isAutoMode: boolean = true;
  @State isRecirculationOn: boolean = false;

  build() {
    Column() {
      // 标题
      Text('❄️ 空调控制')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 20 })
        .selfAlign(ItemAlign.Start)
      
      // 空调开关
      this.renderAcToggle()
      
      // 温度控制
      this.renderTemperatureControl()
      
      // 风扇控制
      this.renderFanControl()
      
      // 模式选择
      this.renderModeSelection()
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding(20)
    .shadow({ radius: 6, color: '#00000010', offsetX: 0, offsetY: 2 })
  }

  /**
   * 渲染空调开关
   */
  @Builder
  renderAcToggle() {
    Row() {
      Text('空调状态')
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
      
      Toggle({ type: ToggleType.Switch, isOn: this.isAcOn })
        .onChange((isOn: boolean) => {
          this.isAcOn = isOn;
          this.onAcToggle(isOn);
        })
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  /**
   * 渲染温度控制
   */
  @Builder
  renderTemperatureControl() {
    Column() {
      Text('目标温度')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 15 })
        .selfAlign(ItemAlign.Start)
      
      Row() {
        // 减温按钮
        Button('-')
          .width(40)
          .height(40)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .borderRadius(20)
          .margin({ right: 15 })
          .enabled(this.isAcOn)
          .onClick(() => {
            if (this.targetTemperature > 16) {
              this.targetTemperature--;
              this.onTemperatureChange(this.targetTemperature);
            }
          })
        
        // 温度显示
        Column() {
          Text(formatTemperature(this.targetTemperature))
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isAcOn ? '#2196F3' : '#999999')
          
          Text('车内温度')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        // 增温按钮
        Button('+')
          .width(40)
          .height(40)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .borderRadius(20)
          .margin({ left: 15 })
          .enabled(this.isAcOn)
          .onClick(() => {
            if (this.targetTemperature < 30) {
              this.targetTemperature++;
              this.onTemperatureChange(this.targetTemperature);
            }
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 20 })
      
      // 温度滑块
      Slider({
        value: this.targetTemperature,
        min: 16,
        max: 30,
        style: SliderStyle.OutSet
      })
      .width('100%')
      .enabled(this.isAcOn)
      .onChange((value: number) => {
        this.targetTemperature = Math.round(value);
        this.onTemperatureChange(this.targetTemperature);
      })
    }
    .margin({ bottom: 25 })
  }

  /**
   * 渲染风扇控制
   */
  @Builder
  renderFanControl() {
    Column() {
      Row() {
        Text('风速控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Text(`${this.fanSpeed}/7`)
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 15 })
      
      // 风速滑块
      Slider({
        value: this.fanSpeed,
        min: 0,
        max: 7,
        style: SliderStyle.OutSet
      })
      .width('100%')
      .enabled(this.isAcOn)
      .onChange((value: number) => {
        this.fanSpeed = Math.round(value);
        this.onFanSpeedChange(this.fanSpeed);
      })
      .margin({ bottom: 10 })
      
      // 风速级别显示
      Row() {
        ForEach([0, 1, 2, 3, 4, 5, 6, 7], (level: number) => {
          Column() {
            Circle()
              .width(8)
              .height(8)
              .fill(level <= this.fanSpeed && this.isAcOn ? '#2196F3' : '#E0E0E0')
            
            Text(level.toString())
              .fontSize(10)
              .fontColor(level <= this.fanSpeed && this.isAcOn ? '#2196F3' : '#999999')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        })
      }
      .width('100%')
    }
    .margin({ bottom: 25 })
  }

  /**
   * 渲染模式选择
   */
  @Builder
  renderModeSelection() {
    Column() {
      Text('工作模式')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 15 })
        .selfAlign(ItemAlign.Start)
      
      // 自动模式
      Row() {
        Text('自动模式')
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Toggle({ type: ToggleType.Switch, isOn: this.isAutoMode })
          .enabled(this.isAcOn)
          .onChange((isOn: boolean) => {
            this.isAutoMode = isOn;
            this.onModeChange('auto', isOn);
          })
      }
      .width('100%')
      .margin({ bottom: 15 })
      
      // 内循环
      Row() {
        Text('内循环')
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Toggle({ type: ToggleType.Switch, isOn: this.isRecirculationOn })
          .enabled(this.isAcOn)
          .onChange((isOn: boolean) => {
            this.isRecirculationOn = isOn;
            this.onModeChange('recirculation', isOn);
          })
      }
      .width('100%')
    }
  }

  /**
   * 空调开关回调
   */
  private onAcToggle(isOn: boolean): void {
    console.info('AC toggled:', isOn);
  }

  /**
   * 温度变化回调
   */
  private onTemperatureChange(temperature: number): void {
    console.info('Temperature changed to:', temperature);
  }

  /**
   * 风速变化回调
   */
  private onFanSpeedChange(speed: number): void {
    console.info('Fan speed changed to:', speed);
  }

  /**
   * 模式变化回调
   */
  private onModeChange(mode: string, isEnabled: boolean): void {
    console.info('Mode changed:', mode, isEnabled);
  }
}