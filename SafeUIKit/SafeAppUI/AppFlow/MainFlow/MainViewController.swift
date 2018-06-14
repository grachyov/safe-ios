//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import MultisigWalletApplication

public class MainViewController: UIViewController {

    @IBOutlet weak var totalBalanceLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var receiveButton: UIButton!

    public static func create() -> MainViewController {
        return StoryboardScene.Main.mainViewController.instantiate()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        stylize(button: receiveButton)
        stylize(button: sendButton)
    }

    private func stylize(button: UIButton) {
        button.layer.borderColor = ColorName.borderGrey.color.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4
    }

}