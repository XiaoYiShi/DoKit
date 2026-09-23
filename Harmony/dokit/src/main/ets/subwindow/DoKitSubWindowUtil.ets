import { window } from '@kit.ArkUI';
import display from '@ohos.display';

export interface ChromeBoundsVp {
  minX: number;
  minY: number;
  maxX: number;
  maxY: number;
}

export type InjectChromeBounds = ChromeBoundsVp;

export interface MainWindowRectPx {
  leftPx: number;
  topPx: number;
  widthPx: number;
  heightPx: number;
}

export function bindWindowStageToAppStorage(windowStage: window.WindowStage): void {
  AppStorage.setOrCreate('windowStage', windowStage);
  try {
    const mainWin = windowStage.getMainWindowSync();
    const avoidArea = mainWin.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    AppStorage.setOrCreate('topRectHeight', avoidArea.topRect.height);
    mainWin.on('avoidAreaChange', (data) => {
      if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
        AppStorage.setOrCreate('topRectHeight', data.area.topRect.height);
      }
    });
  } catch (_e) {
  }
}

export function queryMainWindowRectPx(): MainWindowRectPx {
  try {
    const stage = AppStorage.get<window.WindowStage>('windowStage');
    if (stage !== undefined && stage !== null) {
      const rect = stage.getMainWindowSync().getWindowProperties().windowRect;
      return {
        leftPx: rect.left,
        topPx: rect.top,
        widthPx: rect.width,
        heightPx: rect.height
      };
    }
  } catch (_e) {
  }
  const displayInfo = display.getDefaultDisplaySync();
  return {
    leftPx: 0,
    topPx: 0,
    widthPx: displayInfo.width,
    heightPx: displayInfo.height
  };
}

export function setSubWindowTransparent(subWindow: window.Window): void {
  try {
    subWindow.setWindowBackgroundColor('#00000000');
  } catch (_e) {
  }
}

export function layoutSubWindowFromBounds(
  subWindow: window.Window,
  bounds: ChromeBoundsVp,
  padVp: number,
  vp2px: (vp: number) => number
): void {
  const mainBound = queryMainWindowRectPx();
  subWindow.setWindowLayoutFullScreen(false);
  subWindow.resize(
    Math.max(1, vp2px(bounds.maxX - bounds.minX + padVp * 2)),
    Math.max(1, vp2px(bounds.maxY - bounds.minY + padVp * 2))
  );
  subWindow.moveWindowTo(
    mainBound.leftPx + vp2px(bounds.minX - padVp),
    mainBound.topPx + vp2px(bounds.minY - padVp)
  );
  try {
    subWindow.showWindow();
  } catch (_e) {
  }
}

export function ensureNamedSubWindow(
  windowStage: window.WindowStage | undefined,
  currentWindow: window.Window | undefined,
  windowName: string,
  routeName: string,
  onCreated: (subWindow: window.Window) => void,
  onCreateFailed: (subWindow: window.Window) => void,
  onReady?: () => void
): void {
  if (windowStage === undefined) {
    return;
  }
  if (currentWindow !== undefined) {
    onReady?.();
    return;
  }
  windowStage.createSubWindow(windowName, (err, subWindow) => {
    if (err.code !== 0) {
      return;
    }
    onCreated(subWindow);
    subWindow.setWindowFocusable(false);
    subWindow.loadContentByName(routeName, (loadErr) => {
      if (loadErr.code !== 0) {
        onCreateFailed(subWindow);
        subWindow.destroyWindow();
        return;
      }
      setSubWindowTransparent(subWindow);
      subWindow.showWindow((showErr) => {
        if (showErr.code !== 0) {
          onCreateFailed(subWindow);
          subWindow.destroyWindow();
          return;
        }
        setSubWindowTransparent(subWindow);
        onReady?.();
      });
    });
  });
}
