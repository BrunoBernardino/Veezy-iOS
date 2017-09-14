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

class ImageViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewButton: UIButton!
    
    var chosenImages: [String] = []
    var chosenInterval: Int = 5
    
    let defaults = UserDefaults.standard
    let chosenImagesDefaultsKey = "chosenImages"
    let chosenIntervalDefaultsKey = "chosenInterval"
    
    var images: [String] = []
    var currentImageIndex: Int = 0
    var isAnimating: Bool = false
    
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
        
        // Don't fall asleep
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Make sure to loop from the beginning, and reshuffle
        if (self.currentImageIndex >= self.images.count) {
            self.currentImageIndex = 0
            self.images.shuffle()
        }
        
        let imageManager = PHCachingImageManager()
        
        UIView.transition(with: imageView, duration: 0.5, options: .transitionCrossDissolve, animations: {
            // TODO: Show live photos as videos/animations: https://stackoverflow.com/questions/33990830/working-with-live-photos-in-playground
            let asset = PHAsset.fetchAssets(withLocalIdentifiers: [self.images[self.currentImageIndex]], options: nil).firstObject!
            
            let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = true

            imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: {
                    (image, info) -> Void in
                    self.imageView.image = image
             })
        }, completion: {
            (completed: Bool) -> Void in
            self.currentImageIndex += 1

            if (self.isAnimating) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(self.chosenInterval), execute: {
                    self.playSlideshow()
                })
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentImageIndex = 0

        chosenImages = defaults.value(forKey: chosenImagesDefaultsKey) as! [String]
        
        for chosenImage in chosenImages {
            images.append(chosenImage)
        }
        
        images.shuffle()
        
        chosenInterval = defaults.value(forKey: chosenIntervalDefaultsKey) as! Int
        
        // imageView defaults
        imageView.contentMode = .scaleAspectFit
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.isAnimating = true

        playSlideshow()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}
