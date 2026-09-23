import { CustomViewRegistry } from './CustomViewRegistry';
import { DoKitViewManager, ViewConfig } from './DoKitViewManager';
import { DoKitInjectSubWindow } from '../subwindow/DoKitInjectSubWindow';

/** 业务 inject 浮窗：idle 贴 SubWindow，拖拽全屏跟手（仅 DoKitInjectOverlay 使用） */
@Component
export struct ViewConfigDoKitView {
  @Prop config: ViewConfig = new ViewConfig('', false);
  containerWidth: number = 0;
  containerHeight: number = 0;
  injectUnionInOneWindow: boolean = false;
  chromeOriginX: number = 0;
  chromeOriginY: number = 0;
  onInjectDragStart?: () => void;
  onInjectDragEnd?: () => void;
  onInjectLayoutSync?: () => void;

  private readonly dragThreshold: number = 3;
  private readonly edgeMargin: number = 16;
  private readonly localPad: number = 12;
  private readonly panJumpThresholdVp: number = 72;

  @State private viewX: number = 0;
  @State private viewY: number = 0;
  @State private viewWidth: number = 0;
  @State private viewHeight: number = 0;
  @State private dragMoved: boolean = false;
  @State private injectDragActive: boolean = false;
  @State private lastPanOffsetX: number = 0;
  @State private lastPanOffsetY: number = 0;
  @State private positionInitialized: boolean = false;

  private toNumber(value?: Length): number {
    if (value === undefined) {
      return 0;
    }
    return Number(value);
  }

  aboutToAppear(): void {
    this.viewX = this.toNumber(this.config.viewPoint.x);
    this.viewY = this.toNumber(this.config.viewPoint.y);
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.min(Math.max(value, min), max);
  }

  private getMaxX(): number {
    return Math.max(0, this.containerWidth - this.viewWidth);
  }

  private getMaxY(): number {
    return Math.max(0, this.containerHeight - this.viewHeight);
  }

  private getIdleUnionOffsetX(): number {
    if (!this.injectUnionInOneWindow) {
      return 0;
    }
    return this.toNumber(this.config.viewPoint.x) - this.chromeOriginX;
  }

  private getIdleUnionOffsetY(): number {
    if (!this.injectUnionInOneWindow) {
      return 0;
    }
    return this.toNumber(this.config.viewPoint.y) - this.chromeOriginY;
  }

  private getPositionX(): number {
    if (this.injectDragActive) {
      return this.viewX;
    }
    return this.localPad + this.getIdleUnionOffsetX();
  }

  private getPositionY(): number {
    if (this.injectDragActive) {
      return this.viewY;
    }
    return this.localPad + this.getIdleUnionOffsetY();
  }

  private resetPanBaseline(offsetX: number, offsetY: number): void {
    this.lastPanOffsetX = offsetX;
    this.lastPanOffsetY = offsetY;
  }

  private getLayoutChromeWidth(): number {
    return this.config.chromeWidthVp > 0 ? this.config.chromeWidthVp : 280;
  }

  private getLayoutChromeHeight(): number {
    return this.config.chromeHeightVp > 0 ? this.config.chromeHeightVp : 80;
  }

  private lockChromeSize(width: number, height: number): void {
    if (width <= 0 || height <= 0) {
      return;
    }
    const prevW = this.config.chromeWidthVp;
    const prevH = this.config.chromeHeightVp;
    this.config.chromeWidthVp = Math.max(this.config.chromeWidthVp, width);
    this.config.chromeHeightVp = Math.max(this.config.chromeHeightVp, height);
    DoKitViewManager.updateViewChromeSize(this.config.name, this.config.chromeWidthVp, this.config.chromeHeightVp);
    if (this.config.chromeWidthVp > prevW || this.config.chromeHeightVp > prevH) {
      this.onInjectLayoutSync?.();
    }
  }

  private commitViewPointToWindow(): void {
    DoKitViewManager.updateViewPoint(this.config.name, this.viewX, this.viewY);
    this.config.viewPoint = { x: this.viewX, y: this.viewY };
  }

  private beginInjectDragIfNeeded(): void {
    if (this.injectDragActive || DoKitInjectSubWindow.isMainWindowChromeActive()) {
      return;
    }
    this.injectDragActive = true;
    this.onInjectDragStart?.();
  }

