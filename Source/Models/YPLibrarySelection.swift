//
//  YPLibrarySelection.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 18/04/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

struct YPLibrarySelection {

    let index: Int
    var cropRect: CGRect?
    var scrollViewContentOffset: CGPoint?
    var scrollViewZoomScale: CGFloat?
    let assetIdentifier: String
    ///新增，用来判断类型实现图片和视频不能同时选择的需求
    let mediaType: PHAssetMediaType
    let isSelected: Bool
    
    init(index: Int,
         cropRect: CGRect? = nil,
         scrollViewContentOffset: CGPoint? = nil,
         scrollViewZoomScale: CGFloat? = nil,
         assetIdentifier: String,
         mediaType: PHAssetMediaType,
         isSelected: Bool) {
        self.index = index
        self.cropRect = cropRect
        self.scrollViewContentOffset = scrollViewContentOffset
        self.scrollViewZoomScale = scrollViewZoomScale
        self.assetIdentifier = assetIdentifier
        
        self.mediaType = mediaType
        self.isSelected = isSelected
    }
}
