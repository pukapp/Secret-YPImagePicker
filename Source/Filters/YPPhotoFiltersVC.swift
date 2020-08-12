//
//  YPPhotoFiltersVC.swift
//  photoTaking
//
//  Created by Sacha Durand Saint Omer on 21/10/16.
//  Copyright © 2016 octopepper. All rights reserved.
//

import UIKit

protocol IsMediaFilterVC: class {
    var didSave: ((YPMediaItem) -> Void)? { get set }
    var didCancel: (() -> Void)? { get set }
}

open class YPPhotoFiltersVC: UIViewController, IsMediaFilterVC, UIGestureRecognizerDelegate {
    
    required public init(inputPhoto: YPMediaPhoto, isFromSelectionVC: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.inputPhoto = inputPhoto
        self.isFromSelectionVC = isFromSelectionVC
    }
    
    public var inputPhoto: YPMediaPhoto!
    public var isFromSelectionVC = false

    public var didSave: ((YPMediaItem) -> Void)?
    public var didCancel: (() -> Void)?

    fileprivate let filters: [YPFilter] = YPConfig.filters

    fileprivate var selectedFilter: YPFilter?
    
    fileprivate var filteredThumbnailImagesArray: [UIImage] = []
    fileprivate var thumbnailImageForFiltering: CIImage? // Small image for creating filters thumbnails
    fileprivate var currentlySelectedImageThumbnail: UIImage? // Used for comparing with original image when tapped

    fileprivate var v = YPFiltersView()

    override open var prefersStatusBarHidden: Bool { return YPConfig.hidesStatusBar }
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    fileprivate let navigationView = UIView()
    fileprivate var rightDoneBtn = UIButton()
    fileprivate lazy var activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.color = YPConfig.colors.navigationBarActivityIndicatorColor
        navigationView.addSubview(spinner)
        spinner.bounds = CGRect.init(x: 0, y: 0, width: 15, height: 15)
        spinner.center = CGPoint.init(x: navigationView.frame.size.width - 30 , y: navigationView.frame.size.height - 20)
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    // MARK: - Life Cycle ♻️
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(v)
        v.frame = CGRect.init(x: 0, y: UIScreen.navBarHeight, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - UIScreen.navBarHeight)
        
        // Setup of main image an thumbnail images
        v.imageView.image = inputPhoto.image
        thumbnailImageForFiltering = thumbFromImage(inputPhoto.image)
        DispatchQueue.global().async {
            self.filteredThumbnailImagesArray = self.filters.map { filter -> UIImage in
                if let applier = filter.applier,
                    let thumbnailImage = self.thumbnailImageForFiltering,
                    let outputImage = applier(thumbnailImage) {
                    return outputImage.toUIImage()
                } else {
                    return self.inputPhoto.originalImage
                }
            }
            DispatchQueue.main.async {
                self.v.collectionView.reloadData()
                self.v.collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                            animated: false,
                                            scrollPosition: UICollectionView.ScrollPosition.bottom)
                self.v.filtersLoader.stopAnimating()
            }
        }
        
        // Setup of Collection View
        v.collectionView.register(YPFilterCollectionViewCell.self, forCellWithReuseIdentifier: "FilterCell")
        v.collectionView.dataSource = self
        v.collectionView.delegate = self

        view.backgroundColor = YPConfig.colors.filterBackgroundColor
        
        // Setup of Navigation Bar
        title = YPConfig.wordings.filter
        if isFromSelectionVC {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(cancel))
            navigationItem.leftBarButtonItem?.setFont(font: YPConfig.fonts.leftBarButtonFont, forState: .normal)
        }
        setupRightBarButton()
        
        // Custom of Navigation Bar
        setupCustomBarButton()
        
        YPHelper.changeBackButtonIcon(self)
        YPHelper.changeBackButtonTitle(self)
        
        // Touch preview to see original image.
        let touchDownGR = UILongPressGestureRecognizer(target: self,
                                                       action: #selector(handleTouchDown))
        touchDownGR.minimumPressDuration = 0
        touchDownGR.delegate = self
        v.imageView.addGestureRecognizer(touchDownGR)
        v.imageView.isUserInteractionEnabled = true
    }
    
    // MARK: Setup - ⚙️
    // 这里采用自定义的是因为这里会出现一个bug，当图库点击下一步的时候，导航bar不会改变。此bug无法定位的根源，所以这里先采用自定义的方式
    fileprivate func setupCustomBarButton() {
        navigationView.backgroundColor = .white
        self.view.addSubview(navigationView)
        navigationView.frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.navBarHeight)
        
        let titleLabel = UILabel.init()
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.text = YPConfig.wordings.filter
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        navigationView.addSubview(titleLabel)
        titleLabel.center = CGPoint.init(x: navigationView.frame.size.width/2.0, y: navigationView.frame.size.height - 20)
        titleLabel.bounds = CGRect.init(x: 0, y: 0, width: 100, height: 20)
        
        let rightBarButtonTitle = isFromSelectionVC ? YPConfig.wordings.done : YPConfig.wordings.next
