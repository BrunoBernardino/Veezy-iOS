//
//  ImageViewController.swift
//  Veezy
//
//  Created by Bruno Bernardino on 12/09/2017.
//  Copyright © 2017 Bruno Bernardino. All rights reserved.
//

import Foundation
import UIKit
import Photos
import PhotosUI

class ImageViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var placeholderView: UIView!
    var imageView: UIImageView!
    var livePhotoView: PHLivePhotoView!
    @IBOutlet weak var imageViewButton: UIButton!
    
    var chosenImages: [String] = []
    var chosenInterval: Int = 5
    
    let defaults = UserDefaults.standard
    let chosenImagesDefaultsKey = "chosenImages"
    let chosenIntervalDefaultsKey = "chosenInterval"
    
    var images: [String] = []
    var currentImageIndex: Int = 0
    var isAnimating: Bool = false
    
    var loopAgain = true
    
    @IBAction func goBackToMainScreen(_ sender: Any) {
        UIApplication.shared.isIdleTimerDisabled = false
        self.isAnimating = false
        self.dismiss(animated: false, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func playSlideshow() {
        // Stop if we're gone
        if (!self.isAnimating) {
            return;
        }
        
        self.loopAgain = false
        
        // Stop live photo playback
        self.livePhotoView.stopPlayback()
        
        // Don't fall asleep
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Make sure to loop from the beginning, and reshuffle
        if (self.currentImageIndex >= self.images.count) {
            self.currentImageIndex = 0
            self.images.shuffle()
        }
        
        let imageManager = PHImageManager.default()
        
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [self.images[self.currentImageIndex]], options: nil).firstObject!
        
        let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        
        // NOTE: As a future improvement, here this can potentially only start the transition once it's sure the next asset has been loaded by attempting a synchronous "showStaticPhoto" or "showLivePhoto"
        
        UIView.transition(with: self.placeholderView, duration: 0.5, options: .transitionCrossDissolve, animations: {
            if (asset.mediaSubtypes.contains(.photoLive)) {
                self.showLivePhoto(asset: asset, imageSize: imageSize, imageManager: imageManager, display: true)
            } else {
                self.showStaticPhoto(asset: asset, imageSize: imageSize, imageManager: imageManager, display: true)
            }
        }, completion: {
            (completed: Bool) -> Void in
            self.currentImageIndex += 1
            
            // Cache next image
            if (self.currentImageIndex < self.images.count) {
                let nextAsset = PHAsset.fetchAssets(withLocalIdentifiers: [self.images[self.currentImageIndex]], options: nil).firstObject!
                if (nextAsset.mediaSubtypes.contains(.photoLive)) {
                    self.showLivePhoto(asset: nextAsset, imageSize: imageSize, imageManager: imageManager, display: false)
                } else {
                    self.showStaticPhoto(asset: nextAsset, imageSize: imageSize, imageManager: imageManager, display: false)
                }
            }
        })
    }
    
    func showStaticPhoto(asset: PHAsset, imageSize: CGSize, imageManager: PHImageManager, display: Bool) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false // Otherwise image can come back as nil if it isn't cached in the device
        
        imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
            (image, info) -> Void in
            // print("Finished requesting static photo", asset.localIdentifier)
            // print(image as Any)
            if (display) {
                self.imageView.isHidden = false
                self.livePhotoView.isHidden = true
                self.imageView.image = image
                
                // Move to the next image only after image has finished loading
                if (self.isAnimating) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(self.chosenInterval), execute: {
                        self.playSlideshow()
                    })
                }
            }
        })
    }
    
    func showLivePhoto(asset: PHAsset, imageSize: CGSize, imageManager: PHImageManager, display: Bool) {
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        if (display) {
            self.loopAgain = true
        }
        
        imageManager.requestLivePhoto(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
            (livePhoto, info) -> Void in
            // print("Finished requesting live photo", asset.localIdentifier)
            // print(livePhoto as Any)
            if (display) {
                self.imageView.isHidden = true
                self.livePhotoView.isHidden = false
                self.livePhotoView.livePhoto = livePhoto
                
                // Delay live photo playback for 2 seconds, if interval is greater
                if (self.chosenInterval > 2) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                        self.livePhotoView.startPlayback(with: .full)
                    })
                }
                
                // Move to the next image only after image has finished loading
                if (self.isAnimating) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(self.chosenInterval), execute: {
                        self.playSlideshow()
                    })
                }
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView = UIImageView.init(frame: self.view.frame)
        self.livePhotoView = PHLivePhotoView.init(frame: self.view.frame)
        self.livePhotoView.delegate = self
        self.livePhotoView.isMuted = true
        self.imageView.isHidden = true
        self.livePhotoView.isHidden = true
        
        self.placeholderView.addSubview(self.imageView)
        self.placeholderView.addSubview(self.livePhotoView)

        self.imageView?.contentMode = .scaleAspectFit
        self.livePhotoView?.contentMode = .scaleAspectFit
        
        currentImageIndex = 0

        chosenImages = defaults.value(forKey: chosenImagesDefaultsKey) as! [String]
        
        for chosenImage in chosenImages {
            images.append(chosenImage)
        }
        
        images.shuffle()
        
        chosenInterval = defaults.value(forKey: chosenIntervalDefaultsKey) as! Int
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.isAnimating = true

        playSlideshow()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

// MARK: PHLivePhotoViewDelegate
extension ImageViewController: PHLivePhotoViewDelegate {
    // Loop, by starting when it's finished.
    func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        if (self.loopAgain) {
            livePhotoView.startPlayback(with: .full)
        }
    }
}
