//
//  ViewController.swift
//  Veezy
//
//  Created by Bruno Bernardino on 10/09/2017.
//  Copyright © 2017 Bruno Bernardino. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var startSlideshowButton: UIButton!
    @IBOutlet weak var photoIntervalSlider: UISlider!
    @IBOutlet weak var photoIntervalSliderLabel: UILabel!

    var chosenImages: [String] = []
    var chosenInterval: Int = 5
    
    var photoAssets = PHFetchResult<AnyObject>()
    
    let defaults = UserDefaults.standard
    let chosenImagesDefaultsKey = "chosenImages"
    let chosenIntervalDefaultsKey = "chosenInterval"
    
    @IBAction func photoIntervalSliderChanged(_ sender: Any) {
        chosenInterval = Int(photoIntervalSlider.value)
        
        defaults.set(chosenInterval, forKey: chosenIntervalDefaultsKey)
        
        refreshUI()
    }

    func addAsset(assetLocalIdentifier: String) {
        chosenImages.append(assetLocalIdentifier)
        
        defaults.set(chosenImages, forKey: chosenImagesDefaultsKey)
        
        refreshUI()
    }
    
    func fetchImagesFromAlbum() {
        let albumName = "Veezy"
        var assetCollection = PHAssetCollection()
        var albumFound = Bool()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _:AnyObject = collection.firstObject{
            assetCollection = collection.firstObject!
            albumFound = true
        } else {
            albumFound = false
        }
        
        if (!albumFound) {
            let alert = UIAlertController(title: "Oops!", message: "I wasn't able to find a photo album named \"Veezy\" (without quotes).\nPlease create one and make sure it has photos.\n\nPRO TIP: Use a shared album with family, so they can add to it easily too!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            startSlideshowButton.setTitle("\"Veezy\" album not found.", for: .normal)
            return;
        }
        
        photoAssets = PHAsset.fetchAssets(in: assetCollection, options: nil) as! PHFetchResult<AnyObject>
        
        photoAssets.enumerateObjects(using: {(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset {
                let asset = object as! PHAsset
                
                self.addAsset(assetLocalIdentifier: asset.localIdentifier)
            }
        })
    }
    
    func refreshUI() {
        if (chosenImages.count > 0) {
            startSlideshowButton.setTitle("Start Slideshow", for: .normal)
            photoIntervalSliderLabel.text = String(chosenInterval) + " seconds per photo"
            photoIntervalSlider.value = Float(chosenInterval)
            startSlideshowButton.isEnabled = true
            photoIntervalSlider.isHidden = false
            photoIntervalSliderLabel.isHidden = false
        } else {
            startSlideshowButton.setTitle("Loading album...", for: .normal)
            startSlideshowButton.isEnabled = false
            photoIntervalSlider.isHidden = true
            photoIntervalSliderLabel.isHidden = true
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clear past album photos from settings, allowing album to refresh
        defaults.set(chosenImages, forKey: chosenImagesDefaultsKey)
        
        // Get Interval from user settings
        let chosenIntervalFromDefaults = defaults.value(forKey: chosenIntervalDefaultsKey) as? Int
        
        if (chosenIntervalFromDefaults != nil) {
            chosenInterval = chosenIntervalFromDefaults!
        } else {
            // Save initial default value
            defaults.set(chosenInterval, forKey: chosenIntervalDefaultsKey)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        fetchImagesFromAlbum()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

