//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest

class UITestCase: XCTestCase {

    let application = Application()
    let password = "11111A"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func givenUnlockedAppSetup() {
        application.resetAllContentAndSettings()
        application.setPassword(password)
        application.start()
        let unlock = UnlockScreen()
        unlock.enterPassword(password)
    }

    func givenNewSafeSetup() {
        givenUnlockedAppSetup()
        let setupOptions = SetupSafeOptionsScreen()
        setupOptions.newSafe.tap()
    }

    func givenBrowserExtensionSetup() {
        givenNewSafeSetup()
        let newSafe = NewSafeScreen()
        newSafe.browserExtension.element.tap()
    }

}