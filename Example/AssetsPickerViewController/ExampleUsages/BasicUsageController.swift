//
//  BasicUsageController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 5/17/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import AssetsPickerViewController

class BasicUsageController: CommonExampleController {
    
    let nc = UINavigationController()
    
    override func pressedPick(_ sender: Any) {
//        let picker = AssetsPickerViewController()
//        picker.pickerDelegate = self
//        present(picker, animated: true, completion: nil)
        

        
        let albumVC = ThirdPartiesAlbumViewController(albums: loadAlbumData())
        albumVC.delegate = self
        nc.viewControllers = [albumVC]
        present(nc, animated: true)
    }
    
    private func loadData() -> [PhotoViewModel] {
        var assets = [PhotoViewModel]()
        for i in 0...40 {
            let asset = PhotoViewModel(url: URL(string: "https://splashbase.s3.amazonaws.com/unsplash/regular/tumblr_mtax0twHix1st5lhmo1_1280.jpg")!, imageID: String(i))
            assets.append(asset)
        }
        return assets
    }
    
    private func loadAlbumData() -> [AlbumViewModel] {
        var assets = [AlbumViewModel]()
        for i in 0...40 {
            let asset = AlbumViewModel(name: String(i), count: 40, coverURL: URL(string: "https://splashbase.s3.amazonaws.com/unsplash/regular/tumblr_mtax0twHix1st5lhmo1_1280.jpg"), albmId: String(i))
            assets.append(asset)
        }
        return assets
    }
}

extension BasicUsageController: ThirdPartiesPhotoViewControllerDelegate {
    func assetsPicker(selected assets: [PhotoViewModel]) {
        print("Assets Count:", assets.count)
        dismiss(animated: true)
    }
}
extension BasicUsageController: ThirdPartiesAlbumViewControllerDelegate {
    func thirdPartyAlbum(selected album: AlbumViewModel) {
        print("Album Title", album.name ?? "NO NAME")
        let photosVC = ThirdPartiesPhotoViewController(assets: loadData())
        photosVC.delegate = self
        nc.pushViewController(photosVC, animated: true)
    }
}
