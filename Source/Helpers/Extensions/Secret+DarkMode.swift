//
//  Secret+DarkMode.swift
//  YPImagePicker
//
//  Created by 老西瓜 on 2020/8/13.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    /// 给图片染色，相当于tintColor，针对 iOS13以前返回原始图片
    @objc func stain(for color: UIColor) -> UIImage {
        if #available(iOS 13.0, *) {
            return self.withTintColor(color)
        } else {
            return self
        }
    }
    
}

extension UIColor {
    
    static func make(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { trait -> UIColor in
                trait.userInterfaceStyle == .dark ? dark : light
            }
        } else {
            return light
        }
    }
    
}
