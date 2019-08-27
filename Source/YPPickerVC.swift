//
//  YYPPickerVC.swift
//  YPPickerVC
//
//  Created by Sacha Durand Saint Omer on 25/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation
import Stevia
import Photos

protocol ImagePickerDelegate: AnyObject {
    func noPhotos()
    func didFinishPicking(proceedItems: [YPMediaItem], isOriginal: Bool, completion: (() -> Void)?)
}

public class YPPickerVC: YPBottomPager, YPBottomPagerDelegate {
    
    deinit {
        debugPrint("secret:ios===YPPickerVC释放了")
    }
    
    let albumsManager = YPAlbumsManager()
    var shouldHideStatusBar = false
    var initialStatusBarHidden = false
    weak var imagePickerDelegate: ImagePickerDelegate?
    
    override public var prefersStatusBarHidden: Bool {
        return (shouldHideStatusBar || initialStatusBarHidden) && YPConfig.hidesStatusBar
    }
    
    /// Private callbacks to YPImagePicker
    public var didClose:(((() -> Void)?) -> Void)?
    public var didSelectItems: (([YPMediaItem]) -> Void)?
    
    enum Mode {
        case library
        case camera
        case video
        case secretLibrary
    }
    
    private var libraryVC: YPLibraryVC?
    private var cameraVC: YPCameraVC?
    private var videoVC: YPVideoCaptureVC?
    private var selibraryVC: SELibraryVC?
    private var selibraryAlbumVC: YPAlbumVC?
    
    var mode = Mode.camera
    
    var capturedImage: UIImage?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(r: 247, g: 247, b: 247)
        
        delegate = self
        
        // Force Library only when using `minNumberOfItems`.
        if YPConfig.library.minNumberOfItems > 1 {
            YPImagePickerConfiguration.shared.screens = [.library]
        }
        
        // Library
        if YPConfig.screens.contains(.library) {
            libraryVC = YPLibraryVC()
            libraryVC?.delegate = self
        }
        
        // Camera
        if YPConfig.screens.contains(.photo) {
            cameraVC = YPCameraVC()
            cameraVC?.didCapturePhoto = { [weak self] img in
                self?.didSelectItems?([YPMediaItem.photo(p: YPMediaPhoto(image: img,
                                                                        fromCamera: true))])
            }
        }
        
