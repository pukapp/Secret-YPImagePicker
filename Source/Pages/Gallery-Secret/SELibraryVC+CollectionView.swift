//
//  SELibraryVC+CollectionView.swift
//  YPImagePicker
//
//  Created by 刘超 on 2019/8/24.
//  Copyright © 2019 Yummypets. All rights reserved.
//

import Foundation
import UIKit

extension SELibraryVC {

    var isLimitExceeded: Bool { return selection.count >= YPConfig.library.maxNumberOfItems }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = self.cellSize()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(YPLibraryViewCell.self, forCellWithReuseIdentifier: "YPLibraryViewCell")
        self.view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomToolView.topAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }

    // MARK: - Library collection view cell managing

    /// Removes cell from selection
    func deselect(indexPath: IndexPath) {
        if let positionIndex = selection.index(where: { $0.assetIdentifier == mediaManager.fetchResult[reverseIndex(indexPath.row)].localIdentifier }) {
            selection.remove(at: positionIndex)

            // Refresh the numbers
            var selectedIndexPaths = [IndexPath]()
            mediaManager.fetchResult.enumerateObjects { [unowned self] (asset, index, _) in
                if self.selection.contains(where: { $0.assetIdentifier == asset.localIdentifier }) {
                    selectedIndexPaths.append(IndexPath(row: index, section: 0))
                }
            }
            self.collectionView.reloadItems(at: selectedIndexPaths)
        }
    }

    /// Adds cell to selection
    ///新增isSelected 来判断当前是否是选择状态。
    func addToSelection(indexPath: IndexPath, isSelected: Bool) {
        let asset = mediaManager.fetchResult[reverseIndex(indexPath.item)]
        if asset.mediaType == .video && selection.count > 0 {
            ///不能同时选择视频和图片
            chooseErrorType()
            return
        }
        if selection.count > 0 && selection.first!.mediaType == .video {
            ///视频只能单选
            videoCheckLimit()
            return
        }
        if selection.count == YPConfig.library.maxNumberOfItems {
            photosCheckLimit()
            return
        }
        
        selection.append(
            YPLibrarySelection(
                index: reverseIndex(indexPath.row),
                assetIdentifier: asset.localIdentifier,
                mediaType: asset.mediaType,
                isSelected: isSelected
            )
        )
    }

    func isInSelectionPool(indexPath: IndexPath) -> Bool {
        return selection.contains(where: { $0.assetIdentifier == mediaManager.fetchResult[reverseIndex(indexPath.row)].localIdentifier })
    }

    func videoCheckLimit() {
        self.present(YPAlert.videoChooseAmountLimit(self.view), animated: true, completion: nil)
    }
    
    func photosCheckLimit() {
        self.present(YPAlert.maxItemsLimit(self.view), animated: true, completion: nil)
    }

    func chooseErrorType() {
        self.present(YPAlert.canChooseOneType(self.view), animated: true, completion: nil)
    }
}

extension SELibraryVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func reverseIndex(_ item: Int) -> Int {
        return mediaManager.fetchResult.count - 1 - item
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaManager.fetchResult.count
    }
    
    func cellSize() -> CGSize {
        let size = UIScreen.main.bounds.width/4 * UIScreen.main.scale
        return CGSize(width: size, height: size)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = mediaManager.fetchResult[reverseIndex(indexPath.item)]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "YPLibraryViewCell",
                                                            for: indexPath) as? YPLibraryViewCell else {
                                                                fatalError("unexpected cell in collection view")
        }
        cell.representedAssetIdentifier = asset.localIdentifier
        cell.multipleSelectionIndicator.selectionColor = YPConfig.colors.multipleItemsSelectedCircleColor
            ?? YPConfig.colors.tintColor
        mediaManager.imageManager?.requestImage(for: asset,
                                                targetSize: self.cellSize(),
                                                contentMode: .aspectFill,
                                                options: nil) { image, _ in
                                                    // The cell may have been recycled when the time this gets called
                                                    // set image only if it's still showing the same asset.
                                                    if cell.representedAssetIdentifier == asset.localIdentifier && image != nil {
                                                        cell.imageView.image = image
                                                    }
        }
        
        let isVideo = (asset.mediaType == .video)
        cell.durationLabel.isHidden = !isVideo
        cell.durationLabel.text = isVideo ? YPHelper.formattedStrigFrom(asset.duration) : ""
        
        //cell.isSelected = currentlySelectedIndex == indexPath.row
        
        // Set correct selection number
        if let index = selection.index(where: { $0.assetIdentifier == asset.localIdentifier }) {
            cell.multipleSelectionIndicator.set(number: index + 1) // start at 1, not 0
        } else {
            cell.multipleSelectionIndicator.set(number: nil)
        }
        
        // Prevent weird animation where thumbnail fills cell on first scrolls.
        UIView.performWithoutAnimation {
            cell.layoutIfNeeded()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cellIsInTheSelectionPool = isInSelectionPool(indexPath: indexPath)
        
        if cellIsInTheSelectionPool {
            deselect(indexPath: indexPath)
        } else {
            addToSelection(indexPath: indexPath, isSelected: true)
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
}

extension SELibraryVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margins = 4 * CGFloat(YPConfig.library.numberOfItemsInRow - 1)
        let width = (collectionView.frame.width - margins) / CGFloat(YPConfig.library.numberOfItemsInRow)
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
}
