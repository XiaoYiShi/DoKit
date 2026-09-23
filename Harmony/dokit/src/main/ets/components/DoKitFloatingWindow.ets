import { GlobalConfig } from '../config/GlobalConfig';
import { DokitMemoryConfig } from '../config/DokitMemoryConfig';
import { CustomDoKitViewRenderer, CustomFragmentRenderer, DoKitIntent, DoKitViewCloseHandler } from '../core/DoKitIntent';
import { DoKitViewManager } from '../core/DoKitViewManager';
import { buildUniversalFragment, SystemFragmentRegistry } from '../core/SystemFragmentRigistry';
import { DoKitManager } from '../core/DoKitManager';
import { MainIconDoKitView } from '../core/main/MainIconDoKitView';
import { ToolPanelDoKitView } from '../core/toolpanel/ToolPanelDoKitView';
import { PerformanceDokitViewManager } from '../kit/performance/PerformanceDokitViewManager';
import { FpsFrameCollector } from '../kit/performance/FpsFrameCollector';
import { DoKitOverlayState } from '../model/DoKitOverlayState';
import { KitGroup } from '../model/KitModels';
import { DoKitBundle } from '../core/FragmentRenderer';
import { DoKitInjectSubWindow } from '../subwindow/DoKitInjectSubWindow';
import { DoKitPerformanceSubWindow } from '../subwindow/DoKitPerformanceSubWindow';
import { window } from '@kit.ArkUI';
import display from '@ohos.display';
import { DoKitSubWindow } from '../subwindow/DoKitSubWindow';
import { DOKIT_OVERLAY_WINDOW_NAME } from '../subwindow/DoKitSubWindowRoute';

@Builder
function defaultCustomFullScreenPage(_fragmentClass: string, _bundle: DoKitBundle, _onClose: () => void) {
  Column().width('100%').height('100%')
}

/**
 * DoKit Overlay 根容器，对标 Android DoKitFrameLayout + DoKitViewManager 挂载点
 * 推荐 DoKitSubWindow；亦可 Stack() { 业务页; DoKitFloatingWindow() }
 */
@Component
export struct DoKitFloatingWindow {
  @BuilderParam customFullScreenPage: CustomFragmentRenderer = defaultCustomFullScreenPage;

  private readonly ballSize: number = 58;
  private readonly ballMarginRight: number = 16;
  private readonly ballMarginBottom: number = 108;
  private readonly iconChromePadVp: number = 12;

  @State private containerWidth: number = 0;
  @State private containerHeight: number = 0;
  @State private ballX: number = 0;
  @State private ballY: number = 0;
  @State private showPanel: boolean = false;
  @State private activeFragmentClass: string = '';
  @State private activeIsSystemFragment: boolean = false;
  @State private kitGroups: KitGroup[] = [];
  @State private showCustomFloat: boolean = false;
  @State private activeFloatingClass: string = '';
  @State private activeFloatingBundle: DoKitBundle = {};
  @State private fpsMonitorActive: boolean = false;
  @State private subWindowIconChrome: boolean = false;
  @State private subWindowDragExpanded: boolean = false;

  @StorageLink(DoKitOverlayState.ICON_VISIBLE_KEY) @Watch('syncSubWindowWindowChrome') iconVisible: boolean = true;
  @StorageLink(DoKitOverlayState.PANEL_OPEN_KEY) @Watch('onPanelOpenRequest') panelOpenRequest: boolean = false;
  /** 壳 EntryAbility 写入的状态栏高度（px）；用 StorageProp 才能跟着避让区变化刷新 */
  @StorageProp('topRectHeight') private topRectHeightPx: number = 0;

