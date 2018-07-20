//
//  ConfirmButton.swift
//  AssetsPickerViewController
//
//  Created by Pablo Paciello on 4/20/18.
//

import UIKit

public class ConfirmButtonView: UIView {
    
    private var didSetupConstraints = false
    private let button = UIButton(type: .system)
    private let height: CGFloat = 50
    
    public var buttonPressedHandler: (() -> ())?
    
    required public init(title: String, color: UIColor = UIColor(red: 255/255, green: 72/255, blue: 149/255, alpha: 1)) {
        super.init(frame: .zero)
        
        layer.cornerRadius = height / 2
        clipsToBounds = true
        
        addSubview(button)
        button.setTitle(title.uppercased(), for: .normal)
        button.addTarget(self, action: #selector(pressed), for: .touchUpInside)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func updateConstraints() {
        if !didSetupConstraints {
            autoSetDimension(.height, toSize: height)
            button.autoPinEdgesToSuperviewEdges()
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
        
    @objc fileprivate func pressed() {
        button.isEnabled = false
        buttonPressedHandler?()
    }
    
    func enableConfirmButton() {
        button.isEnabled = true
    }
}
