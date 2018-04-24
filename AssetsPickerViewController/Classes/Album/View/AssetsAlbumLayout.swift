//
//  AssetsAlbumLayout.swift
//  Pods
//
//  Created by DragonCherry on 5/18/17.
//
//

import UIKit

open class AssetsAlbumLayout: UICollectionViewFlowLayout {

    // MARK: Custom Layout
    open var albumCellType: AnyClass = AssetsAlbumCell.classForCoder()
    open var albumDefaultSpace: CGFloat = 20
    open var albumLineSpace: CGFloat = -1
    open let albumPortraitDefaultColumnCount: Int = UI_USER_INTERFACE_IDIOM() == .pad ? 3 : 2
    open var albumPortraitColumnCount: Int?
    open var albumPortraitForcedCellWidth: CGFloat?
    open var albumPortraitForcedCellHeight: CGFloat?
    open var albumPortraitCellSize: CGSize = .zero

    open let albumLandscapeDefaultColumnCount: Int = UI_USER_INTERFACE_IDIOM() == .pad ? 4 : 3
    open var albumLandscapeColumnCount: Int?
    open var albumLandscapeForcedCellWidth: CGFloat?
    open var albumLandscapeForcedCellHeight: CGFloat?
    open var albumLandscapeCellSize: CGSize = .zero

    func albumItemSpace(isPortrait: Bool) -> CGFloat {
        let size = isPortrait ? UIScreen.main.portraitSize : UIScreen.main.landscapeSize
        let count = CGFloat(isPortrait ? (albumPortraitColumnCount ?? albumPortraitDefaultColumnCount) : albumLandscapeColumnCount ?? albumLandscapeDefaultColumnCount)
        let albumCellSize = isPortrait ? albumPortraitCellSize : albumLandscapeCellSize
        let space = (size.width - count * albumCellSize.width) / (count + 1)
        return space
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public override init() {
        super.init()
        commonInit()
    }

    public func commonInit() {
        /* initialize album attributes */

        // album line space
        if albumLineSpace < 0 {
            albumLineSpace = albumDefaultSpace
        }

        // initialize album cell size
        let albumPortraitCount = CGFloat(albumPortraitColumnCount ?? albumPortraitDefaultColumnCount)
        let albumPortraitWidth = (UIScreen.main.portraitSize.width - albumDefaultSpace * (albumPortraitCount + 1)) / albumPortraitCount
        albumPortraitCellSize = CGSize(
            width: albumPortraitForcedCellWidth ?? albumPortraitWidth,
            height: albumPortraitForcedCellHeight ?? albumPortraitWidth * 1.25
        )

        let albumLandscapeCount = CGFloat(albumLandscapeColumnCount ?? albumLandscapeDefaultColumnCount)
        var albumLandscapeWidth: CGFloat = 0
        if let _ = albumPortraitColumnCount {
            albumLandscapeWidth = (UIScreen.main.landscapeSize.width - albumDefaultSpace * (albumLandscapeCount + 1)) / albumLandscapeCount
        } else {
            albumLandscapeWidth = albumPortraitWidth
        }
        albumLandscapeCellSize = CGSize(
            width: albumLandscapeForcedCellWidth ?? albumLandscapeWidth,
            height: albumLandscapeForcedCellHeight ?? albumLandscapeWidth * 1.25
        )
    }
    
}
