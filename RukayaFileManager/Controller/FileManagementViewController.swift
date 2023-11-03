//
//  ViewController.swift
//  RukayaFileManager
//

import UIKit
import Foundation
import Photos
import Firebase
import FirebaseFirestore
import FirebaseStorage
import UserNotifications

class FileManagementViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var authLabel: UILabel!
    
    var cameraAssets: [PHAsset] = []
    var screenshotsAssets: [PHAsset] = []
    var videoAssets: [PHAsset] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupCollectionView()
        requestAuthFromUser()
    }
    
    // MARK: - Setup Functions
    
    func setupCollectionView(){
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.register(UINib(nibName: "CameraCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "cameraCell")
        collectionView.register(UINib(nibName: "ScreenshotsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "screenshotsCell")
        collectionView.register(UINib(nibName: "VideoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "videoCell")
    }
    
    // MARK: - Fetch Media
    
    func requestAuthFromUser(){
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                self.fetchCameraLibrary()
                self.fetchScreenshotsPhotos()
                self.fetchVideos()
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            } else {
                self.authLabel.text = "Access to Gallery Denied!"
            }
        }
    }
    
    func fetchCameraLibrary() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        
        for index in 0..<fetchResult.count {
            let asset = fetchResult.object(at: index)
            cameraAssets.append(asset)
        }
    }
    
    func fetchScreenshotsPhotos(){
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaSubtype == %ld", PHAssetMediaSubtype.photoScreenshot.rawValue)
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        for index in 0..<fetchResult.count {
            let asset = fetchResult.object(at: index)
            screenshotsAssets.append(asset)
        }
    }
    
    func fetchVideos(){
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        for index in 0..<fetchResult.count {
            let asset = fetchResult.object(at: index)
            videoAssets.append(asset)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return cameraAssets.count
        case 1:
            return screenshotsAssets.count
        case 2:
            return videoAssets.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell

        switch segmentedControl.selectedSegmentIndex {
        case 0:
            if indexPath.row < cameraAssets.count {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cameraCell", for: indexPath) as! CameraCollectionViewCell
                if let cameraCell = cell as? CameraCollectionViewCell {
                    
                    cameraCell.layer.cornerRadius = 10
                    let imageView = cameraCell.cameraImage!
                    imageView.contentMode = .scaleAspectFill
                    let selectedAsset = cameraAssets[indexPath.row]
                    Utilities().loadThumbnail(for: selectedAsset, into: imageView)
                }
            } else {
                cell = UICollectionViewCell()
            }
        case 1:
            if indexPath.row < screenshotsAssets.count {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "screenshotsCell", for: indexPath) as! ScreenshotsCollectionViewCell
                if let screenshotsCell = cell as? ScreenshotsCollectionViewCell {
                    screenshotsCell.layer.cornerRadius = 10
                    let imageView = screenshotsCell.screenshotImage!
                    imageView.contentMode = .scaleAspectFill
                    let selectedAsset = screenshotsAssets[indexPath.row]
                    Utilities().loadThumbnail(for: selectedAsset, into: imageView)
                }
            } else {
                cell = UICollectionViewCell()
            }
        case 2:
            if indexPath.row < videoAssets.count {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "videoCell", for: indexPath) as! VideoCollectionViewCell
                if let videoCell = cell as? VideoCollectionViewCell {
                    videoCell.layer.cornerRadius = 10
                    let imageView = videoCell.videoImage!
                    imageView.contentMode = .scaleAspectFill
                    let selectedAsset = videoAssets[indexPath.row]
                    Utilities().loadThumbnail(for: selectedAsset, into: imageView)
                }
            } else {
                cell = UICollectionViewCell()
            }
        default:
            cell = UICollectionViewCell()
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth: CGFloat = 114
        let cellHeight: CGFloat = 114
        return CGSize(width: cellWidth, height: cellHeight)
    }

    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var selectedAsset: PHAsset
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            selectedAsset = self.cameraAssets[indexPath.item]
            self.displayAlert(forItem: selectedAsset, from: cameraAssets, at: indexPath)
        case 1:
            selectedAsset = self.screenshotsAssets[indexPath.item]
            self.displayAlert(forItem: selectedAsset, from: screenshotsAssets, at: indexPath)
        case 2:
            selectedAsset = self.videoAssets[indexPath.item]
            self.displayAlert(forItem: selectedAsset, from: videoAssets, at: indexPath)
        default:
            return
        }
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        collectionView.reloadData()
    }
    
    func displayAlert(forItem: PHAsset, from: [PHAsset], at: IndexPath){
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let storeAction = UIAlertAction(title: "Store in Firestore", style: .default) { (action) in
            let db = Firestore.firestore()
            let collectionReference = db.collection("your_collection_name")
            if forItem.mediaType == .image {
                Utilities().retrieveImage(for: forItem) { image in
                    if let image = image {
                        Utilities().uploadImage(for: image, to: collectionReference)
                    }
                }
            }  else if forItem.mediaType == .video {
                Utilities().uploadVideo(for: forItem, to: collectionReference)
            }
            let content = UNMutableNotificationContent()
            content.title = "Media Stored"
            content.body = "Your media has been stored in Firestore."
            let request = UNNotificationRequest(identifier: "MediaStoredNotification", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
        
        let deleteAction = UIAlertAction(title: "Delete From Gallery", style: .destructive) { (action) in
            Utilities().deleteMedia(of: forItem, from: from, at: at)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            let content = UNMutableNotificationContent()
            content.title = "Media Deleted"
            content.body = "Your media has been deleted from the gallery."
            let request = UNNotificationRequest(identifier: "MediaDeletedNotification", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(storeAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
}

