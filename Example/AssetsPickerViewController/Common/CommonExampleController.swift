//
//  CommonExampleController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 5/29/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import AssetsPickerViewController
import TinyLog

class CommonExampleController: UITableViewController {
    
    let kCellReuseIdentifier: String = UUID().uuidString
    lazy var imageManager = {
        return PHCachingImageManager()
    }()
    lazy var cellSize: CGSize = {
        return CGSize(width: self.view.bounds.width, height: 60)
    }()
    var assets = [PHAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = cellSize.height
        title = "\(type(of: self))"
        setupToolbarItems()
    }
    
    func setupToolbarItems() {
        let clearItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(pressedClear))
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let pickItem = UIBarButtonItem(title: "Pick", style: .plain, target: self, action: #selector(pressedPick))
        toolbarItems = [clearItem, spaceItem, pickItem]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    // MARK: - Delegates
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier) else {
            return UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: kCellReuseIdentifier)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let asset = assets[indexPath.row]
        
        // set title & summary
        cell.textLabel?.text = "[\(asset.mediaType == .image ? "Photo" : "Video")] \(asset.pixelWidth)x\(asset.pixelHeight)"
        cell.detailTextLabel?.text = "\(asset.creationDate?.description ?? "Unknown")"
        
        // set image
        let imageWidth = cellSize.height * UIScreen.main.scale
        imageManager.requestImage(for: asset, targetSize: CGSize(width: imageWidth, height: imageWidth), contentMode: .aspectFill, options: nil) { (image, info) in
            cell.imageView?.contentMode = .scaleAspectFill
            cell.imageView?.image = image
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension CommonExampleController {
    @objc func pressedClear(_ sender: Any) {
        assets.removeAll()
        tableView.reloadData()
    }
    @objc func pressedPick(_ sender: Any) {}
}

extension CommonExampleController: AssetsPickerViewControllerDelegate {
    
    func assetsPickerCannotAccessPhotoLibrary() {
        logw("Need permission to access photo library.")
    }
    
    func assetsPickerDidCancel() {
        logi("Cancelled.")
    }
    
    func assetsPicker(selected assets: [PHAsset]) {
        self.assets = assets
        tableView.reloadData()
        dismiss(animated: true)
    }
    
    func assetsPicker(shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        logi("shouldSelect: \(indexPath.row)")
        return true
    }
    
    func assetsPicker(didSelect asset: PHAsset, at indexPath: IndexPath) {
        logi("didSelect: \(indexPath.row)")
    }
    
    func assetsPicker(shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        logi("shouldDeselect: \(indexPath.row)")
        return true
    }
    
    func assetsPicker(didDeselect asset: PHAsset, at indexPath: IndexPath) {
        logi("didDeselect: \(indexPath.row)")
    }
    
    func assetsPicker(didDismissByCancelling byCancel: Bool) {
        logi("dismiss completed - byCancel: \(byCancel)")
    }
}

