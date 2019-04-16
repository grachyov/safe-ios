//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import MultisigWalletApplication

final class ConnectBrowserExtensionLaterCommand: MenuCommand {

    override var title: String {
        return LocalizedString("connect_browser_extension", comment: "Connect browser extension").capitalized
    }

    override var isHidden: Bool {
        return !ApplicationServiceRegistry.connectExtensionService.isAvailable
    }

    override init() {
        super.init()
        childFlowCoordinator = ConnectBrowserExtensionFlowCoordinator()
    }

}
