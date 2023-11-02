//
//  Utilities.swift
//  RukayaFileManager
//

import UIKit
import Foundation
import Photos
import Firebase
import FirebaseFirestore
import FirebaseStorage

class Utilities{
    
    func deleteMedia(of: PHAsset, from: [PHAsset], at: IndexPath){
        var selectedAsset = from
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({ [weak self] in
                    guard self != nil else { return }
                    PHAssetChangeRequest.deleteAssets([of] as NSFastEnumeration)
                }) { [weak self] success, error in
                    guard self != nil else { return }
                    if success {
                        selectedAsset.remove(at: at.item)
                        print("Media deleted successfully.")
                    } else {
                        if let error = error {
                            print("Error deleting media: \(error)")
                        }
                    }
                }
            } else {
                print("Access Denied!:")
            }
        }
    }
    
    func loadThumbnail(for asset: PHAsset, into imageView: UIImageView) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 114, height: 114), contentMode: .aspectFill, options: requestOptions) { (image, info) in
            if let image = image {
                imageView.image = image
            }
        }
    }
    
    func retrieveImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 114, height: 114), contentMode: .aspectFill, options: requestOptions) { (image, info) in
            if let image = image {
                completion(image)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Store In Firebase Functions
    
    func uploadImage(for image: UIImage, to collectionReference: CollectionReference) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let storageRef = Storage.storage().reference().child("images").child(UUID().uuidString + ".jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            storageRef.putData(imageData, metadata: metadata) { (metadata, error) in
                if let error = error {
                    print("Error storing image in Firebase Storage: \(error.localizedDescription)")
                } else {
                    storageRef.downloadURL { (url, error) in
                        if let downloadURL = url?.absoluteString {
                            let data = ["imageURL": downloadURL]
                            collectionReference.addDocument(data: data) { error in
                                if let error = error {
                                    print("Error storing data in Firestore: \(error.localizedDescription)")
                                } else {
                                    print("Data stored in Firestore successfully!")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func uploadVideo(for asset: PHAsset, to collectionReference: CollectionReference) {
        let requestOptions = PHVideoRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        PHImageManager.default().requestAVAsset(forVideo: asset, options: requestOptions) { (avAsset, audioMix, info) in
            if let urlAsset = avAsset as? AVURLAsset {
                let videoURL = urlAsset.url
                let storageRef = Storage.storage().reference().child("videos").child(UUID().uuidString + ".mp4")
                let metadata = StorageMetadata()
                metadata.contentType = "video/mp4"

                storageRef.putFile(from: videoURL, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error storing video in Firebase Storage: \(error.localizedDescription)")
                    } else {
                        storageRef.downloadURL { (url, error) in
                            if let downloadURL = url?.absoluteString {
                                let data = ["videoURL": downloadURL]
                                collectionReference.addDocument(data: data) { error in
                                    if let error = error {
                                        print("Error storing data in Firestore: \(error.localizedDescription)")
                                    } else {
                                        print("Data stored in Firestore successfully!")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
