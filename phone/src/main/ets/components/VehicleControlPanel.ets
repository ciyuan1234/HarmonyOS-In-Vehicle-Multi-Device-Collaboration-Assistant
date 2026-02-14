/**
 * 车辆控制面板组件
 * 
 * 功能描述：
 * 1. 导航控制：设置目的地并下发到车机
 * 2. 音乐控制：播放/暂停/切歌
 * 3. 空调控制：温度调节
 * 
 * @author 车载多设备协同助手项目组
 */

import { DistributedDataManager } from '../../../shared/src/main/ets/utils/DistributedDataManager';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';

@Component
export struct VehicleControlPanel {
  // 导航控制状态
  @State destination: string = '';
  @State isNavigating: boolean = false;
  
  // 音乐控制状态
  @State isMusicPlaying: boolean = false;
  @State currentSong: string = '未选择歌曲';
  
  // 空调控制状态
  @State acTemperature: number = 22;
  @State isAcOn: boolean = false;
  
  private dataManager: DistributedDataManager = DistributedDataManager.getInstance();
  private readonly TAG: string = 'VehicleControlPanel';
  
  build() {
    Column() {
      // 面板标题
      Text('🚗 车辆控制')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .margin({ bottom: 16 })
        .selfAlign(ItemAlign.Start)
      
      // 导航控制区域
      this.renderNavigationControl()
      
      // 音乐控制区域
      this.renderMusicControl()
      
      // 空调控制区域
      this.renderClimateControl()
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding(16)
    .shadow({ radius: 6, color: '#00000010', offsetX: 0, offsetY: 2 })
  }
  
  /**
   * 渲染导航控制
   */
  @Builder
  private renderNavigationControl() {
    Column() {
      Row() {
        Text('🧭 导航控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
        
        If (this.isNavigating) {
          Text('导航中')
            .fontSize(12)
            .fontColor('#4CAF50')
        }
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 目的地输入
      Row() {
        TextInput({ placeholder: '请输入目的地', text: this.destination })
          .layoutWeight(1)
          .height(40)
          .borderRadius(8)
          .margin({ right: 8 })
          .onChange((value: string) => {
            this.destination = value;
          })
        
        Button('下发')
          .width(60)
          .height(40)
          .backgroundColor('#2196F3')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .enabled(this.destination.length > 0 && !this.isNavigating)
          .onClick(() => {
            this.sendNavigationCommand();
          })
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      // 导航状态按钮
      Row() {
        Button(this.isNavigating ? '结束导航' : '开始导航')
          .layoutWeight(1)
          .height(36)
          .backgroundColor(this.isNavigating ? '#F44336' : '#4CAF50')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .margin({ right: 8 })
          .onClick(() => {
            this.toggleNavigation();
          })
        
        Button('模拟路线')
          .layoutWeight(1)
          .height(36)
          .backgroundColor('#FF9800')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .onClick(() => {
            this.simulateRoute();
          })
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 20 })
  }
  
  /**
   * 渲染音乐控制
   */
  @Builder
  private renderMusicControl() {
    Column() {
      Row() {
        Text('🎵 音乐控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
        
        If (this.isMusicPlaying) {
          Text('播放中')
            .fontSize(12)
            .fontColor('#4CAF50')
        }
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 当前歌曲显示
      Text(this.currentSong)
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 12 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      
      // 控制按钮
      Row() {
        Button('⏮')
          .width(45)
          .height(45)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .borderRadius(22)
          .margin({ right: 12 })
          .onClick(() => {
            this.previousSong();
          })
        
        Button(this.isMusicPlaying ? '⏸' : '▶')
          .width(55)
          .height(55)
          .backgroundColor('#2196F3')
          .fontColor('#FFFFFF')
          .borderRadius(27)
          .margin({ left: 12, right: 12 })
          .onClick(() => {
            this.toggleMusic();
          })
        
        Button('⏭')
          .width(45)
          .height(45)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .borderRadius(22)
          .margin({ left: 12 })
          .onClick(() => {
            this.nextSong();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 8 })
      
      // 音量控制
      Row() {
        Text('🔈')
          .fontSize(16)
          .margin({ right: 8 })
        
        Slider({
          value: 70,
          min: 0,
          max: 100,
          style: SliderStyle.OutSet
        })
        .layoutWeight(1)
        .onChange((value: number) => {
          this.adjustVolume(Math.round(value));
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .margin({ bottom: 20 })
  }
  
  /**
   * 渲染空调控制
   */
  @Builder
  private renderClimateControl() {
    Column() {
      Row() {
        Text('❄️ 空调控制')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Toggle({ type: ToggleType.Switch, isOn: this.isAcOn })
          .onChange((isOn: boolean) => {
            this.toggleAc(isOn);
          })
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 温度显示和调节
      Column() {
        Text(`${this.acTemperature}°C`)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isAcOn ? '#2196F3' : '#999999')
          .margin({ bottom: 8 })
        
        Text('当前温度设定')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ bottom: 16 })
        
        // 温度调节滑块
        Slider({
          value: this.acTemperature,
          min: 18,
          max: 30,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .enabled(this.isAcOn)
        .onChange((value: number) => {
          this.setAcTemperature(Math.round(value));
        })
        .margin({ bottom: 12 })
        
        // 温度预设按钮
        Row() {
          ForEach([18, 22, 25, 28], (temp: number) => {
            Button(`${temp}°`)
              .width(50)
              .height(30)
              .fontSize(12)
              .backgroundColor(this.acTemperature === temp ? '#2196F3' : '#F5F5F5')
              .fontColor(this.acTemperature === temp ? '#FFFFFF' : '#333333')
              .borderRadius(6)
              .margin({ right: 8 })
              .onClick(() => {
                this.setAcTemperature(temp);
              })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
  }
  
  /**
   * 发送导航指令
   */
  private async sendNavigationCommand(): Promise<void> {
    if (!this.destination) {
      promptAction.showToast({ message: '请输入目的地' });
      return;
    }
    
    try {
      const success = await this.dataManager.storeVehicleData({
        navigationDestination: this.destination
      });
      
      if (success) {
        promptAction.showToast({ message: '导航指令已发送到车机' });
        hilog.info(0x0000, this.TAG, 'Navigation command sent: %{public}s', this.destination);
      } else {
        promptAction.showToast({ message: '指令发送失败' });
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to send navigation command: %{public}s', 
                 JSON.stringify(error));
      promptAction.showToast({ message: '发送失败' });
    }
  }
  
  /**
   * 切换导航状态
   */
  private toggleNavigation(): void {
    this.isNavigating = !this.isNavigating;
    const message = this.isNavigating ? '导航已开始' : '导航已结束';
    promptAction.showToast({ message: message });
    hilog.info(0x0000, this.TAG, 'Navigation toggled: %{public}s', this.isNavigating.toString());
  }
  
  /**
   * 模拟路线
   */
  private simulateRoute(): void {
    if (!this.destination) {
      promptAction.showToast({ message: '请先设置目的地' });
      return;
    }
    
    promptAction.showDialog({
      title: '模拟路线',
      message: `从当前位置到${this.destination}的路线：\n1. 直行2公里\n2. 右转进入主干道\n3. 行驶8公里到达`,
      buttons: [
        {
          text: '确定',
          color: '#2196F3'
        }
      ]
    });
  }
  
  /**
   * 切换音乐播放状态
   */
  private async toggleMusic(): Promise<void> {
    this.isMusicPlaying = !this.isMusicPlaying;
    
    try {
      await this.dataManager.storeVehicleData({
        isMusicPlaying: this.isMusicPlaying
      });
      
      const message = this.isMusicPlaying ? '音乐已开始播放' : '音乐已暂停';
      promptAction.showToast({ message: message });
      hilog.info(0x0000, this.TAG, 'Music toggled: %{public}s', this.isMusicPlaying.toString());
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to toggle music: %{public}s', JSON.stringify(error));
    }
  }
  
  /**
   * 上一首歌曲
   */
  private previousSong(): void {
    this.currentSong = '上一首歌曲';
    promptAction.showToast({ message: '切换到上一首' });
    hilog.info(0x0000, this.TAG, 'Previous song selected');
  }
  
  /**
   * 下一首歌曲
   */
  private nextSong(): void {
    this.currentSong = '下一首歌曲';
    promptAction.showToast({ message: '切换到下一首' });
    hilog.info(0x0000, this.TAG, 'Next song selected');
  }
  
  /**
   * 调节音量
   */
  private adjustVolume(volume: number): void {
    hilog.info(0x0000, this.TAG, 'Volume adjusted to: %{public}d%%', volume);
  }
  
  /**
   * 切换空调开关
   */
  private async toggleAc(isOn: boolean): Promise<void> {
    this.isAcOn = isOn;
    
    try {
      await this.dataManager.storeVehicleData({
        isAcOn: isOn
      });
      
      const message = isOn ? '空调已开启' : '空调已关闭';
      promptAction.showToast({ message: message });
      hilog.info(0x0000, this.TAG, 'AC toggled: %{public}s', isOn.toString());
    } catch (error) {
      hilog.error(0x0000, this.TAG, 'Failed to toggle AC: %{public}s', JSON.stringify(error));
    }
  }
  
  /**
   * 设置空调温度
   */
  private async setAcTemperature(temperature: number): Promise<void> {
    this.acTemperature = temperature;
    
    if (this.isAcOn) {
      try {
        await this.dataManager.storeVehicleData({
          acTemperature: temperature
        });
        
        hilog.info(0x0000, this.TAG, 'AC temperature set to: %{public}d°C', temperature);
      } catch (error) {
        hilog.error(0x0000, this.TAG, 'Failed to set AC temperature: %{public}s', 
                   JSON.stringify(error));
      }
    }
  }
}