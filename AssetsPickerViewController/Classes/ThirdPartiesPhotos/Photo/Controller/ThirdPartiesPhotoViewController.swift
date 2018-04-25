//
//  ThirdPartiesPhotoViewController.swift
//  AssetsPickerViewController
//
//  Created by Pablo Paciello on 4/19/18.
//

import UIKit
import Photos
import PhotosUI
import TinyLog
import Device

// MARK: - ThirdPartiesPhotoViewControllerDelegate
@objc public protocol ThirdPartiesPhotoViewControllerDelegate: class {
    func assetsPicker(selected assets: [PhotoViewModel])
    @objc optional func assetsPicker(didSelect asset: PhotoViewModel, at indexPath: IndexPath)
}

// MARK: - ThirdPartiesPhotoViewController
open class ThirdPartiesPhotoViewController: UIViewController {
    
    @objc open weak var delegate: ThirdPartiesPhotoViewControllerDelegate?
    
    // MARK: Properties
    fileprivate let cellReuseIdentifier: String = UUID().uuidString
    fileprivate let footerReuseIdentifier: String = UUID().uuidString
    fileprivate let confirmButton = ConfirmButtonView(title:NSLocalizedString("NEXT", comment: ""))
    fileprivate var selectedArray = [PhotoViewModel]()
    fileprivate var selectedMap = [String: PhotoViewModel]()
    fileprivate var didSetupConstraints = false
    fileprivate var didSetInitialPosition: Bool = false
    fileprivate var isPortrait: Bool = true
    fileprivate var leadingConstraint: NSLayoutConstraint?
    fileprivate var trailingConstraint: NSLayoutConstraint?
    /// Loading indicator
    fileprivate var indicator = UIActivityIndicatorView()
    
    fileprivate lazy var collectionView: UICollectionView = {
        let layout = AssetsPhotoLayout()
        self.updateLayout(layout: layout, isPortrait: UIApplication.shared.statusBarOrientation.isPortrait)
        layout.scrollDirection = .vertical
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.configureForAutoLayout()
        view.allowsMultipleSelection = true
        view.alwaysBounceVertical = true
        view.register(PhotoCell.classForCoder(), forCellWithReuseIdentifier: self.cellReuseIdentifier)
        view.register(AssetsPhotoFooterView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: self.footerReuseIdentifier)
        view.contentInset = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
        view.backgroundColor = UIColor.clear
        view.dataSource = self
        view.delegate = self
        view.remembersLastFocusedIndexPath = true
        if #available(iOS 10.0, *) {
            //view.prefetchDataSource = self
        }
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        
        return view
    }()
    
    private var selectedAssets: [PhotoViewModel] {
        return selectedArray
    }
    
    public var assets: [PhotoViewModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.activityIndicatorStop()
                self.collectionView.reloadData()
                self.updateFooter()
                self.setupPreSelectedItems()
            }
        }
    }
    
    public var maxItemsSelection: Int = 1
    public var albumTitle = NSLocalizedString("My Album", comment: "")
    
    // MARK: Lifecycle Methods
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public init(assets: [PhotoViewModel]) {
        self.init()
        self.assets = assets
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.addSubview(collectionView)
        view.addSubview(confirmButton)
        
        initialSetup()
        updateFooter()
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didSetInitialPosition {
            let count = assets.count
            if count > 0 {
                if self.collectionView.collectionViewLayout.collectionViewContentSize.height > 0 {
                    let lastRow = self.collectionView.numberOfItems(inSection: 0) - 1
                    self.collectionView.scrollToItem(at: IndexPath(row: lastRow, section: 0), at: .bottom, animated: false)
                }
            }
            didSetInitialPosition = true
        }
    }
    
    override open func updateViewConstraints() {
        if !didSetupConstraints {
            collectionView.autoPinEdge(toSuperviewEdge: .top)
            
            if #available(iOS 11.0, *) {
                leadingConstraint = collectionView.autoPinEdge(toSuperviewEdge: .leading, withInset: view.safeAreaInsets.left)
                trailingConstraint = collectionView.autoPinEdge(toSuperviewEdge: .trailing, withInset: view.safeAreaInsets.right)
            } else {
                leadingConstraint = collectionView.autoPinEdge(toSuperviewEdge: .leading)
                trailingConstraint = collectionView.autoPinEdge(toSuperviewEdge: .trailing)
            }
            collectionView.autoPinEdge(toSuperviewEdge: .bottom)
            
            //emptyView.autoPinEdgesToSuperviewEdges()
            confirmButton.autoAlignAxis(.vertical, toSameAxisOf: view)
            confirmButton.autoPin(toBottomLayoutGuideOf: self, withInset: 10)
            confirmButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            confirmButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
    
    @available(iOS 11.0, *)
    override open func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        leadingConstraint?.constant = view.safeAreaInsets.left
        trailingConstraint?.constant = -view.safeAreaInsets.right
        updateLayout(layout: collectionView.collectionViewLayout)
        logi("\(view.safeAreaInsets)")
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let isPortrait = size.height > size.width
        let contentSize = CGSize(width: size.width, height: size.height)
        if let photoLayout = collectionView.collectionViewLayout as? AssetsPhotoLayout {
            if let offset = photoLayout.translateOffset(forChangingSize: contentSize, currentOffset: collectionView.contentOffset, itemsCount: assets.count) {
                photoLayout.translatedOffset = offset
                logi("translated offset: \(offset)")
            }
            coordinator.animate(alongsideTransition: { (_) in
            }) { (_) in
                photoLayout.translatedOffset = nil
            }
        }
        updateLayout(layout: collectionView.collectionViewLayout, isPortrait: isPortrait)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationStatus()
    }
    
    deinit {
        logd("Released \(type(of: self))")
    }
}

