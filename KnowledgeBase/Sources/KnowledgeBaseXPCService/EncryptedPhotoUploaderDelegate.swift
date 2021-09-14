//
//  EncryptedPhotoUploaderDelegate.swift
//  
//
//  Created by Gennaro Frazzingaro on 8/11/21.
//

import Foundation
import KnowledgeBase
import Photos

struct EncryptedPhotoUploaderDelegate: KBPhotoAssetChangeDelegate {
    func wasAddedToCameraRoll(asset: PHAsset) {
        
        if asset.mediaType == .image {
            self.getPictureAsData(from: asset) { result in
                switch result {
                case .success(let data):
                    let encryptedData = self.encrypt(data: data)
                    self.upload(data: encryptedData) { uploadResult in
                        if case .failure(let error) = uploadResult {
                            log.error("Failed to upload picture: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    log.error("Failed to retrieve picture from asset \(asset): \(error.localizedDescription)")
                }
            }
        } else {
            
        }
    }
    
    func wasRemovedFromCameraRoll(asset: PHAsset) {
        // Remove data from the cloud?
    }
    
    
    func encrypt(data: Data) -> Data {
        return data
    }
    
    func upload(data: Data, completionHandler: (Swift.Result<Void, Error>) -> ()) {
        // Call the lambda with the data encrypted locally
    }
    
    func getPictureAsData(from asset: PHAsset, completionHandler: (Swift.Result<Data, Error>) -> ()) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.version = .current
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) {
            data, dataUTI, orientation, resultInfoKeys in
            
        }
    }
}
