//
//  AddTokenTableViewCell.swift
//  AlphaWallet
//
//  Created by Rajan Maharjan on 26/01/2024.
//

import UIKit
import SDWebImage

class AddTokenTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = String(describing: AddTokenTableViewCell.self)
    
    let wrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let tokenImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.cornerRadius = 25
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    let tokenLabel: UILabel = {
        let label  = UILabel()
        label.clipsToBounds = true
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 1
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var imageName = String() {
        didSet {
            tokenImageView.sd_imageTransition = .fade
            tokenImageView.sd_setImage(with: URL(string: imageName), placeholderImage: UIImage(named: "iconsTokensPlaceholder"))
        }
    }
    
    var tokenName = String() {
        didSet {
            tokenLabel.text = tokenName
        }
    }

    var dataToDisplay: TokenData? {
        didSet {
            tokenName = dataToDisplay?.name ?? ""
            imageName = dataToDisplay?.logoURI ?? ""
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupViews()
        setupConstraint()
    }
    
    private func setupViews() {
        self.selectionStyle = .none
        self.addSubview(wrapperView)
        [tokenImageView, tokenLabel].forEach { wrapperView.addSubview($0) }
    }
    
    private func setupConstraint() {
        wrapperView.anchor(top: self.topAnchor, leading: self.leadingAnchor, bottom: self.bottomAnchor, trailing: self.trailingAnchor )
        tokenImageView.anchor(top: wrapperView.topAnchor, leading: wrapperView.leadingAnchor, bottom: wrapperView.bottomAnchor, trailing: tokenLabel.leadingAnchor, padding: .init(top: 10, left: 16, bottom: 10, right: 16), size: .init(width: 50, height: 50))
        tokenLabel.anchor(top: nil, leading: tokenImageView.trailingAnchor, bottom: nil, trailing: wrapperView.trailingAnchor, padding: .init(top: 4, left: 16, bottom: 4, right: 4))
        tokenLabel.centerYAnchor.constraint(equalTo: wrapperView.centerYAnchor).isActive = true
    }
}
