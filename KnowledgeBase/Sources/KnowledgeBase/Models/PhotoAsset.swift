//
//  PhotoAsset.swift
//  
//
//  Created by Gennaro Frazzingaro on 8/19/21.
//

import Photos
import Foundation

private let PHAssetIdentifierKey = "phAssetLocalIdentifier"
private let CachedDataKey = "cachedData"
private let CachedUpdatedAtKey = "cacheUpdatedAt"

public class KBPhotoAsset : NSObject, NSSecureCoding {
    public static var supportsSecureCoding = true
    
    var imageManager: PHImageManager
    
    public let phAsset: PHAsset
    public var cachedData: Data?
    public var cacheUpdatedAt: Date?
    
    public init(for asset: PHAsset, cachedData: Data? = nil, cacheUpdatedAt: Date? = nil) {
        self.phAsset = asset
        self.cachedData = cachedData
        self.cacheUpdatedAt = cacheUpdatedAt
        self.imageManager = PHImageManager.default()
    }
    
    public convenience init(for asset: PHAsset, usingCachingImageManager manager: PHCachingImageManager) {
        self.init(for: asset)
        self.imageManager = manager
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(self.phAsset.localIdentifier, forKey: PHAssetIdentifierKey)
        coder.encode(self.cachedData, forKey: CachedDataKey)
        coder.encode(self.cacheUpdatedAt, forKey: CachedUpdatedAtKey)
    }
    
    public required convenience init?(coder decoder: NSCoder) {
        let phAssetIdentifier = decoder.decodeObject(of: NSString.self, forKey: PHAssetIdentifierKey)
        let cachedData = decoder.decodeObject(of: NSData.self, forKey: CachedDataKey)
        let cacheUpdatedAt = decoder.decodeObject(of: NSDate.self, forKey: CachedUpdatedAtKey)
        
        guard let phAssetIdentifier = phAssetIdentifier as String? else {
            log.error("unexpected value for phAssetIdentifier when decoding KBPhotoAsset object")
            return nil
        }
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [phAssetIdentifier], options: nil)
        guard fetchResult.count > 0 else {
            return nil
        }
        
        let asset = fetchResult.object(at: 0)
        
        guard let cachedData = cachedData as Data?,
              let cacheUpdatedAt = cacheUpdatedAt as Date? else {
                  self.init(for: asset)
                  return
        }
        self.init(for: asset, cachedData: cachedData, cacheUpdatedAt: cacheUpdatedAt)
    }
    
    /// /// Retrieves the Data representation for the PHAsset from the Library for `.image` and `.video` mediaTypes.
    /// - Parameter shouldCache: whether or not the data property of this object should be updated with the result  (defaults to `true`)
    /// - Returns: the Data object for the `PHAsset`
    public func data(shouldCache: Bool = true) -> Data? {
        if let data = self.cachedData,
           (self.phAsset.modificationDate ?? .distantPast).compare(self.cacheUpdatedAt ?? .distantPast) == .orderedDescending {
            return data
        }
        
        let options = PHImageRequestOptions()
        var assetData: Data? = nil
        options.isSynchronous = true
        
        switch self.phAsset.mediaType {
        case .image:
            self.imageManager.requestImageDataAndOrientation(for: self.phAsset, options: options) { data, _, _, _ in
                if let data = data {
                    assetData = data
                }
            }
        case .video:
            self.imageManager.requestAVAsset(forVideo: self.phAsset, options: nil) { asset, audioMix, info in
                if let asset = asset as? AVURLAsset,
                   let data = NSData(contentsOf: asset.url) as Data? {
                    assetData = data
                }
            }
        default:
            let type = self.phAsset.mediaType.rawValue
            log.error("PHAsset mediaType not supported \(type)")
        }
        
        if shouldCache && assetData != nil {
            self.cachedData = assetData
            self.cacheUpdatedAt = Date()
        }
        return assetData
    }
}
