//
//  AddTokenViewController.swift
//  AlphaWallet
//
//  Created by Rajan Maharjan on 25/01/2024.
//

import UIKit

class AddTokenViewController: UIViewController {
    let viewModel: AddTokenViewModel

    private lazy var addTokenView = AddTokenListView()
    
    init() {
        self.viewModel = AddTokenViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.title = viewModel.title
        viewModel.fetchTokenList()
        bindView()
        bindViewModel()
        view.addSubview(addTokenView)
        addTokenView.title = viewModel.title
        addTokenView.fillSuperview()
    }
    
    private func bindView() {
        self.addTokenView.backButtonAction = {[weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
    }
    
    private func bindViewModel() {
        
        self.viewModel.addTokenGot = { [weak self] tokenList in
            guard let self = self else {return}
            DispatchQueue.main.async {
                self.addTokenView.tokenList = tokenList
            }
        }
    }
    
}