// MARK: - Initial Setups
extension ThirdPartiesPhotoViewController {
    
    private func initialSetup() {
        view.backgroundColor = .white

        confirmButton.buttonPressedHandler = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.assetsPicker(selected: weakSelf.selectedArray)
        }
        confirmButton.isHidden = true
        
        // Init Activity Indicator
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        indicator.center = view.center
        view.addSubview(indicator)
        view.setNeedsUpdateConstraints()
    }
    
    open func activityIndicatorStartLoading() {
        indicator.startAnimating()
    }
    
    open func activityIndicatorStop() {
        indicator.stopAnimating()
    }
    
    private func setupPreSelectedItems() {
        if self.selectedArray.count > 0 {
            self.collectionView.performBatchUpdates({ [weak self] in
                self?.collectionView.reloadData()
                }, completion: { [weak self] (finished) in
                    guard let `self` = self else { return }
                    // initialize preselected assets
                    self.selectedArray.forEach({ [weak self] (asset) in
                        if let row = self?.assets.index(of: asset) {
                            let indexPathToSelect = IndexPath(row: row, section: 0)
                            self?.collectionView.selectItem(at: indexPathToSelect, animated: false, scrollPosition: UICollectionViewScrollPosition(rawValue: 0))
                        }
                    })
                    self.updateSelectionCount()
            })
        }
    }
}

// MARK: - Internal APIs for UI
extension ThirdPartiesPhotoViewController {
    
    private func updateLayout(layout: UICollectionViewLayout, isPortrait: Bool? = nil) {
        guard let photoLayout = layout as? AssetsPhotoLayout else { return }
        if let isPortrait = isPortrait {
            self.isPortrait = isPortrait
        }
        photoLayout.itemSize = self.isPortrait ? photoLayout.assetPortraitCellSize(forViewSize: UIScreen.main.portraitContentSize) : photoLayout.assetLandscapeCellSize(forViewSize: UIScreen.main.landscapeContentSize)
        photoLayout.minimumLineSpacing = self.isPortrait ? photoLayout.assetPortraitLineSpace : photoLayout.assetLandscapeLineSpace
        photoLayout.minimumInteritemSpacing = self.isPortrait ? photoLayout.assetPortraitInteritemSpace : photoLayout.assetLandscapeInteritemSpace
    }

