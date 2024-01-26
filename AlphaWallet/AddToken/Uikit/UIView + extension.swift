//
//  UIView + extension.swift
//  AlphaWallet
//
//  Created by Rajan Maharjan on 26/01/2024.
//

import UIKit

extension UIView {
    typealias Attribute = NSLayoutConstraint.Attribute
    
    func addConstraintsWithFormat(format: String, view: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in view.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    func fillSuperview() {
        anchor(top: superview?.topAnchor, leading: superview?.leadingAnchor, bottom: superview?.bottomAnchor, trailing: superview?.trailingAnchor)
    }
    
    func anchorSize(to view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }
    
    func anchor(top: NSLayoutYAxisAnchor?, leading: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, trailing: NSLayoutXAxisAnchor?, padding: UIEdgeInsets = .zero, size: CGSize = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: padding.top).isActive = true
        }
        
        if let leading = leading {
            leadingAnchor.constraint(equalTo: leading, constant: padding.left).isActive = true
        }
        
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -padding.bottom).isActive = true
        }
        
        if let trailing = trailing {
            trailingAnchor.constraint(equalTo: trailing, constant: -padding.right).isActive = true
        }
        
        if size.width != 0 {
            widthAnchor.constraint(equalToConstant: size.width).isActive = true
        }
        
        if size.height != 0 {
            heightAnchor.constraint(equalToConstant: size.height).isActive = true
        }
    }
    
    @objc func constraintWithAttribute(_ attribute: Attribute, _ relation: NSLayoutConstraint.Relation, to constant: CGFloat, multiplier: CGFloat = 1.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: nil, attribute: .notAnAttribute, multiplier: multiplier, constant: constant)
    }
    
    @objc func constraintWithAttribute(_ attribute: Attribute, _ relation: NSLayoutConstraint.Relation, to otherAttribute: Attribute, of item: AnyObject? = nil, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: item ?? self, attribute: otherAttribute, multiplier: multiplier, constant: constant)
    }
    
    @objc func constraintWithAttribute(_ attribute: Attribute, _ relation: NSLayoutConstraint.Relation, to item: AnyObject, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: item, attribute: attribute, multiplier: multiplier, constant: constant)
    }
    
    func constraintsWithAttributes(_ attributes: [Attribute], _ relation: NSLayoutConstraint.Relation, to item: AnyObject, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> [NSLayoutConstraint] {
        return attributes.map { self.constraintWithAttribute($0, relation, to: item, multiplier: multiplier, constant: constant) }
    }
    
    func addTopBorder(with color: UIColor?, andWidth borderWidth: CGFloat) {
        let border = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        border.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: borderWidth)
        addSubview(border)
    }
    
    func addBottomBorder(with color: UIColor?, andWidth borderWidth: CGFloat) {
        let border = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        border.frame = CGRect(x: 0, y: frame.size.height - borderWidth, width: frame.size.width, height: borderWidth)
        addSubview(border)
    }
    
    func addLeftBorder(with color: UIColor?, andWidth borderWidth: CGFloat) {
        let border = UIView()
        border.backgroundColor = color
        border.frame = CGRect(x: 0, y: 0, width: borderWidth, height: frame.size.height)
        border.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        addSubview(border)
    }
    
    func addRightBorder(with color: UIColor?, andWidth borderWidth: CGFloat) {
        let border = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
        border.frame = CGRect(x: frame.size.width - borderWidth, y: 0, width: borderWidth, height: frame.size.height)
        addSubview(border)
    }
    
    func addBottomShadow(color: UIColor, radius: CGFloat, opacity: Float, shadowHeight: Int ) {
        layer.masksToBounds = false
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: 0 , height: shadowHeight)
        layer.shadowPath = UIBezierPath(rect: CGRect(x: 0,
                                                     y: bounds.maxY - layer.shadowRadius,
                                                     width: bounds.width,
                                                     height: layer.shadowRadius)).cgPath
    }
    
    func addTopShadow(color: UIColor, radius: CGFloat, opacity: Float, shadowHeight: Int){
        layer.masksToBounds = false
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: 0 , height: -shadowHeight)
        self.clipsToBounds = false
    }
    
    func addRightShadow(color: UIColor, radius: CGFloat, opacity: Float, shadowHeight: Int ) {
        layer.masksToBounds = false
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: 0 , height: shadowHeight)
        layer.shadowPath = UIBezierPath(rect: CGRect(x: 0,
                                                     y: 0,
                                                     width: bounds.width,
                                                     height: layer.shadowRadius)).cgPath
    }
    
    func addTopCurveBorders(withEdges edges: [UIRectEdge],
                    withColor color: UIColor,
                    withThickness thickness: CGFloat,
                    cornerRadius: CGFloat) {
      layer.borderColor = color.cgColor
      layer.borderWidth = thickness
      layer.cornerRadius = cornerRadius
      edges.forEach({ edge in
        
        switch edge {
          case .left:
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            
          case .right:
            layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            
          case .top:
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            
          case .bottom:
            layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            
          default:
            break
        }
      })
    }
}