  private endInjectDragIfNeeded(): void {
    if (!this.injectDragActive) {
      return;
    }
    this.injectDragActive = false;
    this.onInjectDragEnd?.();
  }

  private initPositionIfNeeded(): void {
    if (this.positionInitialized || this.containerWidth <= 0 || this.viewWidth <= 0) {
      return;
    }
    this.viewX = this.toNumber(this.config.viewPoint.x);
    this.viewY = this.toNumber(this.config.viewPoint.y);
    this.viewX = this.clamp(this.viewX, 0, this.getMaxX());
    this.viewY = this.clamp(this.viewY, 0, this.getMaxY());
    this.positionInitialized = true;
    this.commitViewPointToWindow();
    this.onInjectLayoutSync?.();
  }

  private onPanMove(event?: GestureEvent): void {
    if (!event) {
      return;
    }
    if (!this.injectDragActive && !DoKitInjectSubWindow.isMainWindowChromeActive()) {
      if (Math.abs(event.offsetX) <= this.dragThreshold && Math.abs(event.offsetY) <= this.dragThreshold) {
        return;
      }
      this.beginInjectDragIfNeeded();
      this.resetPanBaseline(event.offsetX, event.offsetY);
      return;
    }
    const deltaX = event.offsetX - this.lastPanOffsetX;
    const deltaY = event.offsetY - this.lastPanOffsetY;
    if ((this.lastPanOffsetX !== 0 || this.lastPanOffsetY !== 0) &&
      (Math.abs(deltaX) > this.panJumpThresholdVp || Math.abs(deltaY) > this.panJumpThresholdVp)) {
      this.resetPanBaseline(event.offsetX, event.offsetY);
      return;
    }
    this.resetPanBaseline(event.offsetX, event.offsetY);
    if (Math.abs(deltaX) <= this.dragThreshold && Math.abs(deltaY) <= this.dragThreshold) {
      return;
    }
    this.dragMoved = true;
    this.viewX = this.clamp(this.viewX + deltaX, 0, this.getMaxX());
    this.viewY = this.clamp(this.viewY + deltaY, 0, this.getMaxY());
  }

  private onPanEnd(event?: GestureEvent): void {
    const didDrag = event !== undefined &&
      (Math.abs(event.offsetX) > this.dragThreshold || Math.abs(event.offsetY) > this.dragThreshold || this.dragMoved);
    if (didDrag) {
      const centerX = this.viewX + this.viewWidth / 2;
      const targetX = centerX < this.containerWidth / 2 ? this.edgeMargin : this.getMaxX() - this.edgeMargin;
      const targetY = this.clamp(this.viewY, 0, this.getMaxY());
      this.viewX = targetX;
      this.viewY = targetY;
      this.commitViewPointToWindow();
      this.endInjectDragIfNeeded();
      setTimeout(() => {
        this.dragMoved = false;
      }, 50);
      return;
    }
    this.endInjectDragIfNeeded();
  }

  build() {
    Stack() {
      Stack() {
        CustomViewRegistry.getBuilder(this.config.name)?.builder(this.config.params, this.config.closeHandler)
      }
      .width(this.getLayoutChromeWidth())
      .height(this.getLayoutChromeHeight())
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        this.viewWidth = Number(newValue.width);
        this.viewHeight = Number(newValue.height);
        this.lockChromeSize(this.viewWidth, this.viewHeight);
        this.initPositionIfNeeded();
      })
      .gesture(
        PanGesture({ direction: PanDirection.All, fingers: 1, distance: 1 })
          .onActionStart(() => {
            this.dragMoved = false;
            this.resetPanBaseline(0, 0);
          })
          .onActionUpdate((event?: GestureEvent) => {
            this.onPanMove(event);
          })
          .onActionEnd((event?: GestureEvent) => {
            this.onPanEnd(event);
          })
          .onActionCancel(() => {
            this.resetPanBaseline(0, 0);
            this.endInjectDragIfNeeded();
            this.onInjectLayoutSync?.();
          })
      )
      .position({ x: this.getPositionX(), y: this.getPositionY() })
      .hitTestBehavior(HitTestMode.Default)
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