    private func select(asset: PhotoViewModel, at indexPath: IndexPath) {
        if let _ = selectedMap[asset.imageID] {
            logw("Invalid status.")
            return
        }
        selectedArray.append(asset)
        selectedMap[asset.imageID] = asset
        
        // update selected UI
        guard var photoCell = collectionView.cellForItem(at: indexPath) as? ThirdPartiesPhotoCellProtocol else {
            logw("Invalid status.")
            return
        }
        photoCell.count = selectedArray.count
    }
    
    private func deselect(asset: PhotoViewModel, at indexPath: IndexPath) {
        guard let targetAsset = selectedMap[asset.imageID] else {
            logw("Invalid status.")
            return
        }
        guard let targetIndex = selectedArray.index(of: targetAsset) else {
            logw("Invalid status.")
            return
        }
        selectedArray.remove(at: targetIndex)
        selectedMap.removeValue(forKey: targetAsset.imageID)
        
        updateSelectionCount()
    }
    
    private func updateSelectionCount() {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        for visibleIndexPath in visibleIndexPaths {
            guard assets.count > visibleIndexPath.row else {
                logw("Referred wrong index\(visibleIndexPath.row) while asset count is \(assets.count).")
                break
            }
            if let selectedAsset = selectedMap[assets[visibleIndexPath.row].imageID], var photoCell = collectionView.cellForItem(at: visibleIndexPath) as? ThirdPartiesPhotoCellProtocol {
                if let selectedIndex = selectedArray.index(of: selectedAsset){
                    photoCell.count = selectedIndex + 1
                }
            }
        }
    }
    
    private func updateNavigationStatus() {
        confirmButton.isHidden = selectedArray.count == 0
        let imageCount = selectedArray.count
        
        if imageCount > 0 {
            title = String(imageCount).appending("/").appending(String(maxItemsSelection))
        } else {
            title = albumTitle
        }
    }
    
    private func updateFooter() {
        guard let footerView = collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionFooter).last as? AssetsPhotoFooterView else {
            return
        }
        footerView.set(imageCount: assets.count, videoCount: 0)
    }
}

// MARK: - UICollectionViewDelegate
extension ThirdPartiesPhotoViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return selectedArray.count < maxItemsSelection
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = assets[indexPath.row]
        select(asset: asset, at: indexPath)
        updateNavigationStatus()
        delegate?.assetsPicker?(didSelect: asset, at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let asset = assets[indexPath.row]
        deselect(asset: asset, at: indexPath)
        updateNavigationStatus()
        //delegate?.assetsPicker?(controller: picker, didDeselect: asset, at: indexPath)
    }
}

// MARK: - UICollectionViewDataSource
extension ThirdPartiesPhotoViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard var photoCell = cell as? ThirdPartiesPhotoCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return
        }
        
        let asset = assets[indexPath.row]
        
        if let selectedAsset = selectedMap[asset.imageID] {
            // update cell UI as selected
            if let targetIndex = selectedArray.index(of: selectedAsset) {
                photoCell.count = targetIndex + 1
                photoCell.isSelected = true
            }
        }
        
        photoCell.configure(item: asset)
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerReuseIdentifier, for: indexPath) as? AssetsPhotoFooterView else {
            logw("Failed to cast AssetsPhotoFooterView.")
            return AssetsPhotoFooterView()
        }
        footerView.setNeedsUpdateConstraints()
        footerView.updateConstraintsIfNeeded()
        footerView.set(imageCount: assets.count, videoCount: 0)
        return footerView
    }
}
// MARK: - UICollectionViewDelegateFlowLayout
extension ThirdPartiesPhotoViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let photoLayout = collectionViewLayout as? AssetsPhotoLayout else { return .zero }
        
        if collectionView.numberOfSections - 1 == section {
            if collectionView.bounds.width > collectionView.bounds.height {
                return CGSize(width: collectionView.bounds.width, height:
                    photoLayout.assetLandscapeCellSize(forViewSize: collectionView.bounds.size).width * 2/3)
            } else {
                return CGSize(width: collectionView.bounds.width, height: photoLayout.assetPortraitCellSize(forViewSize: collectionView.bounds.size).width * 2/3)
            }
        } else {
            return .zero
        }
    }
}
