//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import SafeUIKit

extension RBEIntroViewController {

    // MARK: Base States

    class State {

        func didEnter(controller: RBEIntroViewController) {}
        func willPush(controller: RBEIntroViewController, onTopOf topViewController: UIViewController) {}
        func handleError(_ error: Error, controller: RBEIntroViewController) {}
        func back(controller: RBEIntroViewController) {}
        func didLoad(controller: RBEIntroViewController) {}
        func start(controller: RBEIntroViewController) {}
        func didStart(controller: RBEIntroViewController) {}
        func retry(controller: RBEIntroViewController) {}

    }

    class CancellableState: State {

        override func back(controller: RBEIntroViewController) {
            controller.transition(to: CancellingState())
        }

    }

    class BaseErrorState: CancellableState {

        var error: Error

        init(error: Error) {
            self.error = error
        }

        override func retry(controller: RBEIntroViewController) {
            controller.transition(to: LoadingState())
        }

    }

    // MARK: Controller states

    class LoadingState: CancellableState {

        override func didEnter(controller: RBEIntroViewController) {
            controller.navigationItem.titleView = LoadingTitleView()
            controller.navigationItem.rightBarButtonItems = [controller.startButtonItem]
            controller.startButtonItem.isEnabled = false
            controller.feeCalculation = EthFeeCalculation()
        }

        override func willPush(controller: RBEIntroViewController, onTopOf topViewController: UIViewController) {
            topViewController.navigationItem.backBarButtonItem = controller.backButtonItem
        }

        override func handleError(_ error: Error, controller: RBEIntroViewController) {
            controller.transition(to: InvalidState(error: error))
        }

        override func didLoad(controller: RBEIntroViewController) {
            controller.transition(to: ReadyState())
        }

    }

    class InvalidState: BaseErrorState {

        override func didEnter(controller: RBEIntroViewController) {
            controller.navigationItem.titleView = nil
            if let data = controller.calculationData {
                let formatter = TokenNumberFormatter()
                formatter.tokenSymbol = data.currentBalance.code
                controller.feeCalculation.currentBalance.set(value: formatter.string(from: data.currentBalance.balance!))
                controller.feeCalculation.networkFee.set(value: formatter.string(from: data.networkFee.balance!))
                controller.feeCalculation.balance.set(value: formatter.string(from: data.balance.balance!))
            }
            if let calculationError = error as? FeeCalculationError, calculationError == .insufficientBalance {
                controller.feeCalculation.balance.set(error: calculationError)
                controller.feeCalculation.error = FeeCalculationErrorLine(text: calculationError.localizedDescription)
            } else {
                controller.feeCalculation.error = FeeCalculationErrorLine(text: error.localizedDescription).enableIcon()
            }
            controller.feeCalculation.update()
            controller.feeCalculationView.update()
        }

    }

    class CancellingState: State {}

    class ReadyState: CancellableState {

        override func start(controller: RBEIntroViewController) {
            controller.transition(to: StartingState())
        }

    }

    class StartingState: State {

        override func didStart(controller: RBEIntroViewController) {
            controller.transition(to: StartedState())
        }

        override func handleError(_ error: Error, controller: RBEIntroViewController) {
            controller.transition(to: ErrorState(error: error))
        }

    }

    class StartedState: State {}

    class ErrorState: BaseErrorState {}

}
