//
//  AssetsPhotoLayout.swift
//  Pods
//
//  Created by DragonCherry on 5/18/17.
//
//

import UIKit
import Device
import TinyLog

open class AssetsPhotoLayout: UICollectionViewFlowLayout {
    
    open var translatedOffset: CGPoint?
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        return targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if let translatedOffset = self.translatedOffset {
            return translatedOffset
        } else {
            return proposedContentOffset
        }
    }
    
    open var assetPortraitColumnCount: Int = UI_USER_INTERFACE_IDIOM() == .pad ? 5 : 4
    open var assetPortraitInteritemSpace: CGFloat = 1
    open var assetPortraitLineSpace: CGFloat = 1
    
    func assetPortraitCellSize(forViewSize size: CGSize) -> CGSize {
        let count = CGFloat(assetPortraitColumnCount)
        let edge = (size.width - (count - 1) * assetPortraitInteritemSpace) / count
        return CGSize(width: edge, height: edge)
    }
    
    open var assetLandscapeColumnCount: Int = 7
    open var assetLandscapeInteritemSpace: CGFloat = 1.5
    open var assetLandscapeLineSpace: CGFloat = 1.5
    
    func assetLandscapeCellSize(forViewSize size: CGSize) -> CGSize {
        let count = CGFloat(assetLandscapeColumnCount)
        let edge = (size.width - (count - 1) * assetLandscapeInteritemSpace) / count
        return CGSize(width: edge, height: edge)
    }
}

extension AssetsPhotoLayout {
    
    open func expectedContentHeight(forViewSize size: CGSize, isPortrait: Bool, itemsCount: Int) -> CGFloat {
        var rows = itemsCount / (isPortrait ? assetPortraitColumnCount : assetLandscapeColumnCount)
        let remainder = itemsCount % (isPortrait ? assetPortraitColumnCount : assetLandscapeColumnCount)
        rows += remainder > 0 ? 1 : 0
        
        let cellSize = isPortrait ? assetPortraitCellSize(forViewSize: UIScreen.main.portraitContentSize) : assetLandscapeCellSize(forViewSize: UIScreen.main.landscapeContentSize)
        let lineSpace = isPortrait ? assetPortraitLineSpace : assetLandscapeLineSpace
        let contentHeight = CGFloat(rows) * cellSize.height + (CGFloat(max(rows - 1, 0)) * lineSpace)
        let bottomHeight = cellSize.height * 2/3 + Device.safeAreaInsets(isPortrait: isPortrait).bottom
        
        return contentHeight + bottomHeight
    }
    
    private func offsetRatio(collectionView: UICollectionView, offset: CGPoint, contentSize: CGSize, isPortrait: Bool) -> CGFloat {
        return (offset.y > 0 ? offset.y : 0) / ((contentSize.height + Device.safeAreaInsets(isPortrait: isPortrait).bottom) - collectionView.bounds.height)
    }
    
    open func translateOffset(forChangingSize size: CGSize, currentOffset: CGPoint, itemsCount: Int) -> CGPoint? {
        guard let collectionView = self.collectionView else {
            return nil
        }
        let isPortraitFuture = size.height > size.width
        let isPortraitCurrent = collectionView.bounds.size.height > collectionView.bounds.size.width
        let contentHeight = expectedContentHeight(forViewSize: size, isPortrait: isPortraitFuture, itemsCount: itemsCount)
        let currentRatio = offsetRatio(collectionView: collectionView, offset: currentOffset, contentSize: collectionView.contentSize, isPortrait: isPortraitCurrent)
        logi("currentRatio = \(currentRatio)")
        var futureOffsetY = (contentHeight - size.height) * currentRatio
        
        if currentOffset.y < 0 {
            let insetRatio = (-currentOffset.y) / Device.safeAreaInsets(isPortrait: isPortraitCurrent).top
            let insetDiff = Device.safeAreaInsets(isPortrait: isPortraitFuture).top * insetRatio
            futureOffsetY -= insetDiff
        }
        
        return CGPoint(x: 0, y: futureOffsetY)
    }
}
