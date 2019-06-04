//
//  YPHelper.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 02/11/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation
import UIKit
import Photos

internal func ypLocalized(_ str: String) -> String {
    return NSLocalizedString(str,
                             tableName: "YPImagePickerLocalizable",
                             bundle: Bundle(for: YPPickerVC.self),
                             value: "",
                             comment: "")
}

internal func imageFromBundle(_ named: String) -> UIImage {
    return UIImage(named: named, in: Bundle(for: YPPickerVC.self), compatibleWith: nil) ?? UIImage()
}

struct YPHelper {
    static func changeBackButtonIcon(_ controller: UIViewController) {
        if YPConfig.icons.shouldChangeDefaultBackButtonIcon {
            let backButtonIcon = YPConfig.icons.backButtonIcon
            controller.navigationController?.navigationBar.backIndicatorImage = backButtonIcon
            controller.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonIcon
        }
    }
    
    static func changeBackButtonTitle(_ controller: UIViewController) {
        if YPConfig.icons.hideBackButtonTitle {
            controller.navigationItem.backBarButtonItem = UIBarButtonItem(title: "",
                                                                          style: .plain,
                                                                          target: nil,
                                                                          action: nil)
        }
    }
    
    static func configureFocusView(_ v: UIView) {
        v.alpha = 0.0
        v.backgroundColor = UIColor.clear
        v.layer.borderColor = UIColor(r: 204, g: 204, b: 204).cgColor
        v.layer.borderWidth = 1.0
        v.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
    }
    
    static func animateFocusView(_ v: UIView) {
        UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 3.0, options: UIView.AnimationOptions.curveEaseIn,
                       animations: {
                        v.alpha = 1.0
                        v.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: { _ in
            v.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            v.removeFromSuperview()
        })
    }
    
    static func formattedStrigFrom(_ timeInterval: TimeInterval) -> String {
        let interval = Int(timeInterval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension UIScreen {
    // 刘海屏
    static var hasNotch: Bool {
        if #available(iOS 12, *) {
            ///on iOS12 insets.top == 20 on device without notch.
            ///insets.top == 44 on device with notch.
            guard let window = UIApplication.shared.keyWindow else { return false }
            let insets = window.safeAreaInsets
            
            return insets.top > 20 || insets.bottom > 0
        } else if #available(iOS 11, *) {
            guard let window = UIApplication.shared.keyWindow else { return false }
            let insets = window.safeAreaInsets
            // if top or bottom insets are greater than zero, it means that
            // the screen has a safe area (e.g. iPhone X)
            return insets.top > 0 || insets.bottom > 0
        } else {
            return false
        }
    }
    
    static var navBarHeight: CGFloat = {
        return hasNotch ? 88 : 64
    }()
}


