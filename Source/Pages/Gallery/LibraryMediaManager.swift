//
//  LibraryMediaManager.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

class LibraryMediaManager {
    
    weak var v: YPLibraryView?
    var collection: PHAssetCollection?
    internal var fetchResult: PHFetchResult<PHAsset>!
    internal var previousPreheatRect: CGRect = .zero
    internal var imageManager: PHCachingImageManager?
    internal var exportTimer: Timer?
    internal var currentExportSessions: [AVAssetExportSession] = []
    
    func initialize() {
        imageManager = PHCachingImageManager()
        resetCachedAssets()
    }
    
    func resetCachedAssets() {
        imageManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    func updateCachedAssets(in collectionView: UICollectionView) {
        let screenWidth = YPImagePickerConfiguration.screenWidth
        let size = screenWidth / 4 * UIScreen.main.scale
        let cellSize = CGSize(width: size, height: size)
        
        var preheatRect = collectionView.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        if delta > collectionView.bounds.height / 3.0 {
            
            var addedIndexPaths: [IndexPath] = []
            var removedIndexPaths: [IndexPath] = []
            
            previousPreheatRect.differenceWith(rect: preheatRect, removedHandler: { removedRect in
                let indexPaths = collectionView.aapl_indexPathsForElementsInRect(removedRect)
                removedIndexPaths += indexPaths
            }, addedHandler: { addedRect in
                let indexPaths = collectionView.aapl_indexPathsForElementsInRect(addedRect)
                addedIndexPaths += indexPaths
            })
            
            let assetsToStartCaching = fetchResult.assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = fetchResult.assetsAtIndexPaths(removedIndexPaths)
            
            imageManager?.startCachingImages(for: assetsToStartCaching,
                                             targetSize: cellSize,
                                             contentMode: .aspectFill,
                                             options: nil)
            imageManager?.stopCachingImages(for: assetsToStopCaching,
                                            targetSize: cellSize,
                                            contentMode: .aspectFill,
                                            options: nil)
            previousPreheatRect = preheatRect
        }
    }
    
//<<<<<<< HEAD
//    func fetchVideoUrlAndCrop(for videoAsset: PHAsset,
//                              cropRect: CGRect,
//                              callback: @escaping (_ videoURL: URL?) -> Void) {
//        fetchVideoUrlAndCropWithDuration(for: videoAsset, cropRect: cropRect, duration: nil, callback: callback)
//    }
//
//    func fetchVideoUrlAndCropWithDuration(for videoAsset: PHAsset,
//                                          cropRect: CGRect,
//                                          duration: CMTime?,
//                                          callback: @escaping (_ videoURL: URL?) -> Void) {
//=======
    func fetchVideoUrlAndCrop(for videoAsset: PHAsset, cropRect: CGRect?, callback: @escaping (URL) -> Void, callError: @escaping (Error?) -> Void) {
//>>>>>>> secret
        let videosOptions = PHVideoRequestOptions()
        videosOptions.isNetworkAccessAllowed = true
        videosOptions.deliveryMode = .highQualityFormat
        imageManager?.requestAVAsset(forVideo: videoAsset, options: videosOptions) { asset, _, _ in
            do {
                guard let asset = asset else { print("⚠️ PHCachingImageManager >>> Don't have the asset"); return }
                
                let assetComposition = AVMutableComposition()
                let assetMaxDuration = self.getMaxVideoDuration(between: duration, andAssetDuration: asset.duration)
                let trackTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: assetMaxDuration)
                
                // 1. Inserting audio and video tracks in composition
                
                guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first,
                    let videoCompositionTrack = assetComposition
                        .addMutableTrack(withMediaType: .video,
                                         preferredTrackID: kCMPersistentTrackID_Invalid) else {
                                            print("⚠️ PHCachingImageManager >>> Problems with video track")
                                            return
                                            
                }
                if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first,
                    let audioCompositionTrack = assetComposition
                        .addMutableTrack(withMediaType: AVMediaType.audio,
                                         preferredTrackID: kCMPersistentTrackID_Invalid) {
                    try audioCompositionTrack.insertTimeRange(trackTimeRange, of: audioTrack, at: CMTime.zero)
                }
                
                try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: CMTime.zero)
                
                // Layer Instructions
                let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
                var transform = videoTrack.preferredTransform
                let videoSize = videoTrack.naturalSize.applying(transform)
                transform.tx = (videoSize.width < 0) ? abs(videoSize.width) : 0.0
                transform.ty = (videoSize.height < 0) ? abs(videoSize.height) : 0.0
                transform.tx -= cropRect.minX
                transform.ty -= cropRect.minY
                layerInstructions.setTransform(transform, at: CMTime.zero)
                
                // CompositionInstruction
                let mainInstructions = AVMutableVideoCompositionInstruction()
                mainInstructions.timeRange = trackTimeRange
//<<<<<<< HEAD
//                mainInstructions.layerInstructions = [layerInstructions]
//
//                // Video Composition
//                let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
//                videoComposition.instructions = [mainInstructions]
//                videoComposition.renderSize = cropRect.size // needed?
//
//                // 5. Configuring export session
//
//                let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
//=======
                
                // 3. Adding the layer instructions. Transforming
                if let cropRect = cropRect {
                    let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
                    layerInstructions.setTransform(videoTrack.getTransform(cropRect: cropRect), at: CMTime.zero)
                    layerInstructions.setOpacity(1.0, at: CMTime.zero)
                    mainInstructions.layerInstructions = [layerInstructions]
                }
                
                // 4. Create the main composition and add the instructions
                var videoComposition: AVMutableVideoComposition?
                if let cropRect = cropRect {
                    videoComposition = AVMutableVideoComposition()
                    videoComposition!.renderSize = cropRect.size
                    videoComposition!.instructions = [mainInstructions]
                    videoComposition!.frameDuration = CMTimeMake(value: 1, timescale: 30)
                }
                // 5. Configuring export session
                
                let exportSession = AVAssetExportSession(asset: assetComposition,
                                                         presetName: YPConfig.video.compression)
                exportSession?.outputFileType = YPConfig.video.fileType
                exportSession?.shouldOptimizeForNetworkUse = true
                if let videoComposition = videoComposition {
                    exportSession?.videoComposition = videoComposition
                }
                exportSession?.outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
//>>>>>>> secret
                    .appendingUniquePathComponent(pathExtension: YPConfig.video.fileType.fileExtension)
                let exportSession = assetComposition
                    .export(to: fileURL,
                            videoComposition: videoComposition,
                            removeOldFile: true) { [weak self] session in
                                DispatchQueue.main.async {
                                    switch session.status {
                                    case .completed:
                                        if let url = session.outputURL {
                                            if let index = self?.currentExportSessions.firstIndex(of: session) {
                                                self?.currentExportSessions.remove(at: index)
                                            }
                                            callback(url)
                                        } else {
                                            print("LibraryMediaManager -> Don't have URL.")
                                            callback(nil)
                                        }
                                    case .failed:
                                        print("LibraryMediaManager")
										print("Export of the video failed : \(String(describing: session.error))")
                                        callback(nil)
                                    default:
										print("LibraryMediaManager")
                                        print("Export session completed with \(session.status) status. Not handled.")
                                        callback(nil)
                                    }
                                }
                }

                // 6. Exporting
                DispatchQueue.main.async {
                    self.exportTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                                            target: self,
                                                            selector: #selector(self.onTickExportTimer),
                                                            userInfo: exportSession,
                                                            repeats: true)
                }
//<<<<<<< HEAD
//
//                if let s = exportSession {
//                    self.currentExportSessions.append(s)
//                }
//=======
                
                self.currentExportSessions.append(exportSession!)
                exportSession?.exportAsynchronously(completionHandler: {
                    DispatchQueue.main.async {
                        if let url = exportSession?.outputURL, exportSession?.status == .completed {
                            callback(url)
                            if let index = self.currentExportSessions.index(of:exportSession!) {
                                self.currentExportSessions.remove(at: index)
                            }
                        } else {
                            if let index = self.currentExportSessions.index(of:exportSession!) {
                                self.currentExportSessions.remove(at: index)
                            }
                            self.exportTimer?.invalidate()
                            self.exportTimer = nil
                            self.v?.updateProgress(0)
                            let error = exportSession?.error
                            callError(error)
                            print("error exporting video \(String(describing: error))")
                        }
                    }
                })
//>>>>>>> secret
            } catch let error {
                print("⚠️ PHCachingImageManager >>> \(error)")
            }
        }
    }
    
    private func getMaxVideoDuration(between duration: CMTime?, andAssetDuration assetDuration: CMTime) -> CMTime {
        guard let duration = duration else { return assetDuration }

        if assetDuration <= duration {
            return assetDuration
        } else {
            return duration
        }
    }
    
    @objc func onTickExportTimer(sender: Timer) {
        if let exportSession = sender.userInfo as? AVAssetExportSession {
            if let v = v {
                if exportSession.progress > 0 {
                    v.updateProgress(exportSession.progress)
                }
            }
            
            if exportSession.progress > 0.99 {
                sender.invalidate()
                v?.updateProgress(0)
                self.exportTimer = nil
            }
        }
    }
    
    func forseCancelExporting() {
        for s in self.currentExportSessions {
            s.cancelExport()
        }
    }
}
