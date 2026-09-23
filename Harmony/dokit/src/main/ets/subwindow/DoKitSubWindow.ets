import { window } from '@kit.ArkUI';
import display from '@ohos.display';
import { DOKIT_OVERLAY_ROUTE_NAME, DOKIT_OVERLAY_WINDOW_NAME } from './DoKitSubWindowRoute';
import { DoKitInjectSubWindow } from './DoKitInjectSubWindow';
import { DoKitPerformanceSubWindow } from './DoKitPerformanceSubWindow';
import { bindWindowStageToAppStorage, setSubWindowTransparent } from './DoKitSubWindowUtil';

/** SubWindow 生命周期与贴球/全屏 chrome 布局 */
export class DoKitSubWindow {
  private static windowStage?: window.WindowStage;
  private static subWindow?: window.Window;
  private static iconChromeLeftPx: number = 0;
  private static iconChromeTopPx: number = 0;
  private static fullScreenChromeActive: boolean = false;

  static attach(windowStage: window.WindowStage): void {
    DoKitSubWindow.windowStage = windowStage;
    bindWindowStageToAppStorage(windowStage);
    DoKitInjectSubWindow.bindStage(windowStage);
    DoKitPerformanceSubWindow.bindStage(windowStage);
  }

  static detach(): void {
    DoKitSubWindow.hide();
    DoKitInjectSubWindow.hide();
    DoKitPerformanceSubWindow.hide();
    DoKitSubWindow.windowStage = undefined;
  }

  static isShowing(): boolean {
    return DoKitSubWindow.subWindow !== undefined;
  }

  static getIconChromeLeftPx(): number {
    return DoKitSubWindow.iconChromeLeftPx;
  }

  static getIconChromeTopPx(): number {
    return DoKitSubWindow.iconChromeTopPx;
  }

  static show(): void {
    if (DoKitSubWindow.windowStage === undefined || DoKitSubWindow.subWindow !== undefined) {
      return;
    }
    DoKitSubWindow.windowStage.createSubWindow(DOKIT_OVERLAY_WINDOW_NAME, (err, subWindow) => {
      if (err.code !== 0) {
        return;
      }
      DoKitSubWindow.subWindow = subWindow;
      subWindow.setWindowFocusable(false);
      subWindow.loadContentByName(DOKIT_OVERLAY_ROUTE_NAME, (loadErr) => {
        if (loadErr.code !== 0) {
          DoKitSubWindow.clearSubWindowRef(subWindow);
          return;
        }
        setSubWindowTransparent(subWindow);
        subWindow.showWindow((showErr) => {
          if (showErr.code !== 0) {
            DoKitSubWindow.clearSubWindowRef(subWindow);
            return;
          }
          setSubWindowTransparent(subWindow);
        });
      });
    });
  }

  static layoutAsIconChrome(leftPx: number, topPx: number, widthPx: number, heightPx: number): void {
    const win = DoKitSubWindow.subWindow;
    if (win === undefined) {
      return;
    }
    DoKitSubWindow.fullScreenChromeActive = false;
    DoKitSubWindow.iconChromeLeftPx = leftPx;
    DoKitSubWindow.iconChromeTopPx = topPx;
    win.setWindowLayoutFullScreen(false);
    win.resize(Math.max(1, widthPx), Math.max(1, heightPx));
    win.moveWindowTo(leftPx, topPx);
  }

  static layoutAsFullScreenChrome(): void {
    const win = DoKitSubWindow.subWindow;
    if (win === undefined || DoKitSubWindow.fullScreenChromeActive) {
      return;
    }
    try {
      const displayInfo = display.getDefaultDisplaySync();
      win.setWindowLayoutFullScreen(true);
      win.resize(displayInfo.width, displayInfo.height);
      win.moveWindowTo(0, 0);
      DoKitSubWindow.fullScreenChromeActive = true;
    } catch (_e) {
    }
  }

  static layoutAsHiddenChrome(): void {
    DoKitSubWindow.layoutAsIconChrome(-2, -2, 1, 1);
  }

  static hide(): void {
    if (DoKitSubWindow.subWindow === undefined) {
      return;
    }
    const win = DoKitSubWindow.subWindow;
    DoKitSubWindow.subWindow = undefined;
    DoKitSubWindow.fullScreenChromeActive = false;
    win.destroyWindow();
  }

  private static clearSubWindowRef(subWindow: window.Window): void {
    if (DoKitSubWindow.subWindow === subWindow) {
      DoKitSubWindow.subWindow = undefined;
      DoKitSubWindow.fullScreenChromeActive = false;
    }
    subWindow.destroyWindow();
  }
}
