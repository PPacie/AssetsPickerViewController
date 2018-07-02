//
//  HideEmptyAlbumsController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 5/31/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import AssetsPickerViewController

class HideEmptyAlbumsController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
        
        let pickerConfig = AssetsPickerConfig()
        pickerConfig.albumIsShowEmptyAlbum = false
        pickerConfig.maxItemsSelection = 2
        
        let picker = AssetsPickerViewController(pickerConfig: pickerConfig)
        picker.pickerDelegate = self
        present(picker, animated: true, completion: nil)
    }
}
