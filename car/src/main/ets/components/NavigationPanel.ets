/**
 * 导航面板组件
 * 
 * 功能描述：
 * 1. 显示导航目的地信息
 * 2. 展示路线规划（模拟文字）
 * 3. 响应导航指令更新
 * 
 * @author 车载多设备协同助手项目组
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 导航信息接口
 */
interface NavigationInfo {
  destination: string;      // 目的地
  distance: string;         // 距离
  estimatedTime: string;    // 预计时间
  routeInfo: string;        // 路线信息
  isNavigating: boolean;    // 是否正在导航
}

@Component
export struct NavigationPanel {
  @State navInfo: NavigationInfo = {
    destination: '未设置目的地',
    distance: '-- km',
    estimatedTime: '-- 分钟',
    routeInfo: '请先设置导航目的地',
    isNavigating: false
  };
  
  private readonly TAG: string = 'NavigationPanel';
  
  build() {
    Column() {
      // 面板标题
      Row() {
        Text('🧭 导航系统')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        
        Blank()
        
        // 导航状态指示器
        If (this.navInfo.isNavigating) {
          Row() {
            Circle()
              .width(12)
              .height(12)
              .fill('#4CAF50')
              .margin({ right: 8 })
            
            Text('导航中')
              .fontSize(14)
              .fontColor('#4CAF50')
          }
        }
      }
      .width('100%')
      .padding({ bottom: 16 })
      
      // 目的地信息
      Column() {
        Text('目的地')
          .fontSize(14)
          .fontColor('#AAAAAA')
          .selfAlign(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        Text(this.navInfo.destination)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ bottom: 20 })
      
      // 路线信息
      Column() {
        // 距离和时间
        Row() {
          Column() {
            Text(this.navInfo.distance)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
            
            Text('剩余距离')
              .fontSize(12)
              .fontColor('#AAAAAA')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          
          Column() {
            Text(this.navInfo.estimatedTime)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2196F3')
            
            Text('预计时间')
              .fontSize(12)
              .fontColor('#AAAAAA')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ bottom: 20 })
        
        // 路线详情
        Column() {
          Text('路线规划')
            .fontSize(14)
            .fontColor('#AAAAAA')
            .selfAlign(ItemAlign.Start)
            .margin({ bottom: 8 })
          
          Text(this.navInfo.routeInfo)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Start)
            .lineHeight(20)
        }
        .width('100%')
      }
      
      // 操作按钮
      Row() {
        Button('开始导航')
          .backgroundColor(this.navInfo.isNavigating ? '#9E9E9E' : '#4CAF50')
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .margin({ right: 8 })
          .onClick(() => {
            this.startNavigation();
          })
        
        Button('结束导航')
          .backgroundColor('#F44336')
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .margin({ left: 8 })
          .onClick(() => {
            this.stopNavigation();
          })
      }
      .width('100%')
      .padding({ top: 20 })
    }
    .width('100%')
    .backgroundColor('#1E1E1E')
    .borderRadius(16)
    .padding(20)
  }
  
  /**
   * 更新导航信息
   */
  updateNavigation(destination: string, routeInfo?: string): void {
    this.navInfo = {
      destination: destination,
      distance: this.calculateDistance(destination),
      estimatedTime: this.calculateTime(destination),
      routeInfo: routeInfo || this.generateRouteInfo(destination),
      isNavigating: this.navInfo.isNavigating
    };
    
    hilog.info(0x0000, this.TAG, 'Navigation info updated: %{public}s', destination);
  }
  
  /**
   * 开始导航
   */
  private startNavigation(): void {
    if (this.navInfo.destination !== '未设置目的地') {
      this.navInfo = {
        ...this.navInfo,
        isNavigating: true
      };
      hilog.info(0x0000, this.TAG, 'Navigation started to: %{public}s', this.navInfo.destination);
    }
  }
  
  /**
   * 结束导航
   */
  private stopNavigation(): void {
    this.navInfo = {
      ...this.navInfo,
      isNavigating: false
    };
    hilog.info(0x0000, this.TAG, 'Navigation stopped');
  }
  
  /**
   * 计算距离（模拟）
   */
  private calculateDistance(destination: string): string {
    // 模拟距离计算
    const distances = {
      '公司': '12.5 km',
      '家': '8.2 km',
      '商场': '3.7 km',
      '加油站': '2.1 km',
      '医院': '5.8 km'
    };
    
    return distances[destination as keyof typeof distances] || '10.0 km';
  }
  
  /**
   * 计算时间（模拟）
   */
  private calculateTime(destination: string): string {
    // 模拟时间计算
    const times = {
      '公司': '25分钟',
      '家': '18分钟',
      '商场': '12分钟',
      '加油站': '8分钟',
      '医院': '15分钟'
    };
    
    return times[destination as keyof typeof times] || '20分钟';
  }
  
  /**
   * 生成路线信息（模拟）
   */
  private generateRouteInfo(destination: string): string {
    const routeTemplates = [
      '1. 沿当前道路直行2公里\n2. 右转进入主干道\n3. 继续行驶8公里\n4. 左转到达目的地',
      '1. 从当前位置出发\n2. 经过3个红绿灯\n3. 行驶约10分钟\n4. 到达指定地点',
      '1. 走最近路线\n2. 预计耗时较短\n3. 路况良好\n4. 安全抵达'
    ];
    
    return routeTemplates[Math.floor(Math.random() * routeTemplates.length)];
  }
}