//
//  AddTokenNavigationBar.swift
//  AlphaWallet
//
//  Created by Rajan Maharjan on 26/01/2024.
//

import UIKit

class AddTokenNavigationBar: UIView {
    
    lazy var wrapperView: UIView = {
        var viw = UIView()
        viw.backgroundColor = .systemBackground
        viw.translatesAutoresizingMaskIntoConstraints  = false
        return viw
    }()
    
    lazy var titleLabel: UILabel = {
        let label  = UILabel()
        label.clipsToBounds = true
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 1
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "close"), for: .normal)
        return button
    }()
    
    override func layoutSubviews() {
        setupView()
        setUpConstraints()
    }
    
    private func setupView() {
        self.backgroundColor = .systemBackground
        self.addSubview(wrapperView)
        [titleLabel, closeButton].forEach { wrapperView.addSubview($0) }
    }
    
    private func setUpConstraints() {
        wrapperView.anchor(top: self.topAnchor, leading: self.safeAreaLayoutGuide.leadingAnchor, bottom: self.safeAreaLayoutGuide.bottomAnchor, trailing: self.safeAreaLayoutGuide.trailingAnchor )
        titleLabel.anchor(top: nil, leading: wrapperView.leadingAnchor, bottom: nil, trailing: closeButton.leadingAnchor, padding: .init(top: 0, left: 16, bottom: 0, right: 16))
        titleLabel.centerYAnchor.constraint(equalTo: wrapperView.centerYAnchor).isActive = true
        closeButton.anchor(top: wrapperView.topAnchor, leading: titleLabel.trailingAnchor, bottom: wrapperView.bottomAnchor, trailing: wrapperView.trailingAnchor, padding: .init(top: 8, left: 8, bottom: 8, right: 8), size: .init(width: 50, height: 50))
        
    }
    
}
