/**
 * 音乐面板组件
 * 
 * 功能描述：
 * 1. 显示音乐播放状态
 * 2. 响应播放/暂停指令
 * 3. 模拟歌曲信息展示
 * 
 * @author 车载多设备协同助手项目组
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 音乐播放状态接口
 */
interface MusicState {
  isPlaying: boolean;       // 播放状态
  songTitle: string;        // 歌曲标题
  artist: string;           // 歌手
  album: string;            // 专辑
  progress: number;         // 播放进度 (0-100)
  volume: number;           // 音量 (0-100)
}

@Component
export struct MusicPanel {
  @State musicState: MusicState = {
    isPlaying: false,
    songTitle: '请选择歌曲',
    artist: '未知歌手',
    album: '未知专辑',
    progress: 0,
    volume: 60
  };
  
  private progressTimer: number | null = null;
  private readonly TAG: string = 'MusicPanel';
  
  build() {
    Column() {
      // 面板标题
      Row() {
        Text('🎵 音乐播放器')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        
        Blank()
        
        // 播放状态指示器
        If (this.musicState.isPlaying) {
          Row() {
            Circle()
              .width(12)
              .height(12)
              .fill('#4CAF50')
              .margin({ right: 8 })
            
            Text('播放中')
              .fontSize(14)
              .fontColor('#4CAF50')
          }
        }
      }
      .width('100%')
      .padding({ bottom: 16 })
      
      // 专辑封面区域
      Column() {
        Circle()
          .width(120)
          .height(120)
          .fill(this.musicState.isPlaying ? '#4CAF50' : '#666666')
        
        // 歌曲信息
        Column() {
          Text(this.musicState.songTitle)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 16, bottom: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          
          Text(`${this.musicState.artist} - ${this.musicState.album}`)
            .fontSize(14)
            .fontColor('#AAAAAA')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .padding({ top: 16 })
      }
      .width('100%')
      .padding({ bottom: 20 })
      
      // 进度条
      Column() {
        Row() {
          Text(this.formatTime(this.musicState.progress))
            .fontSize(12)
            .fontColor('#AAAAAA')
          
          Blank()
          
          Text(this.formatTime(100))
            .fontSize(12)
            .fontColor('#AAAAAA')
        }
        .width('100%')
        .padding({ bottom: 8 })
        
        ProgressBar({ value: this.musicState.progress, total: 100 })
          .width('100%')
          .height(4)
          .color('#4CAF50')
          .backgroundColor('#333333')
      }
      .width('100%')
      .padding({ bottom: 20 })
      
      // 控制按钮
      Row() {
        // 上一首
        Button('⏮')
          .width(50)
          .height(50)
          .backgroundColor('#333333')
          .fontColor('#FFFFFF')
          .borderRadius(25)
          .margin({ right: 16 })
          .onClick(() => {
            this.previousSong();
          })
        
        // 播放/暂停
        Button(this.musicState.isPlaying ? '⏸' : '▶')
          .width(60)
          .height(60)
          .backgroundColor('#4CAF50')
          .fontColor('#FFFFFF')
          .borderRadius(30)
          .margin({ left: 16, right: 16 })
          .onClick(() => {
            this.togglePlayPause();
          })
        
        // 下一首
        Button('⏭')
          .width(50)
          .height(50)
          .backgroundColor('#333333')
          .fontColor('#FFFFFF')
          .borderRadius(25)
          .margin({ left: 16 })
          .onClick(() => {
            this.nextSong();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: 20 })
      
      // 音量控制
      Column() {
        Row() {
          Text('🔊 音量')
            .fontSize(14)
            .fontColor('#AAAAAA')
            .layoutWeight(1)
          
          Text(`${this.musicState.volume}%`)
            .fontSize(14)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .padding({ bottom: 8 })
        
        Slider({
          value: this.musicState.volume,
          min: 0,
          max: 100,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .onChange((value: number) => {
          this.adjustVolume(Math.round(value));
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
   * 切换播放/暂停状态
   */
  togglePlayPause(): void {
    this.musicState = {
      ...this.musicState,
      isPlaying: !this.musicState.isPlaying
    };
    
    if (this.musicState.isPlaying) {
      this.startProgressTimer();
      hilog.info(0x0000, this.TAG, 'Music playback started');
    } else {
      this.stopProgressTimer();
      hilog.info(0x0000, this.TAG, 'Music playback paused');
    }
  }
  
  /**
   * 上一首歌曲
   */
  private previousSong(): void {
    const songs = this.getSongLibrary();
    const currentIndex = songs.findIndex(song => 
      song.title === this.musicState.songTitle);
    const prevIndex = currentIndex > 0 ? currentIndex - 1 : songs.length - 1;
    const prevSong = songs[prevIndex];
    
    this.updateSong(prevSong);
    hilog.info(0x0000, this.TAG, 'Previous song selected: %{public}s', prevSong.title);
  }
  
  /**
   * 下一首歌曲
   */
  private nextSong(): void {
    const songs = this.getSongLibrary();
    const currentIndex = songs.findIndex(song => 
      song.title === this.musicState.songTitle);
    const nextIndex = (currentIndex + 1) % songs.length;
    const nextSong = songs[nextIndex];
    
    this.updateSong(nextSong);
    hilog.info(0x0000, this.TAG, 'Next song selected: %{public}s', nextSong.title);
  }
  
  /**
   * 更新当前歌曲
   */
  private updateSong(song: any): void {
    this.musicState = {
      ...this.musicState,
      songTitle: song.title,
      artist: song.artist,
      album: song.album,
      progress: 0
    };
    
    // 如果正在播放，重新开始进度计时
    if (this.musicState.isPlaying) {
      this.stopProgressTimer();
      this.startProgressTimer();
    }
  }
  
  /**
   * 调整音量
   */
  private adjustVolume(volume: number): void {
    this.musicState = {
      ...this.musicState,
      volume: volume
    };
    hilog.info(0x0000, this.TAG, 'Volume adjusted to: %{public}d%%', volume);
  }
  
  /**
   * 开始进度计时器
   */
  private startProgressTimer(): void {
    this.progressTimer = setInterval(() => {
      if (this.musicState.progress < 100) {
        this.musicState = {
          ...this.musicState,
          progress: this.musicState.progress + 1
        };
      } else {
        // 歌曲播放完毕，自动播放下一首
        this.nextSong();
      }
    }, 500); // 每500ms更新一次进度
  }
  
  /**
   * 停止进度计时器
   */
  private stopProgressTimer(): void {
    if (this.progressTimer) {
      clearInterval(this.progressTimer);
      this.progressTimer = null;
    }
  }
  
  /**
   * 格式化时间显示
   */
  private formatTime(progress: number): string {
    const totalSeconds = 240; // 假设每首歌4分钟
    const currentSeconds = Math.floor((progress / 100) * totalSeconds);
    const minutes = Math.floor(currentSeconds / 60);
    const seconds = currentSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  }
  
  /**
   * 获取歌曲库（模拟数据）
   */
  private getSongLibrary(): Array<{title: string, artist: string, album: string}> {
    return [
      { title: '夜曲', artist: '周杰伦', album: '十一月的萧邦' },
      { title: '青花瓷', artist: '周杰伦', album: '我很忙' },
      { title: '稻香', artist: '周杰伦', album: '魔杰座' },
      { title: '告白气球', artist: '周杰伦', album: '周杰伦的床边故事' },
      { title: '简单爱', artist: '周杰伦', album: '范特西' }
    ];
  }
  
  /**
   * 设置播放状态（外部调用）
   */
  setPlayState(isPlaying: boolean): void {
    if (isPlaying !== this.musicState.isPlaying) {
      this.musicState = {
        ...this.musicState,
        isPlaying: isPlaying
      };
      
      if (isPlaying) {
        this.startProgressTimer();
      } else {
        this.stopProgressTimer();
      }
    }
  }
  
  /**
   * 组件销毁时清理资源
   */
  aboutToDisappear(): void {
    this.stopProgressTimer();
  }
}