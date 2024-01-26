//
//  AddTokenViewCoordinator.swift
//  AlphaWallet
//
//  Created by Rajan Maharjan  on 25/01/2024.
//

import Foundation
import UIKit
import AlphaWalletFoundation
import FloatingPanel

protocol AddTokenViewCoordinatorDelegate: AnyObject {
    func didDismiss(in coordinator: AddTokenViewCoordinator)
}

class AddTokenViewCoordinator: NSObject, Coordinator {
    private let navigationController: UINavigationController
    var coordinators: [Coordinator] = []
    weak var delegate: AddTokenViewCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    func start() {
        let rootViewController = AddTokenViewController()
        let panel = FloatingPanelController(isPanEnabled: false)
        panel.layout = FullScreenScrollableFloatingPanelLayout()
        panel.set(contentViewController: rootViewController)
        panel.shouldDismissOnBackdrop = true
        panel.delegate = self
        navigationController.present(panel, animated: true)
    }
}

extension AddTokenViewCoordinator: FloatingPanelControllerDelegate {
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        delegate?.didDismiss(in: self)
    }
}