extension UIView {
    func clearConstraints() {
        for subview in self.subviews {
            subview.clearConstraints()
        }
        self.removeConstraints(self.constraints)
    }
}

extension UIView {
    func addRipple() {
        let layer1 = CAShapeLayer()
        layer1.path = UIBezierPath.init(roundedRect: CGRect(x: 0, y: 0, width: 10, height: frame.height - 5),cornerRadius: 0).cgPath
        layer1.frame = CGRect(x: 0, y: 0, width: 10, height: frame.height - 5)
        layer1.position = self.center
        layer1.fillColor = UIColor.init(white: 1.0, alpha: 0.3).cgColor
        self.layer.addSublayer(layer1)
        
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.fromValue = 0.5
        fadeAnimation.toValue = 0.0
        fadeAnimation.duration = 0.3
        layer1.add(fadeAnimation, forKey: "opacity1")
        
        let positionAnimation = CABasicAnimation(keyPath: "transform.scale.x")
        positionAnimation.toValue = 13
        positionAnimation.fromValue = 1
        positionAnimation.duration = 0.3
        positionAnimation.fillMode = CAMediaTimingFillMode.removed
        layer1.add(positionAnimation, forKey: "transform1")
        
        let delayBlock = DispatchTime.now() + 0.2
        DispatchQueue.main.asyncAfter(deadline: delayBlock) {
            layer1.removeFromSuperlayer()
        }
    }
    
    func addRotationAnimation(with duration: Double) {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = 2 * Double.pi
        rotationAnimation.duration = duration
        rotationAnimation.repeatCount = Float.infinity
        layer.add(rotationAnimation, forKey: nil)
    }
    
    var bottomPadding: CGFloat {
        guard let window = UIApplication.shared.windows.first else {
            return 0
        }
        let safeFrame = window.safeAreaLayoutGuide.layoutFrame
        let bottomSafeAreaHeight = window.frame.maxY - safeFrame.maxY
        return bottomSafeAreaHeight
    }
    
    func addShadow(info: ShadowInfo) {
        layer.masksToBounds = false
        layer.shadowOffset = info.shadowOffset
        layer.shadowColor = info.shadowColor.cgColor
        layer.shadowRadius = info.shadowRadius
        layer.shadowOpacity = info.shadowOpacity

        let backgroundCGColor = backgroundColor?.cgColor
        backgroundColor = nil
        layer.backgroundColor =  backgroundCGColor
    }
    
    func createDottedLine(width: CGFloat, color: CGColor) {
       let caShapeLayer = CAShapeLayer()
       caShapeLayer.strokeColor = color
       caShapeLayer.lineWidth = width
       caShapeLayer.lineDashPattern = [2,3]
       let cgPath = CGMutablePath()
       let cgPoint = [CGPoint(x: 0, y: 0), CGPoint(x: self.frame.width, y: 0)]
       cgPath.addLines(between: cgPoint)
       caShapeLayer.path = cgPath
       layer.addSublayer(caShapeLayer)
    }
}

public class ShadowInfo {

    let shadowRadius: CGFloat
    let shadowOpacity: Float
    let shadowColor: UIColor
    let shadowOffset: CGSize

    public init(shadowRadius: CGFloat, shadowOpacity: Float, shadowColor: UIColor, shadowOffset: CGSize) {
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.shadowColor = shadowColor
        self.shadowOffset = shadowOffset
    }
    
}
