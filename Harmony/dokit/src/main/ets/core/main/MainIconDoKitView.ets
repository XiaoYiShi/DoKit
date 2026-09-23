import { DoKitViewManager } from '../DoKitViewManager';

/** 主入口悬浮球，对标 Android kit/main/MainIconDoKitView */
@Component
export struct MainIconDoKitView {
  ballSize: number = 58;
  @Link ballX: number;
  @Link ballY: number;
  containerWidth: number = 0;
  containerHeight: number = 0;
  subWindowIconIdle: boolean = false;
  onChromeDragStart?: () => void;
  onChromeDragEnd?: () => void;
  onChromeLayoutSync?: () => void;
  dragThreshold: number = 3;
  private readonly panJumpThresholdVp: number = 72;
  private readonly localPad: number = 12;

  @State private dragMoved: boolean = false;
  @State private chromeDragActive: boolean = false;
  @State private lastPanOffsetX: number = 0;
  @State private lastPanOffsetY: number = 0;

  private isSubWindowMode(): boolean {
    return this.onChromeDragStart !== undefined;
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.min(Math.max(value, min), max);
  }

  private getMaxBallX(): number {
    return Math.max(0, this.containerWidth - this.ballSize);
  }

  private getMaxBallY(): number {
    return Math.max(0, this.containerHeight - this.ballSize);
  }

  private usesSmallChromeWindow(): boolean {
    return this.isSubWindowMode() && this.subWindowIconIdle && !this.chromeDragActive;
  }

  private getDisplayX(): number {
    return this.usesSmallChromeWindow() ? this.localPad : this.ballX;
  }

  private getDisplayY(): number {
    return this.usesSmallChromeWindow() ? this.localPad : this.ballY;
  }

  private resetPanBaseline(offsetX: number, offsetY: number): void {
    this.lastPanOffsetX = offsetX;
    this.lastPanOffsetY = offsetY;
  }

  private beginChromeDragIfNeeded(): void {
    if (!this.isSubWindowMode() || !this.subWindowIconIdle || this.chromeDragActive) {
      return;
    }
    this.chromeDragActive = true;
    this.onChromeDragStart?.();
  }

  private onBallMove(event?: GestureEvent): void {
    if (!event) {
      return;
    }
    if (this.isSubWindowMode() && this.subWindowIconIdle && !this.chromeDragActive) {
      if (Math.abs(event.offsetX) <= this.dragThreshold && Math.abs(event.offsetY) <= this.dragThreshold) {
        return;
      }
      this.beginChromeDragIfNeeded();
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
    if (Math.abs(deltaX) > this.dragThreshold || Math.abs(deltaY) > this.dragThreshold) {
      this.dragMoved = true;
    }
    if (deltaX !== 0 || deltaY !== 0) {
      this.ballX = this.clamp(this.ballX + deltaX, 0, this.getMaxBallX());
      this.ballY = this.clamp(this.ballY + deltaY, 0, this.getMaxBallY());
    }
  }

  private endChromeDragIfNeeded(): void {
    if (!this.chromeDragActive) {
      return;
    }
    this.chromeDragActive = false;
    this.onChromeDragEnd?.();
  }

  private applyEdgeSnap(): void {
    const centerX = this.ballX + this.ballSize / 2;
    const targetX = centerX < this.containerWidth / 2 ? 16 : this.getMaxBallX() - 16;
    this.ballX = targetX;
    this.ballY = this.clamp(this.ballY, 0, this.getMaxBallY());
  }

  private onBallUp(event?: GestureEvent): void {
    const didDrag = event !== undefined &&
      (Math.abs(event.offsetX) > this.dragThreshold || Math.abs(event.offsetY) > this.dragThreshold || this.dragMoved);
    if (didDrag) {
      if (this.isSubWindowMode()) {
        this.applyEdgeSnap();
        this.endChromeDragIfNeeded();
        this.onChromeLayoutSync?.();
      } else {
        animateTo({ duration: 240, curve: Curve.EaseOut }, () => {
          this.applyEdgeSnap();
        });
      }
      setTimeout(() => {
        this.dragMoved = false;
      }, this.isSubWindowMode() ? 50 : 260);
      return;
    }
    this.endChromeDragIfNeeded();
  }

  build() {
    Stack() {
      Image($r('app.media.dk_doraemon'))
        .width(this.ballSize)
        .height(this.ballSize)
        .objectFit(ImageFit.Contain)
        .position({ x: this.getDisplayX(), y: this.getDisplayY() })
        .onClick(() => {
          if (this.dragMoved) {
            return;
          }
          DoKitViewManager.attachToolPanel();
        })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(this.isSubWindowMode() || this.chromeDragActive ? HitTestMode.Default : HitTestMode.Transparent)
    .gesture(
      PanGesture({ direction: PanDirection.All, fingers: 1, distance: 1 })
        .onActionStart(() => {
          this.dragMoved = false;
          this.resetPanBaseline(0, 0);
        })
        .onActionUpdate((event?: GestureEvent) => {
          this.onBallMove(event);
        })
        .onActionEnd((event?: GestureEvent) => {
          this.onBallUp(event);
        })
        .onActionCancel(() => {
          this.resetPanBaseline(0, 0);
          this.endChromeDragIfNeeded();
          this.onChromeLayoutSync?.();
        })
    )
  }
}
