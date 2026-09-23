import { window } from '@kit.ArkUI';
import { DoKitFloatingWindow } from '../components/DoKitFloatingWindow';
import { DoKitSubWindow } from './DoKitSubWindow';
import { DOKIT_OVERLAY_ROUTE_NAME, DOKIT_OVERLAY_WINDOW_NAME } from './DoKitSubWindowRoute';

@Entry({ routeName: DOKIT_OVERLAY_ROUTE_NAME })
@Component
struct DoKitSubWindowPage {
  aboutToAppear(): void {
    try {
      window.findWindow(DOKIT_OVERLAY_WINDOW_NAME).setWindowBackgroundColor('#00000000');
    } catch (_e) {
    }
  }

  onBackPress(): boolean | void {
    DoKitSubWindow.hide();
    return true;
  }

  build() {
    Stack() {
      DoKitFloatingWindow()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#00000000')
  }
}
