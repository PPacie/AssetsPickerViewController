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
    @objc optional func assetsPicker(selectedAssets: Int, shouldSelect asset: PhotoViewModel, at indexPath: IndexPath) -> Bool
    @objc optional func assetsPicker(didSelect asset: PhotoViewModel, at indexPath: IndexPath)
    @objc optional func scrollViewDidScroll(_ scrollView: UIScrollView)
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
    
    var selectedAssets: [PhotoViewModel] {
        return selectedArray
    }
    
    public var assets: [PhotoViewModel] = [] {
        didSet {
            collectionView.reloadData()
            updateFooter()
        }
    }
    
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
    
    override open func loadView() {
        super.loadView()
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(collectionView)
        view.addSubview(confirmButton)
        view.setNeedsUpdateConstraints()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        initialSetup()
        updateFooter()
        //updateEmptyView(count: assets.count)
    }
    
//    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        if let previewing = self.previewing {
//            if traitCollection.forceTouchCapability != .available {
//                unregisterForPreviewing(withContext: previewing)
//                self.previewing = nil
//            }
//        } else {
//            if traitCollection.forceTouchCapability == .available {
//                self.previewing = registerForPreviewing(with: self, sourceView: collectionView)
//            }
//        }
//    }
    
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
            confirmButton.autoPinEdge(toSuperviewMargin: .bottom)
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
    
//    override open func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        if traitCollection.forceTouchCapability == .available {
//            previewing = registerForPreviewing(with: self, sourceView: collectionView)
//        }
//    }
//
//    override open func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//
//        if let previewing = self.previewing {
//            self.previewing = nil
//            unregisterForPreviewing(withContext: previewing)
//        }
//    }
    
    deinit {
        logd("Released \(type(of: self))")
    }
}

// MARK: - Initial Setups
extension ThirdPartiesPhotoViewController {
    
    func initialSetup() {
        view.backgroundColor = .white

        confirmButton.buttonPressedHandler = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.assetsPicker(selected: weakSelf.selectedArray)
        }
        confirmButton.isHidden = true
    }
}

// MARK: - Internal APIs for UI
extension ThirdPartiesPhotoViewController {
    
//    func updateEmptyView(count: Int) {
//        if emptyView.isHidden {
//            if count == 0 {
//                emptyView.isHidden = false
//            }
//        } else {
//            if count > 0 {
//                emptyView.isHidden = true
//            }
//        }
//        logi("emptyView.isHidden: \(emptyView.isHidden), count: \(count)")
//    }
    
    func updateLayout(layout: UICollectionViewLayout, isPortrait: Bool? = nil) {
        guard let photoLayout = layout as? AssetsPhotoLayout else { return }
        if let isPortrait = isPortrait {
            self.isPortrait = isPortrait
        }
        photoLayout.itemSize = self.isPortrait ? photoLayout.assetPortraitCellSize(forViewSize: UIScreen.main.portraitContentSize) : photoLayout.assetLandscapeCellSize(forViewSize: UIScreen.main.landscapeContentSize)
        photoLayout.minimumLineSpacing = self.isPortrait ? photoLayout.assetPortraitLineSpace : photoLayout.assetLandscapeLineSpace
        photoLayout.minimumInteritemSpacing = self.isPortrait ? photoLayout.assetPortraitInteritemSpace : photoLayout.assetLandscapeInteritemSpace
    }

    func select(asset: PhotoViewModel, at indexPath: IndexPath) {
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
    
    func deselect(asset: PhotoViewModel, at indexPath: IndexPath) {
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
    
    func updateSelectionCount() {
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
    
    func updateNavigationStatus() {
        confirmButton.isHidden = selectedArray.count == 0 //!(selectedArray.count >= (pickerConfig.assetsMinimumSelectionCount > 0 ? pickerConfig.assetsMinimumSelectionCount : 1))
        
        let imageCount = selectedArray.count
        
        var titleString: String = "_Images"
        
        if imageCount > 0 {
            titleString = String(format: String(key: "Title_Selected_Items"), NumberFormatter.decimalString(value: imageCount))
        } else {
            if imageCount > 0 {
                if imageCount > 1 {
                    titleString = String(format: String(key: "Title_Selected_Photos"), NumberFormatter.decimalString(value: imageCount))
                } else {
                    titleString = String(format: String(key: "Title_Selected_Photo"), NumberFormatter.decimalString(value: imageCount))
                }
            }
        }
        title = titleString
    }
    
    func updateFooter() {
        guard let footerView = collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionFooter).last as? AssetsPhotoFooterView else {
            return
        }
        footerView.set(imageCount: assets.count, videoCount: 0)
    }
    
    func title(forAlbum album: PHAssetCollection?) -> String {
        var titleString: String!
        if let albumTitle = album?.localizedTitle {
            titleString = "\(albumTitle) ▾"
        } else {
            titleString = ""
        }
        return titleString
    }
}
// MARK: - UIGestureRecognizerDelegate
//extension ThirdPartiesPhotoViewController: UIGestureRecognizerDelegate {
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        guard let navigationBar = navigationController?.navigationBar else { return false }
//        let point = touch.location(in: navigationBar)
//        // Ignore touches on navigation buttons on both sides.
//        return point.x > navigationBar.bounds.width / 4 && point.x < navigationBar.bounds.width * 3 / 4
//    }
//}

// MARK: - UICollectionViewDelegate
extension ThirdPartiesPhotoViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let delegate = self.delegate {
            return delegate.assetsPicker?(selectedAssets: selectedAssets.count, shouldSelect: assets[indexPath.row], at: indexPath) ?? true
        } else {
            return true
        }
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
        //let count = AssetsManager.shared.assetArray.count
        //updateEmptyView(count: count)
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

extension ThirdPartiesPhotoViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        logi("contentOffset: \(scrollView.contentOffset)")
        delegate?.scrollViewDidScroll?(scrollView)
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

// MARK - UIViewControllerPreviewingDelegate
//@available(iOS 9.0, *)
//extension ThirdPartiesPhotoViewController: UIViewControllerPreviewingDelegate {
//    @available(iOS 9.0, *)
//    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
//        logi("\(location)")
//        guard let pressingIndexPath = collectionView.indexPathForItem(at: location) else { return nil }
//        guard let pressingCell = collectionView.cellForItem(at: pressingIndexPath) else { return nil }
//        previewingContext.sourceRect = pressingCell.frame
//        let previewController = AssetsPreviewController()
//        previewController.asset = array[pressingIndexPath.row]
//        return previewController
//    }
//
//    @available(iOS 9.0, *)
//    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
//        logi("viewControllerToCommit: \(type(of: viewControllerToCommit))")
//    }
//}
