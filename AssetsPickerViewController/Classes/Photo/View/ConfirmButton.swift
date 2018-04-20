//
//  ConfirmButton.swift
//  AssetsPickerViewController
//
//  Created by Pablo Paciello on 4/20/18.
//

import UIKit

class ConfirmButtonView: UIView {
    
    private var didSetupConstraints = false
    private let button = UIButton(type: .system)
    private let height: CGFloat = 50
    
    var buttonPressedHandler: (() -> ())?
    
    required init(title: String, color: UIColor = .green) {
        super.init(frame: .zero)
        
        layer.cornerRadius = height / 2
        clipsToBounds = true
        
        addSubview(button)
        button.setTitle(title.uppercased(), for: .normal)
        button.addTarget(self, action: #selector(pressed), for: .touchUpInside)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        if !didSetupConstraints {
            autoSetDimension(.height, toSize: height)
            button.autoPinEdgesToSuperviewEdges()
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
        
    @objc fileprivate func pressed() {
        buttonPressedHandler?()
    }

}
