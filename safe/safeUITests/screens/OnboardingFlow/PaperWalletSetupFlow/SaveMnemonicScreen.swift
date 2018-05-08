//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import XCTest
import CommonTestSupport

final class SaveMnemonicScreen {

    var isDisplayed: Bool {
        return title.exists
    }

    let title = XCUIApplication().staticTexts[LocalizedString("new_safe.paper_wallet.title")]
    let description = XCUIApplication().staticTexts["description"]
    let mnemonic = XCUIApplication().staticTexts["mnemonic"]
    let saveButton = XCUIApplication().buttons[LocalizedString("new_safe.paper_wallet.save")]
    let continueButton = XCUIApplication().buttons[LocalizedString("new_safe.paper_wallet.continue")]

}