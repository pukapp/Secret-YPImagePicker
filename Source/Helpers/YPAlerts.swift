//
//  YPAlert.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

struct YPAlert {
    static func videoTooLongAlert(_ sourceView: UIView) -> UIAlertController {
        let msg = String(format: YPConfig.wordings.videoDurationPopup.tooLongMessage,
                         "\(YPConfig.video.libraryTimeLimit)")
        let alert = UIAlertController(title: YPConfig.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
    
    static func videoTooShortAlert(_ sourceView: UIView) -> UIAlertController {
        let msg = String(format: YPConfig.wordings.videoDurationPopup.tooShortMessage,
                         "\(YPConfig.video.minimumTimeLimit)")
        let alert = UIAlertController(title: YPConfig.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
    
    static func videoChooseAmountLimit(_ sourceView: UIView) -> UIAlertController {
        let msg = YPConfig.wordings.warningMaxVideoLimitText
        let alert = UIAlertController(title: YPConfig.wordings.warningMaxVideoLimitTitle,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
    
    ///视频损坏了
    static func badvideoChoose(_ sourceView: UIView) -> UIAlertController {
        let msg = YPConfig.wordings.warningBadVideoText
        let alert = UIAlertController(title: YPConfig.wordings.warningBadVideoTitle,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
    
    ///选择图片数量超出限制
    static func maxItemsLimit(_ sourceView: UIView) -> UIAlertController {
        let msg = String(format: YPConfig.wordings.warningMaxItemsLimit, YPConfig.library.maxNumberOfItems)
        let alert = UIAlertController(title: YPConfig.wordings.warningMaxItemsLimitTitle,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
    
    ///不能同时选择图片和视频
    static func canChooseOneType(_ sourceView: UIView) -> UIAlertController {
        let msg = YPConfig.wordings.warningCanChooseOneType
        let alert = UIAlertController(title: YPConfig.wordings.warningCanChooseOneTypeTitle,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
}
