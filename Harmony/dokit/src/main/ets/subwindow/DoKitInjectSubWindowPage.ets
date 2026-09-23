import { window } from '@kit.ArkUI';
import { DoKitInjectOverlay } from '../components/DoKitInjectOverlay';
import { DOKIT_INJECT_WINDOW_NAME, DOKIT_INJECT_ROUTE_NAME } from './DoKitSubWindowRoute';

@Entry({ routeName: DOKIT_INJECT_ROUTE_NAME })
@Component
struct DoKitInjectSubWindowPage {
  aboutToAppear(): void {
    try {
      window.findWindow(DOKIT_INJECT_WINDOW_NAME).setWindowBackgroundColor('#00000000');
    } catch (_e) {
    }
  }

  build() {
    Stack() {
      DoKitInjectOverlay()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#00000000')
    .hitTestBehavior(HitTestMode.None)
  }
}
