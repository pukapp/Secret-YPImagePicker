//
//  YPMediaItem.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 09.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import Photos


public class YPMediaPhoto {
    
    public var image: UIImage { return modifiedImage ?? originalImage }
    public let originalImage: UIImage
    public var modifiedImage: UIImage?
    public let fromCamera: Bool
    public let exifMeta : [String : Any]?
    public var asset: PHAsset?
    
    public init(image: UIImage, exifMeta : [String : Any]? = nil, fromCamera: Bool = false, asset: PHAsset? = nil) {
        self.originalImage = image
        self.modifiedImage = nil
        self.fromCamera = fromCamera
        self.exifMeta = exifMeta
        self.asset = asset
    }
}

public class YPMediaVideo {
    
    public var thumbnail: UIImage
    public var url: URL
    public let fromCamera: Bool
    public var asset: PHAsset?
    ///拍摄的时候是宽高一致的
    public let naturalSize: String
    public let duration: TimeInterval
    
    public init(thumbnail: UIImage,
                videoURL: URL,
                fromCamera: Bool = false,
                naturalSize: String,
                duration: TimeInterval,
                asset: PHAsset? = nil) {
        self.thumbnail = thumbnail
        self.url = videoURL
        self.fromCamera = fromCamera
        self.naturalSize = naturalSize
        self.duration = duration
        self.asset = asset
    }
}

public enum YPMediaItem {
    case photo(p: YPMediaPhoto)
    case video(v: YPMediaVideo)
}

// MARK: - Compression

public extension YPMediaVideo {
    /// Fetches a video data with selected compression in YPImagePickerConfiguration
    func fetchData(completion: (_ videoData: Data) -> Void) {
        // TODO: place here a compression code. Use YPConfig.videoCompression
        // and YPConfig.videoExtension
        completion(Data())
    }
}

// MARK: - Easy access

public extension Array where Element == YPMediaItem {
    var singlePhoto: YPMediaPhoto? {
        if let f = first, case let .photo(p) = f {
            return p
        }
        return nil
    }
    
    var singleVideo: YPMediaVideo? {
        if let f = first, case let .video(v) = f {
            return v
        }
        return nil
    }
}
