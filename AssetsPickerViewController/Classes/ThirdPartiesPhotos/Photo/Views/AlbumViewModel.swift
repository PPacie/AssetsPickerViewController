//
//  AlbumViewModel.swift
//  AssetsPickerViewController
//
//  Created by Pablo Paciello on 4/24/18.
//

import Foundation

import Foundation

@objc public class AlbumViewModel: NSObject {
    public var name: String?
    public var count: Int?
    public var coverUrl: URL?
    public var albumId: String?
    public var photos: [PhotoViewModel] = []
    
    init(name: String,
         count: Int? = nil,
         coverUrl: URL? = nil,
         albmId: String) {
        self.name = name
        self.albumId = albmId
        self.coverUrl = coverUrl
        self.count = count
    }
}