        // Video
        if YPConfig.screens.contains(.video) {
            videoVC = YPVideoCaptureVC()
            videoVC?.didCaptureVideo = { [weak self] videoURL in
                let video = YPMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
                                         videoURL: videoURL,
                                         fromCamera: true,
                                         naturalSize: naturalSizeFormVideoPath(videoURL),
                                         duration: durationFormVideoPath(videoURL))
                let item = YPMediaItem.video(v: video)
                self?.didSelectItems?([item])
            }
        }
        
        // SecretLibrary
        if YPConfig.screens.contains(.secretLibrary) {
            selibraryVC = SELibraryVC()
            selibraryVC?.delegate = self
        }
        
        // Show screens
        var vcs = [UIViewController]()
        for screen in YPConfig.screens {
            switch screen {
            case .library:
                if let libraryVC = libraryVC {
                    vcs.append(libraryVC)
                }
            case .photo:
                if let cameraVC = cameraVC {
                    vcs.append(cameraVC)
                }
            case .video:
                if let videoVC = videoVC {
                    vcs.append(videoVC)
                }
            case .secretLibrary:
                if let selibraryVC = selibraryVC {
                    selibraryAlbumVC = YPAlbumVC(albumsManager: albumsManager)
                    let navVC = UINavigationController(rootViewController: selibraryAlbumVC!)
                    navVC.navigationBar.isHidden = true
                    selibraryAlbumVC!.didSelectAlbum = { [weak self, weak selibraryVC] album in
                        guard let self = self, let selibraryVC = selibraryVC else { return }
                        selibraryVC.setAlbum(album)
                        self.navigationItem.title = album.title
                        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: YPConfig.icons.backButtonIcon, style: .done, target: self, action: #selector(self.popToAlbumList))
                        selibraryVC.refreshMediaRequest()
                        navVC.pushViewController(selibraryVC, animated: true)
                    }
                    navVC.viewControllers.append(selibraryVC)
                    
                    vcs = [navVC]
                }
            }
        }
        controllers = vcs
        
        // Select good mode
        if YPConfig.screens.contains(YPConfig.startOnScreen) {
            switch YPConfig.startOnScreen {
            case .library:
                mode = .library
            case .photo:
                mode = .camera
            case .video:
                mode = .video
            case .secretLibrary:
                mode = .secretLibrary
            }
        }
        
        // Select good screen
        if let index = YPConfig.screens.index(of: YPConfig.startOnScreen) {
            startOnPage(index)
        }
        
        YPHelper.changeBackButtonIcon(self)
        YPHelper.changeBackButtonTitle(self)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraVC?.v.shotButton.isEnabled = true
        
        updateMode(with: currentController)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        shouldHideStatusBar = true
        initialStatusBarHidden = true
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    internal func pagerScrollViewDidScroll(_ scrollView: UIScrollView) { }
    
    func modeFor(vc: UIViewController) -> Mode {
        switch vc {
        case is YPLibraryVC:
            return .library
        case is YPCameraVC:
            return .camera
        case is YPVideoCaptureVC:
            return .video
        case is UINavigationController:
            return .secretLibrary
        default:
            return .camera
        }
    }
    
    func pagerDidSelectController(_ vc: UIViewController) {
        updateMode(with: vc)
    }
    
    func updateMode(with vc: UIViewController) {
        stopCurrentCamera()
        
        // Set new mode
        mode = modeFor(vc: vc)
        
        // Re-trigger permission check
        if let vc = vc as? YPLibraryVC {
            vc.checkPermission()
        } else if let cameraVC = vc as? YPCameraVC {
            cameraVC.start()
        } else if let videoVC = vc as? YPVideoCaptureVC {
            videoVC.start()
        } else if let nav = vc as? UINavigationController, let seVC = nav.viewControllers[1] as? SELibraryVC {
            seVC.checkPermission()
        }
    
        updateUI()
    }
    
    func stopCurrentCamera() {
        switch mode {
        case .library:
            libraryVC?.pausePlayer()
        case .camera:
            cameraVC?.stopCamera()
        case .video:
            videoVC?.stopCamera()
        case .secretLibrary:
            break
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shouldHideStatusBar = false
        stopAll()
    }
    
    @objc
    func navBarTapped() {
        let vc = YPAlbumVC(albumsManager: albumsManager)
        let navVC = UINavigationController(rootViewController: vc)
        
        vc.didSelectAlbum = { [weak self] album in
            self?.libraryVC?.setAlbum(album)
            self?.libraryVC?.title = album.title
            self?.libraryVC?.refreshMediaRequest()
            self?.setTitleViewWithTitle(aTitle: album.title)
            self?.dismiss(animated: true, completion: nil)
        }
        present(navVC, animated: true, completion: nil)
    }
    
    func setTitleViewWithTitle(aTitle: String) {
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        
        let label = UILabel()
        label.text = aTitle
        // Use standard font by default.
        label.font = UIFont.boldSystemFont(ofSize: 17)
        
        // Use custom font if set by user.
        if let navBarTitleFont = UINavigationBar.appearance().titleTextAttributes?[.font] as? UIFont {
            // Use custom font if set by user.
            label.font = navBarTitleFont
        }
        // Use custom textColor if set by user.
        if let navBarTitleColor = UINavigationBar.appearance().titleTextAttributes?[.foregroundColor] as? UIColor {
            label.textColor = navBarTitleColor
        }
        
        if YPConfig.library.options != nil {
            titleView.sv(
                label
            )
            |-(>=8)-label.centerHorizontally()-(>=8)-|
            align(horizontally: label)
        } else {
            let arrow = UIImageView()
            arrow.image = YPConfig.icons.arrowDownIcon
            
            let attributes = UINavigationBar.appearance().titleTextAttributes
            if let attributes = attributes, let foregroundColor = attributes[NSAttributedString.Key.foregroundColor] as? UIColor {
                arrow.image = arrow.image?.withRenderingMode(.alwaysTemplate)
                arrow.tintColor = foregroundColor
            }
            
            let button = UIButton()
            button.addTarget(self, action: #selector(navBarTapped), for: .touchUpInside)
            button.setBackgroundColor(UIColor.white.withAlphaComponent(0.5), forState: .highlighted)
            
            titleView.sv(
                label,
                arrow,
                button
            )
            button.fillContainer()
            |-(>=8)-label.centerHorizontally()-arrow-(>=8)-|
            align(horizontally: label-arrow)
        }
        
        label.firstBaselineAnchor.constraint(equalTo: titleView.bottomAnchor, constant: -14).isActive = true
        
        
        
        titleView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        navigationItem.titleView = titleView
    }
    
    func updateUI() {
        // Update Nav Bar state.
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(close))
        
        switch mode {
        case .library:
            setTitleViewWithTitle(aTitle: libraryVC?.title ?? "")
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.next,
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(done))
            navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
            
            // Disable Next Button until minNumberOfItems is reached.
            navigationItem.rightBarButtonItem?.isEnabled = libraryVC!.selection.count >= YPConfig.library.minNumberOfItems

        case .camera:
            navigationItem.titleView = nil
            title = cameraVC?.title
            navigationItem.rightBarButtonItem = nil
        case .video:
            navigationItem.titleView = nil
            title = videoVC?.title
            navigationItem.rightBarButtonItem = nil
        case .secretLibrary:
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(close))
            navigationItem.titleView = nil
            title = YPConfig.wordings.allPhotos
            navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: YPConfig.icons.backButtonIcon, style: .done, target: self, action: #selector(popToAlbumList))
        }
    }
    
    @objc
    func popToAlbumList() {
        navigationItem.leftBarButtonItem = nil
        selibraryVC!.navigationController?.popViewController(animated: true)
    }
    
    @objc
    func close() {
        // Cancelling exporting of all videos
        if let libraryVC = libraryVC {
            libraryVC.mediaManager.forseCancelExporting()
        }
        self.didClose?({
            self.dellocSElibraryAndAlbumVC()
        })
    }
    
    // When pressing "Next"
    @objc
    func done() {
        guard let libraryVC = libraryVC else { print("⚠️ YPPickerVC >>> YPLibraryVC deallocated"); return }
        
        if mode == .library {
            libraryVC.doAfterPermissionCheck { [weak self] in
                libraryVC.selectedMedia(photoCallback: { photo in
                    self?.didSelectItems?([YPMediaItem.photo(p: photo)])
                }, videoCallback: { video in
                    self?.didSelectItems?([YPMediaItem
                        .video(v: video)])
                }, multipleItemsCallback: { items in
                    self?.didSelectItems?(items)
                })
            }
        }
    }
    
    func stopAll() {
        libraryVC?.v.assetZoomableView.videoView.deallocate()
        videoVC?.stopCamera()
        cameraVC?.stopCamera()
    }
}

