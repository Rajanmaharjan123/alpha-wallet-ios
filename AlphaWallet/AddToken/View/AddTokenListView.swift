//
//  AddTokenListView.swift
//  AlphaWallet
//
//  Created by Rajan Maharjan on 26/01/2024.
//

import UIKit

class AddTokenListView: UIView {
    
    lazy var wrapperView: UIView = {
        var viw = UIView()
        viw.backgroundColor = .systemBackground
        viw.translatesAutoresizingMaskIntoConstraints  = false
        return viw
    }()
    
    lazy var navigationBar: AddTokenNavigationBar = {
        let nav = AddTokenNavigationBar()
        return nav
    }()
    
    lazy var tokenTableView: UITableView = {
        let tbl = UITableView(frame: .zero, style: .plain)
        tbl.backgroundColor = .systemBackground
        tbl.isUserInteractionEnabled = true
        return tbl
    }()
    
    var title = String() {
        didSet {
            navigationBar.titleLabel.text = title
        }
    }
    
    var tokenList = [TokenData]() {
        didSet {
            tokenTableView.reloadData()
        }
    }
    
    var backButtonAction: (() -> Void)?
    
    override func layoutSubviews() {
        setupView()
        setUpTableView()
        setUpConstraints()
    }
    
    private func setupView() {
        self.backgroundColor = .systemBackground
        self.addSubview(wrapperView)
        [navigationBar,tokenTableView].forEach { wrapperView.addSubview($0) }
        navigationBar.closeButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
    }
    
    private func setUpTableView() {
        tokenTableView.backgroundColor = .systemBackground
        tokenTableView.dataSource = self
        tokenTableView.delegate = self
        tokenTableView.separatorStyle = .singleLine
        tokenTableView.bounces = false
        tokenTableView.rowHeight = UITableView.automaticDimension
        tokenTableView.register(AddTokenTableViewCell.self, forCellReuseIdentifier: AddTokenTableViewCell.reuseIdentifier)
    }
    
    private func setUpConstraints() {
        wrapperView.anchor(top: self.topAnchor, leading: self.safeAreaLayoutGuide.leadingAnchor, bottom: self.safeAreaLayoutGuide.bottomAnchor, trailing: self.safeAreaLayoutGuide.trailingAnchor )
        navigationBar.anchor(top: wrapperView.topAnchor, leading: wrapperView.leadingAnchor, bottom: tokenTableView.topAnchor, trailing: wrapperView.trailingAnchor)
        tokenTableView.anchor(top: navigationBar.bottomAnchor, leading: wrapperView.leadingAnchor, bottom: wrapperView.bottomAnchor, trailing: wrapperView.trailingAnchor)
    }
    
    @objc func backButtonTapped() {
        self.backButtonAction?()
    }
    
}

extension AddTokenListView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tokenList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddTokenTableViewCell.reuseIdentifier, for: indexPath) as? AddTokenTableViewCell else {
            fatalError()
        }
        cell.dataToDisplay = tokenList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
    }
    
}
