//
//  AssetsPhotoFooterView.swift
//  Pods
//
//  Created by DragonCherry on 5/18/17.
//
//

import UIKit
import PureLayout

open class AssetsPhotoFooterView: UICollectionReusableView {
    
    private var didSetupConstraints: Bool = false
    
    private let countLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textAlignment = .center
        label.font = UIFont.systemFont(forStyle: .body)
        label.textColor = .darkText
        label.text = "TEST TEST"
        return label
    }()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(countLabel)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            countLabel.autoPinEdgesToSuperviewEdges()
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
    
    open func set(imageCount: Int, videoCount: Int) {
        var countText: String?
        if imageCount > 0 && videoCount > 0 {
            countText = String(format: String(key: "Footer_Assets"), imageCount, videoCount)
        } else if imageCount > 0 {
            countText = String(format: String(key: "Footer_Photos"), imageCount)
        } else if videoCount > 0 {
            countText = String(format: String(key: "Footer_Videos"), videoCount)
        } else {
            countText = String(format: String(key: "Footer_Assets"), 0, 0)
        }
        countLabel.text = countText
    }
}