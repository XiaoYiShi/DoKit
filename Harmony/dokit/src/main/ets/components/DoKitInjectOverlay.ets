import { DoKitViewManager, ViewConfig } from '../core/DoKitViewManager';
import { ViewConfigDoKitView } from '../core/ViewConfigDoKitView';
import { DoKitInjectSubWindow } from '../subwindow/DoKitInjectSubWindow';

@Component
export struct DoKitInjectOverlay {
  @State private viewConfigs: ViewConfig[] = [];
  @State private injectDragExpanded: boolean = false;
  @State private chromeAnchorX: number = 0;
  @State private chromeAnchorY: number = 0;
  private readonly chromePadVp: number = 12;

  aboutToAppear(): void {
    DoKitViewManager.setInjectOverlayRefreshHandler(() => {
      this.viewConfigs = DoKitViewManager.getViewConfigList();
      this.refreshChromeAnchor();
      this.syncInjectWindowChrome();
    });
    this.viewConfigs = DoKitViewManager.getViewConfigList();
    this.refreshChromeAnchor();
    this.syncInjectWindowChrome();
  }

  aboutToDisappear(): void {
    DoKitViewManager.setInjectOverlayRefreshHandler(null);
  }

  private refreshChromeAnchor(): void {
    const bounds = DoKitInjectSubWindow.computeBoundsVp(this.viewConfigs);
    if (bounds === undefined) {
      return;
    }
    this.chromeAnchorX = bounds.minX;
    this.chromeAnchorY = bounds.minY;
  }

  private queryLayoutWidthVp(): number {
    const ui = this.getUIContext();
    return ui.px2vp(DoKitInjectSubWindow.queryMainWindowRectPx().widthPx);
  }

  private queryLayoutHeightVp(): number {
    const ui = this.getUIContext();
    return ui.px2vp(DoKitInjectSubWindow.queryMainWindowRectPx().heightPx);
  }

  private syncInjectWindowChrome(): void {
    if (this.viewConfigs.length === 0) {
      DoKitInjectSubWindow.hide();
      return;
    }
    if (this.injectDragExpanded) {
      return;
    }
    this.viewConfigs = DoKitViewManager.getViewConfigList();
    this.refreshChromeAnchor();
    DoKitInjectSubWindow.ensureShown(() => {
      const ui = this.getUIContext();
      DoKitInjectSubWindow.layoutFromViewConfigs(this.viewConfigs, this.chromePadVp, (vp: number) => ui.vp2px(vp));
    });
  }

  private beginInjectDrag(): void {
    this.injectDragExpanded = true;
    DoKitInjectSubWindow.layoutAsMainWindowChrome();
  }

  private endInjectDrag(): void {
    this.injectDragExpanded = false;
    this.viewConfigs = DoKitViewManager.getViewConfigList();
    this.refreshChromeAnchor();
    setTimeout(() => {
      this.syncInjectWindowChrome();
    }, 0);
  }

  build() {
    Stack() {
      ForEach(this.viewConfigs, (config: ViewConfig) => {
        ViewConfigDoKitView({
          config: config,
          containerWidth: this.queryLayoutWidthVp(),
          containerHeight: this.queryLayoutHeightVp(),
          injectUnionInOneWindow: this.viewConfigs.length > 1,
          chromeOriginX: this.chromeAnchorX,
          chromeOriginY: this.chromeAnchorY,
          onInjectDragStart: () => {
            this.beginInjectDrag();
          },
          onInjectDragEnd: () => {
            this.endInjectDrag();
          },
          onInjectLayoutSync: () => {
            this.syncInjectWindowChrome();
          }
        })
      }, (config: ViewConfig) => config.name)
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
