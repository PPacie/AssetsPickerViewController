//
//  BasicUsageController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 5/17/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import AssetsPickerViewController

class BasicUsageController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
//        let picker = AssetsPickerViewController()
//        picker.pickerDelegate = self
//        present(picker, animated: true, completion: nil)
        
        let photosVC = ThirdPartiesPhotoViewController(assets: loadData())
        photosVC.delegate = self
        let nc = UINavigationController()
        nc.viewControllers = [photosVC]
        present(nc, animated: true)
    }
    
    func loadData() -> [PhotoViewModel] {
        var assets = [PhotoViewModel]()
        for i in 0...40 {
            let asset = PhotoViewModel(url: URL(string: "https://splashbase.s3.amazonaws.com/unsplash/regular/tumblr_mtax0twHix1st5lhmo1_1280.jpg")!, imageID: String(i))
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