  aboutToAppear(): void {
    DoKitViewManager.setToolPanelChangeHandler((visible: boolean) => {
      if (visible) {
        this.kitGroups = DoKitManager.getKitGroups();
      }
      this.showPanel = visible;
      this.syncSubWindowWindowChrome();
    });
    SystemFragmentRegistry.setOpenHandler((fragmentClass: string, isSystemFragment: boolean) => {
      this.openFragment(fragmentClass, isSystemFragment);
    });
    SystemFragmentRegistry.setCloseHandler(() => {
      this.closeFragment();
    });
    DoKitViewManager.setFloatingAttachHandler((intent: DoKitIntent) => {
      this.activeFloatingClass = intent.targetClass;
      this.activeFloatingBundle = intent.bundle;
      this.showCustomFloat = true;
      this.syncSubWindowWindowChrome();
    });
    DoKitViewManager.setFloatingDetachHandler(() => {
      this.showCustomFloat = false;
      this.activeFloatingClass = '';
      this.activeFloatingBundle = {};
      this.syncSubWindowWindowChrome();
    });

    DoKitViewManager.setWindowRefreshHandler(() => {
      this.syncSubWindowWindowChrome();
      this.syncInjectSubWindow();
      this.syncPerformanceSubWindow();
    })

    PerformanceDokitViewManager.setOverlayChangeHandler(() => {
      this.fpsMonitorActive = DokitMemoryConfig.FPS_STATUS;
      this.syncPerformanceSubWindow();
    });
    this.fpsMonitorActive = DokitMemoryConfig.FPS_STATUS;
    this.syncPerformanceSubWindow();
    if (DoKitSubWindow.isShowing()) {
      this.initBallPosition();
    }
  }

  aboutToDisappear(): void {
    DoKitViewManager.setToolPanelChangeHandler(null);
    SystemFragmentRegistry.setOpenHandler(null);
    SystemFragmentRegistry.setCloseHandler(null);
    DoKitViewManager.setFloatingAttachHandler(null);
    DoKitViewManager.setFloatingDetachHandler(null);
    DoKitViewManager.setWindowRefreshHandler(null);
    PerformanceDokitViewManager.setOverlayChangeHandler(null);
  }

  private onPanelOpenRequest(): void {
    if (this.panelOpenRequest) {
      this.kitGroups = DoKitManager.getKitGroups();
      this.showPanel = true;
      DoKitOverlayState.clearPanelOpenRequest();
      this.syncSubWindowWindowChrome();
    }
  }

  private syncBallPositionFromIconChrome(): void {
    const uiContext = this.getUIContext();
    const leftPx = DoKitSubWindow.getIconChromeLeftPx();
    const topPx = DoKitSubWindow.getIconChromeTopPx();
    this.ballX = uiContext.px2vp(leftPx) + this.iconChromePadVp;
    this.ballY = uiContext.px2vp(topPx) + this.iconChromePadVp;
    this.clampBallToLayout(this.queryLayoutWidthVp(), this.queryLayoutHeightVp());
  }

  private clampBallToLayout(layoutWidth: number, layoutHeight: number): void {
    if (layoutWidth <= 0 || layoutHeight <= 0) {
      return;
    }
    const maxX = Math.max(0, layoutWidth - this.ballSize);
    const maxY = Math.max(0, layoutHeight - this.ballSize);
    this.ballX = this.clamp(this.ballX, 0, maxX);
    this.ballY = this.clamp(this.ballY, 0, maxY);
  }

  private beginChromeDrag(): void {
    if (DoKitSubWindow.isShowing() && this.subWindowIconChrome && !this.subWindowDragExpanded) {
      this.syncBallPositionFromIconChrome();
    }
    this.subWindowDragExpanded = true;
    DoKitSubWindow.layoutAsFullScreenChrome();
  }

  private endChromeDrag(): void {
    this.subWindowDragExpanded = false;
    this.syncSubWindowWindowChrome();
  }

  private queryLayoutWidthVp(): number {
    if (DoKitSubWindow.isShowing()) {
      try {
        return this.getUIContext().px2vp(display.getDefaultDisplaySync().width);
      } catch (_e) {
      }
    }
    return this.containerWidth;
  }

