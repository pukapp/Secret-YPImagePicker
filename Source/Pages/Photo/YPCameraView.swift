//
//  YPCameraView.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/14.
//  Copyright © 2015 Yummypets. All rights reserved.
//

import UIKit
import Stevia

class YPCameraView: UIView, UIGestureRecognizerDelegate {
    
    let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
    let previewViewContainer = UIView()
    let buttonsContainer = UIView()
    let flipButton = UIButton()
    let shotButton = UIButton()
    let flashButton = UIButton()
    let timeElapsedLabel = UILabel()
    ///新增录制标识
    let recordShineImgV = UIImageView(image: UIImage(named: "wr_video_record_iden"))
    let progressBar = UIProgressView()
    ///新增长按录制提示
    let recordTip = UILabel()
    
    convenience init(overlayView: UIView? = nil) {
        self.init(frame: .zero)
        
        recordShineImgV.backgroundColor = .red
        
        if let overlayView = overlayView {
            // View Hierarchy
            sv(
                previewViewContainer,
                overlayView,
                progressBar,
                timeElapsedLabel,
                recordShineImgV,
                flashButton,
                flipButton,
                buttonsContainer.sv(
                    shotButton,
                    recordTip
                )
            )
        } else {
            // View Hierarchy
            sv(
                previewViewContainer,
                progressBar,
                timeElapsedLabel,
                recordShineImgV,
                flashButton,
                flipButton,
                buttonsContainer.sv(
                    shotButton,
                    recordTip
                )
            )
        }
        
        // Layout
        let isIphone4 = UIScreen.main.bounds.height == 480
        let sideMargin: CGFloat = isIphone4 ? 20 : 0
        if YPConfig.onlySquareImagesFromCamera {
            layout(
                0,
                |-sideMargin-previewViewContainer-sideMargin-|,
                -2,
                |progressBar|,
                0,
                |buttonsContainer|,
                0
            )
            
            previewViewContainer.heightEqualsWidth()
        } else {
            layout(
                0,
                |-sideMargin-previewViewContainer-sideMargin-|,
                -2,
                |progressBar|,
                0
            )
            
            previewViewContainer.fillContainer()
            
            buttonsContainer.fillHorizontally()
            buttonsContainer.height(100)
            buttonsContainer.Bottom == previewViewContainer.Bottom - 50
        }

        overlayView?.followEdges(previewViewContainer)

        |-(15+sideMargin)-flashButton.size(42)
        flashButton.Bottom == previewViewContainer.Bottom - 15

        flipButton.size(42)-(15+sideMargin)-|
        flipButton.Bottom == previewViewContainer.Bottom - 15
        
        timeElapsedLabel-(15+sideMargin)-|
        timeElapsedLabel.Top == previewViewContainer.Bottom + 10
        
        recordShineImgV-10-(timeElapsedLabel)-|
        recordShineImgV.CenterY == timeElapsedLabel.CenterY
        recordShineImgV.size(6)
        
        shotButton.centerVertically()
        shotButton.size(84).centerHorizontally()

        recordTip.centerHorizontally()
        recordTip.Top == shotButton.Bottom + 10
        
        // Style
        backgroundColor = YPConfig.colors.photoVideoScreenBackgroundColor
        previewViewContainer.backgroundColor = .black//UIColor.ypLabel
        timeElapsedLabel.style { l in
            l.textColor = UIColor.init(r: 51/255.0, g: 51/255.0, b: 51/255.0, a: 1)
            l.text = "00:00"
            l.isHidden = true
            l.font = .monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.medium)
        }
        recordShineImgV.style { r in
            r.layer.cornerRadius = 3
            r.layer.masksToBounds = true
            r.isHidden = true
        }
        progressBar.style { p in
            p.backgroundColor = UIColor(r: 220/255.0, g: 219/255.0, b: 219/255.0, a: 1)
            p.trackTintColor = UIColor(r: 83/255.0, g: 152/255.0, b: 247/255.0, a: 1)
        }
        recordTip.style { r in
            r.text = "长按录制"
            r.textColor = UIColor(r: 51/255.0, g: 51/255.0, b: 51/255.0, a: 1)
            r.font = .monospacedDigitSystemFont(ofSize: 14, weight: UIFont.Weight.medium)
        }
        flashButton.setImage(YPConfig.icons.flashOffIcon, for: .normal)
        flipButton.setImage(YPConfig.icons.loopIcon, for: .normal)
        shotButton.setImage(YPConfig.icons.capturePhotoImage, for: .normal)
    }
}
