//
//  PhotoCell.swift
//  GenericDataSource
//
//  Created by Andrea Prearo on 5/5/17.
//  Copyright © 2017 Andrea Prearo. All rights reserved.
//

import UIKit
import Photos
import Dimmer
import PureLayout

public protocol ThirdPartiesPhotoCellProtocol {
    func configure(item: PhotoViewModel)
    var isSelected: Bool { get set }
    var imageView: UIImageView { get }
    var count: Int { set get }
    var cellID: String { set get }
}

open class PhotoCell: UICollectionViewCell, ThirdPartiesPhotoCellProtocol {
    
    public var cellID: String = ""    
    
    public func configure(item: PhotoViewModel) {
        cellID = item.imageID
        //Configure ImageView Image
        downloadImage(url: item.url)
    }
    
    open override var isSelected: Bool {
        didSet { overlay.isHidden = !isSelected }
    }
    
    open let imageView: UIImageView = {
        let view = UIImageView.newAutoLayout()
        view.backgroundColor = UIColor(rgbHex: 0xF0F0F0)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    open var count: Int = 0 {
        didSet { overlay.countLabel.text = "\(count)" }
    }
    
    
    // MARK: - Views
    private var didSetupConstraints: Bool = false
    
    
    private let overlay: AssetsPhotoCellOverlay = {
        let overlay = AssetsPhotoCellOverlay.newAutoLayout()
        overlay.isHidden = true
        return overlay
    }()
    
    // MARK: - Lifecycle
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        contentView.configureForAutoLayout()
        contentView.addSubview(imageView)
        contentView.addSubview(overlay)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            
            contentView.autoPinEdgesToSuperviewEdges()
            
            imageView.autoPinEdgesToSuperviewEdges()
            
            overlay.autoPinEdgesToSuperviewEdges()
            
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    private func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    private func downloadImage(url: URL) {
        getDataFromUrl(url: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() {
                self.imageView.image = UIImage(data: data)
            }
        }
    }
}
