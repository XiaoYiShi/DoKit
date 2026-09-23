import { window } from '@kit.ArkUI';
import display from '@ohos.display';
import { DOKIT_INJECT_ROUTE_NAME, DOKIT_INJECT_WINDOW_NAME } from './DoKitSubWindowRoute';
import { ViewConfig } from '../core/DoKitViewManager';
import {
  ChromeBoundsVp,
  ensureNamedSubWindow,
  layoutSubWindowFromBounds,
  MainWindowRectPx,
  queryMainWindowRectPx
} from './DoKitSubWindowUtil';

export { InjectChromeBounds, MainWindowRectPx } from './DoKitSubWindowUtil';

/** 业务 ViewConfig 浮窗专用 SubWindow */
export class DoKitInjectSubWindow {
  private static windowStage?: window.WindowStage;
  private static injectWindow?: window.Window;
  private static mainWindowChromeActive: boolean = false;

  static bindStage(windowStage: window.WindowStage): void {
    DoKitInjectSubWindow.windowStage = windowStage;
  }

  static isShowing(): boolean {
    return DoKitInjectSubWindow.injectWindow !== undefined;
  }

  static isMainWindowChromeActive(): boolean {
    return DoKitInjectSubWindow.mainWindowChromeActive;
  }

  static ensureShown(onReady?: () => void): void {
    ensureNamedSubWindow(
      DoKitInjectSubWindow.windowStage,
      DoKitInjectSubWindow.injectWindow,
      DOKIT_INJECT_WINDOW_NAME,
      DOKIT_INJECT_ROUTE_NAME,
      (subWindow) => {
        DoKitInjectSubWindow.injectWindow = subWindow;
      },
      (subWindow) => {
        if (DoKitInjectSubWindow.injectWindow === subWindow) {
          DoKitInjectSubWindow.injectWindow = undefined;
          DoKitInjectSubWindow.mainWindowChromeActive = false;
        }
      },
      onReady
    );
  }

  static hide(): void {
    if (DoKitInjectSubWindow.injectWindow === undefined) {
      return;
    }
    const win = DoKitInjectSubWindow.injectWindow;
    DoKitInjectSubWindow.injectWindow = undefined;
    DoKitInjectSubWindow.mainWindowChromeActive = false;
    win.destroyWindow();
  }

  static layoutAsViewChrome(leftPx: number, topPx: number, widthPx: number, heightPx: number): void {
    const win = DoKitInjectSubWindow.injectWindow;
    if (win === undefined) {
      return;
    }
    DoKitInjectSubWindow.mainWindowChromeActive = false;
    win.setWindowLayoutFullScreen(false);
    win.resize(Math.max(1, widthPx), Math.max(1, heightPx));
    win.moveWindowTo(leftPx, topPx);
    try {
      win.showWindow();
    } catch (_e) {
    }
  }

  static layoutFromViewConfigs(configs: ViewConfig[], padVp: number, vp2px: (vp: number) => number): void {
    const bounds = DoKitInjectSubWindow.computeBoundsVp(configs);
    if (bounds === undefined) {
      return;
    }
    const mainBound = queryMainWindowRectPx();
    DoKitInjectSubWindow.layoutAsViewChrome(
      mainBound.leftPx + vp2px(bounds.minX - padVp),
      mainBound.topPx + vp2px(bounds.minY - padVp),
      vp2px(bounds.maxX - bounds.minX + padVp * 2),
      vp2px(bounds.maxY - bounds.minY + padVp * 2)
    );
  }

  static layoutAsMainWindowChrome(): void {
    const win = DoKitInjectSubWindow.injectWindow;
    if (win === undefined) {
      return;
    }
    try {
      const bound = queryMainWindowRectPx();
      DoKitInjectSubWindow.mainWindowChromeActive = true;
      win.setWindowLayoutFullScreen(true);
      win.resize(bound.widthPx, bound.heightPx);
      win.moveWindowTo(bound.leftPx, bound.topPx);
    } catch (_e) {
    }
  }

  static computeBoundsVp(configs: ViewConfig[]): ChromeBoundsVp | undefined {
    if (configs.length === 0) {
      return undefined;
    }
    let minX: number = Number.MAX_VALUE;
    let minY: number = Number.MAX_VALUE;
    let maxX: number = 0;
    let maxY: number = 0;
    for (const config of configs) {
      const vx = Number(config.viewPoint.x);
      const vy = Number(config.viewPoint.y);
      const vw = config.chromeWidthVp > 0 ? config.chromeWidthVp : 280;
      const vh = config.chromeHeightVp > 0 ? config.chromeHeightVp : 80;
      minX = Math.min(minX, vx);
      minY = Math.min(minY, vy);
      maxX = Math.max(maxX, vx + vw);
      maxY = Math.max(maxY, vy + vh);
    }
    if (minX === Number.MAX_VALUE) {
      return undefined;
    }
    return { minX, minY, maxX, maxY };
  }

  static queryMainWindowRectPx(): MainWindowRectPx {
    return queryMainWindowRectPx();
  }
}
