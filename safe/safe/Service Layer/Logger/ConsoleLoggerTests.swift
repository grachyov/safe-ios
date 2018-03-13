//
//  Copyright © 2018 Gnosis. All rights reserved.
//

import XCTest
@testable import safe

class ConsoleLoggerTests: XCTestCase {

    let logger = ConsoleLogger()

    func test_canLog() {
        logger.log("Test Log", level: .info, error: nil, file: #file, line: #line, function: #function)
    }

}
