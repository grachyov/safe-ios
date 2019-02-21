//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import MultisigWalletApplication

class ReplaceBrowserExtensionCommand: MenuCommand {

    override var title: String {
        return LocalizedString("menu.action.change_browser_extension",
                               comment: "Change browser extension menu item")
    }

    override var isHidden: Bool {
        return !(FeatureFlagSettings.instance.isOn(RBEFeatureFlag.replaceBrowserExtension) &&
            ApplicationServiceRegistry.settingsService.replaceBrowserExtensionIsAvailable)
    }

    var commandFlow = ReplaceBrowserExtensionFlowCoordinator()

    override func run(flowCoordinator: FlowCoordinator) {
        flowCoordinator.enter(flow: commandFlow)
    }

}