  private queryLayoutHeightVp(): number {
    if (DoKitSubWindow.isShowing()) {
      try {
        return this.getUIContext().px2vp(display.getDefaultDisplaySync().height);
      } catch (_e) {
      }
    }
    return this.containerHeight;
  }

  private syncSubWindowWindowChrome(): void {
    if (!DoKitSubWindow.isShowing()) {
      this.subWindowIconChrome = false;
      this.subWindowDragExpanded = false;
      return;
    }
    // 拖拽全屏态下禁止 sync（FPS 刷新等会反复触发），避免 resize 导致 Pan offset 跳变
    if (this.subWindowDragExpanded) {
      return;
    }
    if (this.shouldBlockHitThrough()) {
      this.subWindowIconChrome = false;
      DoKitSubWindow.layoutAsFullScreenChrome();
      return;
    }
    if (!this.iconVisible) {
      this.subWindowIconChrome = false;
      DoKitSubWindow.layoutAsHiddenChrome();
      return;
    }
    if (!this.ensureBallPositionReady()) {
      this.subWindowIconChrome = false;
      DoKitSubWindow.layoutAsFullScreenChrome();
      return;
    }
    this.subWindowIconChrome = true;
    const uiContext = this.getUIContext();
    const pad = this.iconChromePadVp;
    DoKitSubWindow.layoutAsIconChrome(
      uiContext.vp2px(this.ballX - pad),
      uiContext.vp2px(this.ballY - pad),
      uiContext.vp2px(this.ballSize + pad * 2),
      uiContext.vp2px(this.ballSize + pad * 2)
    );
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.min(Math.max(value, min), max);
  }

  private ensureBallPositionReady(): boolean {
    const layoutWidth = this.queryLayoutWidthVp();
    const layoutHeight = this.queryLayoutHeightVp();
    if (layoutWidth <= 0 || layoutHeight <= 0) {
      return false;
    }
    const maxX = Math.max(0, layoutWidth - this.ballSize);
    const maxY = Math.max(0, layoutHeight - this.ballSize);
    if (this.ballX === 0 && this.ballY === 0) {
      this.ballX = this.clamp(maxX - this.ballMarginRight, 0, maxX);
      this.ballY = this.clamp(maxY - this.ballMarginBottom, 0, maxY);
    } else {
      this.clampBallToLayout(layoutWidth, layoutHeight);
    }
    return true;
  }

  private initBallPosition(): void {
    if (this.subWindowDragExpanded) {
      return;
    }
    if (!this.ensureBallPositionReady()) {
      return;
    }
    this.syncSubWindowWindowChrome();
  }

  private closeFragment(): void {
    SystemFragmentRegistry.clearContent();
    this.activeFragmentClass = '';
    this.activeIsSystemFragment = false;
    this.syncSubWindowWindowChrome();
  }

  private openFragment(fragmentClass: string, isSystemFragment: boolean): void {
    DoKitViewManager.detachToolPanel();
    this.activeFragmentClass = fragmentClass;
    this.activeIsSystemFragment = isSystemFragment;
    this.syncSubWindowWindowChrome();
  }

  /**
   * 顶避让高度。对齐壳 WebViewPage：
   * 仅承载 DoKit 的窗口 layoutFullScreen（沉浸式）时加 topRectHeight；非全屏内容已在安全区，再加会空一截。
   * SubWindow 面板/拖拽全屏看子窗；Stack 叠层看主窗。读不到窗口属性时用 topRectHeight 兜底。
   */
  private statusBarHeightVp(): number {
    if (!this.shouldAvoidStatusBar()) {
      return 0;
    }
    return this.topRectHeightPx > 0 ? px2vp(this.topRectHeightPx) : 0;
  }

