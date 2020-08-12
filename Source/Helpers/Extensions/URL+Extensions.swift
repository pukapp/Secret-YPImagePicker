//
//  URL+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 23.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

extension URL {
    /// Adds a unique path to url
    func appendingUniquePathComponent(pathExtension: String? = nil) -> URL {
        ///新增localCache标识，用来标记视频缓存，在发布视频那里可以根据此标识，就算沙盒路径变了，也正确获取到路径
        var pathComponent = "localCache" + UUID().uuidString
        if let pathExtension = pathExtension {
            pathComponent += ".\(pathExtension)"
        }
        return appendingPathComponent(pathComponent)
    }
}
