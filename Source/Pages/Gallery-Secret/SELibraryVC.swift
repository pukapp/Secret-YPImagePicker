//
//  SeLibraryVC.swift
//  YPImagePicker
//
//  Created by 刘超 on 2019/8/24.
//  Copyright © 2019 Yummypets. All rights reserved.
//

import UIKit
import Photos

protocol SELibraryVCDelegate: AnyObject {
    func didFinishPicking(proceedItems: [YPMediaItem], isOriginal: Bool)
}

class SELibraryVC: UIViewController {

    weak var delegate: SELibraryVCDelegate?
    
    internal let mediaManager = LibraryMediaManager()
    internal var selection = [YPLibrarySelection]()
    
    internal var initialized = false
    internal var collectionView: UICollectionView!
    
    internal var isSelectOriginal: Bool = false
    internal lazy var sendBtn: UIButton = {
        let sendBtn = UIButton()
        sendBtn.layer.cornerRadius = 5
        sendBtn.layer.masksToBounds = true
        sendBtn.backgroundColor = UIColor(r: 10, g: 119, b: 253)
        sendBtn.setTitle(YPConfig.wordings.send, for: .normal)
        sendBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        sendBtn.addTarget(self, action: #selector(sendAction), for: .touchUpInside)
        return sendBtn
    }()
    internal lazy var spinnerV: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.color = .white
        spinner.isHidden = true
        spinner.center = CGPoint(x: sendBtn.bounds.width/2.0, y: sendBtn.bounds.height/2.0)
        sendBtn.addSubview(spinner)
        return spinner
    }()
    internal lazy var bottomToolView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        
        view.addSubview(sendBtn)
        
        let originalBtn = UIButton()
        originalBtn.setImage(YPConfig.icons.setOriginal_normal, for: .normal)
        originalBtn.setImage(YPConfig.icons.setOriginal_selected, for: .selected)
        originalBtn.addTarget(self, action: #selector(setOriginalAction), for: .touchUpInside)
        view.addSubview(originalBtn)
        
        let originalLabel = UILabel()
        originalLabel.text = YPConfig.wordings.original
        originalLabel.textColor = .white
        originalLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        view.addSubview(originalLabel)
        
        sendBtn.frame = CGRect(x: UIScreen.main.bounds.width - 14 - 60, y: 7.5, width: 60, height: 30)
        originalBtn.frame = CGRect(x: 14, y: 13.5, width: 18, height: 18)
        originalLabel.frame = CGRect(x: originalBtn.frame.maxX + 4, y: 10, width: 60, height: 25)

        return view
    }()
    
    func startDeal() {
        spinnerV.isHidden = false
        spinnerV.startAnimating()
        sendBtn.setTitle(nil, for: .normal)
    }
    
    func endDeal() {
        spinnerV.stopAnimating()
        spinnerV.isHidden = true
        sendBtn.setTitle(YPConfig.wordings.send, for: .normal)
    }
    
    @objc func sendAction() {
        guard spinnerV.isHidden else { return }
        guard self.selection.count > 0 else { return }
        let selectedAssets: [PHAsset] = self.selection.map {
            guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [$0.assetIdentifier], options: PHFetchOptions()).firstObject else { fatalError() }
            return asset
        }
        guard selectedAssets.count > 0 else { return }
        
        self.startDeal()
        
        var resultMediaItems: [YPMediaItem] = []
        let asyncGroup = DispatchGroup()
        
        for asset in selectedAssets {
            asyncGroup.enter()
            
            switch asset.mediaType {
            case .image:
                mediaManager.imageManager?.fetch(photo: asset, callback: { (image, isFromCloud) in
                    let photo = YPMediaPhoto(image: image, exifMeta: nil, asset: asset)
                    resultMediaItems.append(YPMediaItem.photo(p: photo))
                    asyncGroup.leave()
                })
            case .video:
                mediaManager.fetchVideoUrlAndCrop(for: asset, cropRect: nil, callback: { videoURL in
                    let videoItem = YPMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
                                                 videoURL: videoURL,
                                                 naturalSize: naturalSizeFormVideoPath(videoURL),
                                                 duration: durationFormVideoPath(videoURL),
                                                 asset: asset)
                    resultMediaItems.append(YPMediaItem.video(v: videoItem))
                    asyncGroup.leave()
                }, callError: {[weak self] error in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.endDeal()
                        let alert = YPAlert.badvideoChoose(self.view)
                        self.present(alert, animated: true, completion: nil)
                    }
                })
            default:
                break
            }
        }
        
        asyncGroup.notify(queue: .main) {
            self.endDeal()
            self.delegate?.didFinishPicking(proceedItems: resultMediaItems, isOriginal: self.isSelectOriginal)
        }
    }
    
    @objc func setOriginalAction(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        isSelectOriginal = sender.isSelected
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
    }
    
    deinit {
        debugPrint("secret:ios===SELibraryVC释放了")
    }
    
    func initialize() {
        mediaManager.initialize()

        if mediaManager.fetchResult != nil {
            return
        }
        bottomToolView.frame = CGRect.init(x: 0, y: self.view.bounds.height - UIScreen.navBarHeight - 45, width: self.view.bounds.width, height: 45)
        self.view.addSubview(bottomToolView)
        
        setupCollectionView()
        refreshMediaRequest()
    }

    func setAlbum(_ album: YPAlbum) {
        mediaManager.collection = album.collection
    }

    func refreshMediaRequest() {
        
        let options = buildPHFetchOptions()
        
        if let collection = mediaManager.collection {
            mediaManager.fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        } else {
            mediaManager.fetchResult = PHAsset.fetchAssets(with: options)
        }
        
        if mediaManager.fetchResult.count > 0 {
            collectionView.reloadData()
        } else {
            //delegate?.noPhotosForOptions()
        }
        collectionView.scrollToItem(at: IndexPath.init(item: mediaManager.fetchResult.count - 1, section: 0), at: .bottom, animated: true)
    }
    
    func buildPHFetchOptions() -> PHFetchOptions {
        // Sorting condition
        if let userOpt = YPConfig.library.options {
            return userOpt
        }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = YPConfig.library.mediaType.predicate()
        return options
    }
    
    
    func checkPermission() {
        checkPermissionToAccessPhotoLibrary { [weak self] hasPermission in
            guard let self = self else { return }
            if hasPermission && !self.initialized {
                self.initialize()
                self.initialized = true
            }
        }
    }
    
    // Async beacause will prompt permission if .notDetermined
    // and ask custom popup if denied.
    func checkPermissionToAccessPhotoLibrary(block: @escaping (Bool) -> Void) {
        // Only intilialize picker if photo permission is Allowed by user.
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            block(true)
        case .restricted, .denied:
            let popup = YPPermissionDeniedPopup()
            let alert = popup.popup(cancelBlock: {
                block(false)
            })
            present(alert, animated: true, completion: nil)
        case .notDetermined:
            // Show permission popup and get new status
            PHPhotoLibrary.requestAuthorization { s in
                DispatchQueue.main.async {
                    block(s == .authorized)
                }
            }
        }
    }
    
}
