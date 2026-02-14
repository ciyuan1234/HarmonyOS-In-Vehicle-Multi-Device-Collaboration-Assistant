/**
 * 多媒体控制组件
 * 控制音乐播放、收音机等功能
 */
@Component
export struct MediaControlPanel {
  @State isPlaying: boolean = false;
  @State currentTrack: string = '未选择歌曲';
  @State volume: number = 50;
  @State isRadioMode: boolean = false;

  build() {
    Column() {
      // 标题
      Text('🎵 多媒体控制')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 20 })
        .selfAlign(ItemAlign.Start)
      
      // 模式切换
      this.renderModeSwitch()
      
      // 音乐播放控制
      if (!this.isRadioMode) {
        this.renderMusicControls()
      } else {
        this.renderRadioControls()
      }
      
      // 音量控制
      this.renderVolumeControl()
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding(20)
    .shadow({ radius: 6, color: '#00000010', offsetX: 0, offsetY: 2 })
  }

  /**
   * 渲染模式切换
   */
  @Builder
  renderModeSwitch() {
    Row() {
      Button('音乐')
        .backgroundColor(this.isRadioMode ? '#E0E0E0' : '#2196F3')
        .fontColor(this.isRadioMode ? '#666666' : '#FFFFFF')
        .layoutWeight(1)
        .margin({ right: 8 })
        .onClick(() => {
          this.isRadioMode = false;
        })
      
      Button('收音机')
        .backgroundColor(this.isRadioMode ? '#2196F3' : '#E0E0E0')
        .fontColor(this.isRadioMode ? '#FFFFFF' : '#666666')
        .layoutWeight(1)
        .margin({ left: 8 })
        .onClick(() => {
          this.isRadioMode = true;
        })
    }
    .width('100%')
    .height(40)
    .margin({ bottom: 20 })
  }

  /**
   * 渲染音乐控制
   */
  @Builder
  renderMusicControls() {
    Column() {
      // 当前歌曲信息
      Column() {
        Text(this.currentTrack)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ bottom: 4 })
        
        Text('未知艺术家')
          .fontSize(14)
          .fontColor('#666666')
      }
      .margin({ bottom: 20 })
      
      // 播放控制按钮
      Row() {
        Button('⏮️')
          .width(50)
          .height(50)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .borderRadius(25)
          .margin({ right: 20 })
          .onClick(() => {
            this.previousTrack();
          })
        
        Button(this.isPlaying ? '⏸️' : '▶️')
          .width(60)
          .height(60)
          .backgroundColor('#2196F3')
          .fontColor('#FFFFFF')
          .borderRadius(30)
          .margin({ left: 20, right: 20 })
          .onClick(() => {
            this.togglePlayPause();
          })
        
        Button('⏭️')
          .width(50)
          .height(50)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .borderRadius(25)
          .margin({ left: 20 })
          .onClick(() => {
            this.nextTrack();
          })
      }
      .margin({ bottom: 20 })
      
      // 进度条
      Row() {
        Text('0:00')
          .fontSize(12)
          .fontColor('#999999')
        
        Slider({
          value: 30,
          min: 0,
          max: 100,
          style: SliderStyle.OutSet
        })
        .layoutWeight(1)
        .padding({ left: 10, right: 10 })
        .onChange((value: number) => {
          console.info('Progress changed:', value);
        })
        
        Text('3:45')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }

  /**
   * 渲染收音机控制
   */
  @Builder
  renderRadioControls() {
    Column() {
      // 当前频率
      Text('FM 101.1 MHz')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 20 })
      
      // 频道预设
      Row() {
        ForEach(['89.1', '91.5', '97.4', '101.1', '103.8'], (freq: string) => {
          Button(freq)
            .backgroundColor('#E0E0E0')
            .fontColor('#333333')
            .borderRadius(8)
            .margin({ right: 8 })
            .onClick(() => {
              this.tuneFrequency(freq);
            })
        })
      }
      .margin({ bottom: 20 })
      
      // 调频控制
      Row() {
        Button('⬇️')
          .width(50)
          .height(50)
          .backgroundColor('#F5F5F5')
          .borderRadius(25)
          .margin({ right: 20 })
          .onClick(() => {
            this.tuneDown();
          })
        
        Text('调节频率')
          .fontSize(16)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Button('⬆️')
          .width(50)
          .height(50)
          .backgroundColor('#F5F5F5')
          .borderRadius(25)
          .margin({ left: 20 })
          .onClick(() => {
            this.tuneUp();
          })
      }
    }
  }

  /**
   * 渲染音量控制
   */
  @Builder
  renderVolumeControl() {
    Column() {
      Row() {
        Text('🔈')
          .fontSize(20)
          .margin({ right: 10 })
        
        Text(`音量: ${this.volume}%`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 10 })
      
      Slider({
        value: this.volume,
        min: 0,
        max: 100,
        style: SliderStyle.OutSet
      })
      .width('100%')
      .onChange((value: number) => {
        this.volume = Math.round(value);
        this.onVolumeChange(this.volume);
      })
    }
    .margin({ top: 20 })
  }

  /**
   * 切换播放/暂停
   */
  private togglePlayPause(): void {
    this.isPlaying = !this.isPlaying;
    console.info('Play/Pause toggled:', this.isPlaying);
  }

  /**
   * 上一首
   */
  private previousTrack(): void {
    console.info('Previous track');
  }

  /**
   * 下一首
   */
  private nextTrack(): void {
    console.info('Next track');
  }

  /**
   * 调节音量
   */
  private onVolumeChange(volume: number): void {
    console.info('Volume changed to:', volume);
  }

  /**
   * 调频向上
   */
  private tuneUp(): void {
    console.info('Tuning up');
  }

  /**
   * 调频向下
   */
  private tuneDown(): void {
    console.info('Tuning down');
  }

  /**
   * 调至指定频率
   */
  private tuneFrequency(freq: string): void {
    console.info('Tuning to frequency:', freq);
  }
}