  private shouldAvoidStatusBar(): boolean {
    if (DoKitSubWindow.isShowing()) {
      try {
        if (window.findWindow(DOKIT_OVERLAY_WINDOW_NAME).getWindowProperties().isLayoutFullScreen) {
          return true;
        }
      } catch (_err) {
      }
      // 子窗 resize/layoutFullScreen 与 UI 刷新可能不同步，有全屏内容时仍避让
      if (this.shouldBlockHitThrough() || this.subWindowDragExpanded) {
        return true;
      }
      return false;
    }
    try {
      const stage = AppStorage.get<window.WindowStage>('windowStage');
      if (stage === undefined || stage === null) {
        return this.topRectHeightPx > 0;
      }
      return stage.getMainWindowSync().getWindowProperties().isLayoutFullScreen;
    } catch (_err) {
      return this.topRectHeightPx > 0;
    }
  }

  private shouldBlockHitThrough(): boolean {
    return this.activeFragmentClass.length > 0 || this.showPanel || this.showCustomFloat;
  }

  private syncPerformanceSubWindow(): void {
    if (!PerformanceDokitViewManager.isFpsOverlayOpen() &&
      !PerformanceDokitViewManager.isCpuOverlayOpen() &&
      !PerformanceDokitViewManager.isRamOverlayOpen()) {
      DoKitPerformanceSubWindow.hide();
      return;
    }
    DoKitPerformanceSubWindow.ensureShown();
  }

  private syncInjectSubWindow(): void {
    if (DoKitViewManager.getViewConfigList().length === 0) {
      DoKitInjectSubWindow.hide();
      return;
    }
    DoKitInjectSubWindow.ensureShown();
  }

  @Builder
  private buildUniversalContent() {
    Column() {
      if (this.activeIsSystemFragment) {
        buildUniversalFragment(this.activeFragmentClass, SystemFragmentRegistry.getBundle(), () => {
          SystemFragmentRegistry.finish();
        });
      } else {
        this.customFullScreenPage(this.activeFragmentClass, SystemFragmentRegistry.getBundle(), () => {
          SystemFragmentRegistry.finish();
        });
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.statusBarHeightVp() })
    .backgroundColor(Color.White)
    .hitTestBehavior(HitTestMode.Default)
  }

  build() {
    Stack() {
      if (GlobalConfig.debugMode) {
        if (this.activeFragmentClass.length > 0) {
          this.buildUniversalContent()
        } else if (this.showPanel) {
          Column() {
            ToolPanelDoKitView({
              kitGroups: this.kitGroups,
              onClose: () => {
                DoKitViewManager.detachToolPanel();
              }
            })
          }
          .width('100%')
          .height('100%')
          .padding({ top: this.statusBarHeightVp() })
          .backgroundColor(Color.White)
          .hitTestBehavior(HitTestMode.Default)
        } else if (this.iconVisible) {
          MainIconDoKitView({
            ballSize: this.ballSize,
            ballX: $ballX,
            ballY: $ballY,
            containerWidth: this.queryLayoutWidthVp(),
            containerHeight: this.queryLayoutHeightVp(),
            subWindowIconIdle: this.subWindowIconChrome && !this.subWindowDragExpanded,
            onChromeDragStart: DoKitSubWindow.isShowing() ? () => {
              this.beginChromeDrag();
            } : undefined,
            onChromeDragEnd: DoKitSubWindow.isShowing() ? () => {
              this.endChromeDrag();
            } : undefined,
            onChromeLayoutSync: DoKitSubWindow.isShowing() ? () => {
              this.syncSubWindowWindowChrome();
            } : undefined
          })
        }

        if (this.fpsMonitorActive) {
          FpsFrameCollector()
        }

      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
    .hitTestBehavior(this.shouldBlockHitThrough() ? HitTestMode.Default : HitTestMode.Transparent)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.containerWidth = Number(newValue.width);
      this.containerHeight = Number(newValue.height);
      this.initBallPosition();
    })
  }
}
