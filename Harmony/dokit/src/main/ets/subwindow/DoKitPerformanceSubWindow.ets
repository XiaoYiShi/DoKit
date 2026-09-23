import { window } from '@kit.ArkUI';
import { DOKIT_PERFORMANCE_ROUTE_NAME, DOKIT_PERFORMANCE_WINDOW_NAME } from './DoKitSubWindowRoute';
import { ChromeBoundsVp, ensureNamedSubWindow, layoutSubWindowFromBounds } from './DoKitSubWindowUtil';

/** FPS / CPU / 内存性能浮层专用 SubWindow */
export class DoKitPerformanceSubWindow {
  private static windowStage?: window.WindowStage;
  private static performanceWindow?: window.Window;

  static bindStage(windowStage: window.WindowStage): void {
    DoKitPerformanceSubWindow.windowStage = windowStage;
  }

  static isShowing(): boolean {
    return DoKitPerformanceSubWindow.performanceWindow !== undefined;
  }

  static ensureShown(onReady?: () => void): void {
    ensureNamedSubWindow(
      DoKitPerformanceSubWindow.windowStage,
      DoKitPerformanceSubWindow.performanceWindow,
      DOKIT_PERFORMANCE_WINDOW_NAME,
      DOKIT_PERFORMANCE_ROUTE_NAME,
      (subWindow) => {
        DoKitPerformanceSubWindow.performanceWindow = subWindow;
      },
      (subWindow) => {
        if (DoKitPerformanceSubWindow.performanceWindow === subWindow) {
          DoKitPerformanceSubWindow.performanceWindow = undefined;
        }
      },
      onReady
    );
  }

  static hide(): void {
    if (DoKitPerformanceSubWindow.performanceWindow === undefined) {
      return;
    }
    const win = DoKitPerformanceSubWindow.performanceWindow;
    DoKitPerformanceSubWindow.performanceWindow = undefined;
    win.destroyWindow();
  }

  static layoutFromBounds(bounds: ChromeBoundsVp, padVp: number, vp2px: (vp: number) => number): void {
    const win = DoKitPerformanceSubWindow.performanceWindow;
    if (win === undefined) {
      return;
    }
    layoutSubWindowFromBounds(win, bounds, padVp, vp2px);
  }
}
