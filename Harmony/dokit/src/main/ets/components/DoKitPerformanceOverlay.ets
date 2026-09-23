import { PerformanceDokitViewManager } from '../kit/performance/PerformanceDokitViewManager';
import { PerformanceDoKitView } from '../kit/performance/PerformanceDoKitView';
import { DataSourceFactory } from '../kit/performance/datasource/DataSourceFactory';
import { InjectChromeBounds } from '../subwindow/DoKitInjectSubWindow';
import { DoKitPerformanceSubWindow } from '../subwindow/DoKitPerformanceSubWindow';

@Component
export struct DoKitPerformanceOverlay {
  @State private showFpsOverlay: boolean = false;
  @State private showCpuOverlay: boolean = false;
  @State private showRamOverlay: boolean = false;
  @State private chromeAnchorX: number = 0;
  @State private chromeAnchorY: number = 0;

  private readonly chromePadVp: number = 12;
  private readonly overlayWidthVp: number = 160;
  private readonly overlayHeightVp: number = 52;
  private readonly overlayLeftVp: number = 16;
  private readonly baseTopVp: number = 88;
  private readonly stackStepVp: number = 52;

  aboutToAppear(): void {
    PerformanceDokitViewManager.setOverlayUiRefreshHandler(() => {
      this.syncOverlayOpenState();
      this.syncPerformanceWindowChrome();
    });
    this.syncOverlayOpenState();
    this.syncPerformanceWindowChrome();
  }

  aboutToDisappear(): void {
    PerformanceDokitViewManager.setOverlayUiRefreshHandler(null);
  }

  private syncOverlayOpenState(): void {
    this.showFpsOverlay = PerformanceDokitViewManager.isFpsOverlayOpen();
    this.showCpuOverlay = PerformanceDokitViewManager.isCpuOverlayOpen();
    this.showRamOverlay = PerformanceDokitViewManager.isRamOverlayOpen();
  }

  private hasAnyOverlay(): boolean {
    return this.showFpsOverlay || this.showCpuOverlay || this.showRamOverlay;
  }

  private getScreenTop(performanceType: number): number {
    let top = this.baseTopVp;
    if (performanceType === DataSourceFactory.TYPE_CPU || performanceType === DataSourceFactory.TYPE_RAM) {
      if (this.showFpsOverlay) {
        top += this.stackStepVp;
      }
    }
    if (performanceType === DataSourceFactory.TYPE_RAM && this.showCpuOverlay) {
      top += this.stackStepVp;
    }
    return top;
  }

  private computeBoundsVp(): InjectChromeBounds | undefined {
    if (!this.hasAnyOverlay()) {
      return undefined;
    }
    let minY = Number.MAX_VALUE;
    let maxY = 0;
    if (this.showFpsOverlay) {
      const top = this.getScreenTop(DataSourceFactory.TYPE_FPS);
      minY = Math.min(minY, top);
      maxY = Math.max(maxY, top + this.overlayHeightVp);
    }
    if (this.showCpuOverlay) {
      const top = this.getScreenTop(DataSourceFactory.TYPE_CPU);
      minY = Math.min(minY, top);
      maxY = Math.max(maxY, top + this.overlayHeightVp);
    }
    if (this.showRamOverlay) {
      const top = this.getScreenTop(DataSourceFactory.TYPE_RAM);
      minY = Math.min(minY, top);
      maxY = Math.max(maxY, top + this.overlayHeightVp);
    }
    if (minY === Number.MAX_VALUE) {
      return undefined;
    }
    return {
      minX: this.overlayLeftVp,
      minY: minY,
      maxX: this.overlayLeftVp + this.overlayWidthVp,
      maxY: maxY
    };
  }

  private localX(screenLeft: number): number {
    return screenLeft - this.chromeAnchorX + this.chromePadVp;
  }

  private localY(screenTop: number): number {
    return screenTop - this.chromeAnchorY + this.chromePadVp;
  }

  private syncPerformanceWindowChrome(): void {
    if (!this.hasAnyOverlay()) {
      DoKitPerformanceSubWindow.hide();
      return;
    }
    const bounds = this.computeBoundsVp();
    if (bounds === undefined) {
      DoKitPerformanceSubWindow.hide();
      return;
    }
    this.chromeAnchorX = bounds.minX;
    this.chromeAnchorY = bounds.minY;
    DoKitPerformanceSubWindow.ensureShown(() => {
      const ui = this.getUIContext();
      DoKitPerformanceSubWindow.layoutFromBounds(bounds, this.chromePadVp, (vp: number) => ui.vp2px(vp));
    });
  }

  build() {
    Stack() {
      if (this.showFpsOverlay) {
        PerformanceDoKitView({
          performanceType: DataSourceFactory.TYPE_FPS,
          title: '帧率',
          unit: 'FPS',
          offsetX: this.localX(this.overlayLeftVp),
          topOffset: this.localY(this.getScreenTop(DataSourceFactory.TYPE_FPS)),
          onClose: () => {
            PerformanceDokitViewManager.closeOverlayFromView(DataSourceFactory.TYPE_FPS);
          }
        })
      }
      if (this.showCpuOverlay) {
        PerformanceDoKitView({
          performanceType: DataSourceFactory.TYPE_CPU,
          title: 'CPU',
          unit: '%',
          offsetX: this.localX(this.overlayLeftVp),
          topOffset: this.localY(this.getScreenTop(DataSourceFactory.TYPE_CPU)),
          onClose: () => {
            PerformanceDokitViewManager.closeOverlayFromView(DataSourceFactory.TYPE_CPU);
          }
        })
      }
      if (this.showRamOverlay) {
        PerformanceDoKitView({
          performanceType: DataSourceFactory.TYPE_RAM,
          title: '内存',
          unit: 'MB',
          offsetX: this.localX(this.overlayLeftVp),
          topOffset: this.localY(this.getScreenTop(DataSourceFactory.TYPE_RAM)),
          onClose: () => {
            PerformanceDokitViewManager.closeOverlayFromView(DataSourceFactory.TYPE_RAM);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
