import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DoKitSubWindow } from '@didi-hummer/dokit';
import { App } from '../App';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

/** 对标 Android Application 入口，DoKit 初始化委托给 App.onCreate */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'DoKit Demo onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'DoKit Demo onWindowStageCreate');
    const abilityContext = this.context;
    if (abilityContext !== null && abilityContext !== undefined) {
      App.onCreate(abilityContext);
    } else {
      hilog.error(DOMAIN, TAG, 'UIAbilityContext is null, skip DoKit init');
    }
    DoKitSubWindow.attach(windowStage);
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load Index. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      DoKitSubWindow.show();
    });
  }
}
