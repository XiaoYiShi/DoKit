import { window } from '@kit.ArkUI';
import { DoKitPerformanceOverlay } from '../components/DoKitPerformanceOverlay';
import { DOKIT_PERFORMANCE_WINDOW_NAME, DOKIT_PERFORMANCE_ROUTE_NAME } from './DoKitSubWindowRoute';

@Entry({ routeName: DOKIT_PERFORMANCE_ROUTE_NAME })
@Component
struct DoKitPerformanceSubWindowPage {
  aboutToAppear(): void {
    try {
      window.findWindow(DOKIT_PERFORMANCE_WINDOW_NAME).setWindowBackgroundColor('#00000000');
    } catch (_e) {
    }
  }

  build() {
    Stack() {
      DoKitPerformanceOverlay()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#00000000')
    .hitTestBehavior(HitTestMode.None)
  }
}
