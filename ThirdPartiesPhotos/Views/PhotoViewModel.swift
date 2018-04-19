//
//  PhotoViewModel.swift
//  GenericDataSource
//
//  Created by Andrea Prearo on 5/5/17.
//  Copyright © 2017 Andrea Prearo. All rights reserved.
//

import Foundation

@objc public class PhotoViewModel: NSObject {
    public let url: URL
    public let imageID: String
    
    public init(url: URL, imageID: String) {
        self.url = url
        self.imageID = imageID
    }
}
