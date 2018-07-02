//
//  AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import TinyLog
import Photos

// MARK: - AssetsPickerViewControllerDelegate
@objc public protocol AssetsPickerViewControllerDelegate: class {
    @objc optional func assetsPickerDidCancel()
    @objc optional func assetsPickerCannotAccessPhotoLibrary()
    func assetsPicker(selected assets: [PHAsset])
    @objc optional func assetsPicker(didSelect asset: PHAsset, at indexPath: IndexPath)
    @objc optional func assetsPicker(shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool
    @objc optional func assetsPicker(didDeselect asset: PHAsset, at indexPath: IndexPath)
    @objc optional func assetsPicker(didDismissByCancelling byCancel: Bool)
}

// MARK: - AssetsPickerViewController
open class AssetsPickerViewController: UINavigationController {
    
    @objc open weak var pickerDelegate: AssetsPickerViewControllerDelegate?
    open var selectedAssets: [PHAsset] {
        return photoViewController.selectedAssets
    }
    
    open var isShowLog: Bool = false
    private var pickerConfig: AssetsPickerConfig!
    
    open lazy var photoViewController: AssetsPhotoViewController = {
        var config: AssetsPickerConfig!
        if let pickerConfig = self.pickerConfig {
            config = pickerConfig.prepare()
        } else {
            config = AssetsPickerConfig().prepare()
        }
        self.pickerConfig = config
        AssetsManager.shared.pickerConfig = config
        return AssetsPhotoViewController(pickerConfig: config)
    }()
    
    open lazy var albumViewController: AssetsAlbumViewController = {
        var config: AssetsPickerConfig!
        if let pickerConfig = self.pickerConfig {
            config = pickerConfig.prepare()
        } else {
            config = AssetsPickerConfig().prepare()
        }
        config.albumIsShowEmptyAlbum = false
        self.pickerConfig = config
        AssetsManager.shared.pickerConfig = config
        return AssetsAlbumViewController(pickerConfig: pickerConfig)
    }()
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    public init(pickerConfig: AssetsPickerConfig? = nil) {
        self.pickerConfig = pickerConfig
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    func commonInit() {
        TinyLog.isShowInfoLog = isShowLog
        TinyLog.isShowErrorLog = isShowLog
        AssetsManager.shared.registerObserver()
        albumViewController.delegate = self
        viewControllers = [albumViewController]
    }
    
    deinit {
        AssetsManager.shared.clear()
        logd("Released \(type(of: self))")
    }
    
}
extension AssetsPickerViewController: AssetsAlbumViewControllerDelegate {
    
    public func assetsAlbumViewControllerCancelled(controller: AssetsAlbumViewController) {}
    
    public func assetsAlbumViewController(controller: AssetsAlbumViewController, selected album: PHAssetCollection) {
        photoViewController.select(album: album)
        photoViewController.delegate = pickerDelegate
        if let nv = navigationController {
            nv.pushViewController(photoViewController, animated: true)
        } else {
            pushViewController(photoViewController, animated: true)
        }
    }
}