//<<<<<<< HEAD
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
//                                                            style: .done,
//                                                            target: self,
//                                                            action: #selector(save))
//        navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
//        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
//=======
        rightDoneBtn = UIButton.init()
        rightDoneBtn.setTitle(rightBarButtonTitle, for: .normal)
        rightDoneBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        rightDoneBtn.setTitleColor(YPConfig.colors.tintColor, for: .normal)
        rightDoneBtn.addTarget(self, action: #selector(save), for: .touchUpInside)
        rightDoneBtn.bounds = CGRect.init(x: 0, y: 0, width: 80, height: 25)
        rightDoneBtn.contentHorizontalAlignment = .right
        rightDoneBtn.center = CGPoint.init(x: UIScreen.main.bounds.width - 10 - 40, y: navigationView.frame.size.height - 20)
        navigationView.addSubview(rightDoneBtn)
        
        if isFromSelectionVC {
            let cancelBtn = UIButton.init()
            cancelBtn.setTitle(YPConfig.wordings.cancel, for: .normal)
            cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            cancelBtn.setTitleColor(YPConfig.colors.tintColor, for: .normal)
            cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
            cancelBtn.bounds = CGRect.init(x: 0, y: 0, width: 80, height: 20)
            cancelBtn.center = CGPoint.init(x: navigationView.frame.minX + 10 + 40, y: titleLabel.center.y)
            cancelBtn.contentHorizontalAlignment = .left
            navigationView.addSubview(cancelBtn)
        } else {
            let popBtn = UIButton.init()
            popBtn.setImage(YPIcons().backButtonIcon, for: .normal)
            popBtn.addTarget(self, action: #selector(pop), for: .touchUpInside)
            popBtn.bounds = CGRect.init(x: 0, y: 0, width: 60, height: 20)
            popBtn.center = CGPoint.init(x: navigationView.frame.minX + 13 + 30, y: titleLabel.center.y)
            popBtn.contentHorizontalAlignment = .left
            navigationView.addSubview(popBtn)
        }
//>>>>>>> secret
    }
    
    func dealProcess(isStart: Bool) {
        self.rightDoneBtn.isHidden = isStart
        if isStart {
            self.activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }
    }

    // MARK: - Methods 🏓

    @objc
    fileprivate func handleTouchDown(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            v.imageView.image = inputPhoto.originalImage
        case .ended:
            v.imageView.image = currentlySelectedImageThumbnail ?? inputPhoto.originalImage
        default: ()
        }
    }
    
    fileprivate func thumbFromImage(_ img: UIImage) -> CIImage {
        let k = img.size.width / img.size.height
        let scale = UIScreen.main.scale
        let thumbnailHeight: CGFloat = 300 * scale
        let thumbnailWidth = thumbnailHeight * k
        let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailHeight)
        UIGraphicsBeginImageContext(thumbnailSize)
        img.draw(in: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height))
        let smallImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return smallImage!.toCIImage()!
    }
    
    // MARK: - Actions 🥂

    @objc
    func cancel() {
        didCancel?()
    }
    
    @objc
    func pop() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc
    func save() {
        guard let didSave = didSave else { return print("Don't have saveCallback") }
        self.dealProcess(isStart: true)

        DispatchQueue.global().async {
            if let f = self.selectedFilter,
                let applier = f.applier,
                let ciImage = self.inputPhoto.originalImage.toCIImage(),
                let modifiedFullSizeImage = applier(ciImage) {
                self.inputPhoto.modifiedImage = modifiedFullSizeImage.toUIImage()
            } else {
                self.inputPhoto.modifiedImage = nil
            }
            DispatchQueue.main.async {
                self.dealProcess(isStart: false)
                didSave(YPMediaItem.photo(p: self.inputPhoto))
            }
        }
    }
}

extension YPPhotoFiltersVC: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredThumbnailImagesArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let filter = filters[indexPath.row]
        let image = filteredThumbnailImagesArray[indexPath.row]
        if let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: "FilterCell",
                                 for: indexPath) as? YPFilterCollectionViewCell {
            cell.name.text = filter.name
            cell.imageView.image = image
            return cell
        }
        return UICollectionViewCell()
    }
}

extension YPPhotoFiltersVC: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilter = filters[indexPath.row]
        currentlySelectedImageThumbnail = filteredThumbnailImagesArray[indexPath.row]
        self.v.imageView.image = currentlySelectedImageThumbnail
    }
}