extension YPPickerVC: YPLibraryViewDelegate {
    
    public func libraryViewStartedLoading() {
        libraryVC?.isProcessing = true
        DispatchQueue.main.async {
            self.v.scrollView.isScrollEnabled = false
            self.libraryVC?.v.fadeInLoader()
            self.navigationItem.rightBarButtonItem = YPLoaders.defaultLoader
        }
    }
    
    public func libraryViewFinishedLoading() {
        libraryVC?.isProcessing = false
        DispatchQueue.main.async {
            self.v.scrollView.isScrollEnabled = YPConfig.isScrollToChangeModesEnabled
            self.libraryVC?.v.hideLoader()
            self.updateUI()
        }
    }
    
    public func libraryViewDidToggleMultipleSelection(enabled: Bool) {
        var offset = v.header.frame.height
        if #available(iOS 11.0, *) {
            offset += v.safeAreaInsets.bottom
        }
        
        v.header.bottomConstraint?.constant = enabled ? offset : 0
        v.layoutIfNeeded()
        updateUI()
    }
    
    public func noPhotosForOptions() {
        self.dismiss(animated: true) {
            self.imagePickerDelegate?.noPhotos()
        }
    }
    
    ///由于相册弹出的方式，所以这里需要主动打破循环才能释放
    private func dellocSElibraryAndAlbumVC() {
        if self.selibraryAlbumVC != nil {
            self.selibraryAlbumVC?.navigationController?.viewControllers.removeAll()
            self.selibraryAlbumVC = nil
        }
    }
}

extension YPPickerVC: SELibraryVCDelegate {
    func didFinishPicking(proceedItems: [YPMediaItem], isOriginal: Bool) {
        self.imagePickerDelegate?.didFinishPicking(proceedItems: proceedItems, isOriginal: isOriginal, completion: {
            self.dellocSElibraryAndAlbumVC()
        })
    }
}
