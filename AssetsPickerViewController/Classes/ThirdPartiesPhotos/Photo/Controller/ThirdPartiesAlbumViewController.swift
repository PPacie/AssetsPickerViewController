//
//  ThirdPartiesAlbumViewController.swift
//  AssetsPickerViewController
//
//  Created by Pablo Paciello on 4/24/18.
//

import UIKit
import TinyLog
import PureLayout

// MARK: - AssetsAlbumViewControllerDelegate
public protocol ThirdPartiesAlbumViewControllerDelegate {
    func thirdPartyAlbum(selected album: AlbumViewModel)
}

open class ThirdPartiesAlbumViewController: UIViewController {

    open var delegate: ThirdPartiesAlbumViewControllerDelegate?
    
    private let cellReuseIdentifier: String = UUID().uuidString
    private let headerReuseIdentifier: String = UUID().uuidString
    private var didSetupConstraints = false
    private var indicator = UIActivityIndicatorView()
    
    public var albums: [AlbumViewModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.activityIndicatorStop()
                self.collectionView.reloadData()
            }
        }
    }
    
    lazy var collectionView: UICollectionView = {
        let isPortrait = UIApplication.shared.statusBarOrientation.isPortrait
        
        let layout = AssetsAlbumLayout()
        self.updateLayout(layout: layout, isPortrait: isPortrait)
        layout.scrollDirection = .vertical
        
        let defaultSpace = layout.albumDefaultSpace
        let itemSpace = layout.albumItemSpace(isPortrait: isPortrait)
        let view = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        view.configureForAutoLayout()
        view.register(AlbumCell.classForCoder(), forCellWithReuseIdentifier: self.cellReuseIdentifier)
        view.contentInset = UIEdgeInsets(top: defaultSpace, left: itemSpace, bottom: defaultSpace, right: itemSpace)
        view.backgroundColor = UIColor.clear
        view.dataSource = self
        view.delegate = self
        if #available(iOS 10.0, *) {
            //view.prefetchDataSource = self
        }
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        
        return view
    }()
    
    // MARK: Lifecycle Methods
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public init(albums: [AlbumViewModel]) {
        self.init()
        self.albums = albums
    }
    
    deinit { logd("Released \(type(of: self))") }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.addSubview(collectionView)
        // Init Activity Indicator
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        indicator.center = view.center
        indicator.hidesWhenStopped = true
        view.addSubview(indicator)
        
        view.setNeedsUpdateConstraints()        
    }
    
    open func activityIndicatorStartLoading() {
        indicator.startAnimating()
    }
    
    open func activityIndicatorStop() {
        indicator.stopAnimating()
    }
    
    open override func updateViewConstraints() {
        super.updateViewConstraints()
        
        if !didSetupConstraints {
            collectionView.autoPinEdgesToSuperviewEdges()
            didSetupConstraints = true
        }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: collectionView, animation: { (context) in
            guard let photoLayout = self.collectionView.collectionViewLayout as? AssetsAlbumLayout  else { return }
            let isPortrait = size.height > size.width
            let space = photoLayout.albumItemSpace(isPortrait: isPortrait)
            let insets = self.collectionView.contentInset
            self.collectionView.contentInset = UIEdgeInsets(top: insets.top, left: space, bottom: insets.bottom, right: space)
            self.updateLayout(layout: self.collectionView.collectionViewLayout, isPortrait: isPortrait)
        }) { (_) in
        }
    }
}

// MARK: - Internal APIs for UI
extension ThirdPartiesAlbumViewController {
    
    func updateLayout(layout: UICollectionViewLayout?, isPortrait: Bool) {
        if let flowLayout = layout as? AssetsAlbumLayout {
            flowLayout.itemSize = isPortrait ? flowLayout.albumPortraitCellSize : flowLayout.albumLandscapeCellSize
            flowLayout.minimumLineSpacing = flowLayout.albumDefaultSpace
            flowLayout.minimumInteritemSpacing = flowLayout.albumItemSpace(isPortrait: isPortrait)
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ThirdPartiesAlbumViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.thirdPartyAlbum(selected: albums[indexPath.row])
    }
}

// MARK: - UICollectionViewDataSource
extension ThirdPartiesAlbumViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albums.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard let _ = cell as? ThirdPartiesAlbumCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return cell
        }
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let albumCell = cell as? ThirdPartiesAlbumCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return
        }
        albumCell.configure(item: albums[indexPath.row])
    }
}
