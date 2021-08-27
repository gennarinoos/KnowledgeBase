//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 8/10/21.
//

import Foundation
import Photos

public let kKBPhotosAssetCacheStoreName = "com.gf.knowledgebase.PhotosAssetCache"
let kKBPhotosAuthorizationStatusKey = "com.gf.knowledgebase.indexer.photos.authorizationStatus"


public protocol KBPhotoAssetChangeDelegate {
    func wasAdded(asset: PHAsset)
    func wasRemoved(asset: PHAsset)
}

public class KBPhotosIndexer : NSObject, PHPhotoLibraryChangeObserver {
    
    // TODO: Maybe hashing can be handled better by overriding Hashable/Equatable? That would also make it unnecessarily complex though :(
    public var identifier: String {
        "\(self.hashValue)"
    }
    
    private let photosIndexerDefaults = KBKVStore.userDefaultsStore()
    private var delegates = [String: KBPhotoAssetChangeDelegate]()
    
    public let indexedAssets: KBKVStore // The `KBPhotoAsset` ob that have already been indexed
    public var cameraRollInMemoryCache: PHFetchResult<PHAsset>? = nil
    public let imageManager: PHCachingImageManager
    
    private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    private let ingestionQueue = DispatchQueue(label: "com.gf.knowledgebase.indexer.photos.ingestion", qos: .userInitiated)
    private let processingQueue = DispatchQueue(label: "com.gf.knowledgebase.indexer.photos.processing", qos: .background)
    
    /// Enables the indexing of the retrieved `PHAsset` in the `indexedAssetIds`
    /// as `KBPhotoAsset` objects, keyed by the `localIdentifier` of the asset
    public var shouldIndexAssets = true
    
    public override init() {
        self.indexedAssets = KBKVStore.store(withName: kKBPhotosAssetCacheStoreName)
        self.imageManager = PHCachingImageManager()
        self.imageManager.allowsCachingHighQualityImages = true
        super.init()
        self.requestAuthorization()
        PHPhotoLibrary.shared().register(self)
    }
    
    public func requestAuthorization() {
        do {
            let savedAuthStatus = try self.photosIndexerDefaults.value(for: kKBPhotosAuthorizationStatusKey)
            if let savedAuthStatus = savedAuthStatus as? Int {
                self.authorizationStatus = PHAuthorizationStatus(rawValue: savedAuthStatus) ?? .notDetermined
            }
        } catch {}
        
        if [.notDetermined, .denied].contains(self.authorizationStatus) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                self.authorizationStatus = status
                do {
                    try self.photosIndexerDefaults.set(value: status.rawValue, for: kKBPhotosAuthorizationStatusKey)
                } catch {
                    log.warning("Unable to record authorization status in UserDefaults KBKVStore")
                }
            }
        }
    }
    
    public func addDelegate<T: KBPhotoAssetChangeDelegate>(_ delegate: T) {
        self.delegates[String(describing: delegate)] = delegate
    }
    public func removeDelegate<T: KBPhotoAssetChangeDelegate>(_ delegate: T) {
        self.delegates.removeValue(forKey: String(describing: delegate))
    }
    
    private static func cameraRollPredicate() -> NSPredicate {
        return NSPredicate(format: "(mediaType = %d || mediaType = %d) && NOT (mediaSubtype & %d) != 0", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue, PHAssetMediaSubtype.photoScreenshot.rawValue)
    }
    
    // TODO: Support parameter `since: Date`
    /// Fetches the latest assets in the Camera Roll using the Photos Framework in the background
    /// and updates the `cameraRollInMemoryCache` with the corresponding `PHFetchResult`.
    /// If `shouldIndexAssets` is `true`, this method also triggers an update to the `indexedAssetIds`,
    /// storing `KBPhotoAsset` objects from the fetch result on the serial background `processingQueue`.
    /// - Parameters:
    ///   - assetIdsToExclude: a list of `PHAsset` localIdentifier to exclude from the search
    ///   - completionHandler: the completion handler
    public func updateCameraRollCache(excluding assetIdsToExclude: [String]? = nil,
                                      completionHandler: @escaping (Swift.Result<Void, Error>) -> ()) {
        self.ingestionQueue.async { [weak self] in
            guard let self = self else {
                return completionHandler(.failure(KBError.fatalError("self not available after executing block on the serial queue")))
            }
            
            // Get all the camera roll photos and videos
            let fetchResults = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
            fetchResults.enumerateObjects { collection, count, stop in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                
                var predicate = KBPhotosIndexer.cameraRollPredicate()
                if let assetIdsToExclude = assetIdsToExclude, assetIdsToExclude.count > 0 {
                    let skipCachedIdsPredicate = NSPredicate(format: "NOT (localIdentifier IN %@)", assetIdsToExclude)
                    predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, skipCachedIdsPredicate])
                }
                fetchOptions.predicate = predicate
                
                self.cameraRollInMemoryCache = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                
                if self.shouldIndexAssets {
                    if let cameraRollCache = self.cameraRollInMemoryCache {
                        self.processingQueue.async {
                            let cache: [String: Any]
                            do {
                                cache = try self.indexedAssets.dictionaryRepresentation()
                            } catch {
                                cache = [:]
                            }
                            self.updateAssetsIndex(inCache: cache, with: cameraRollCache)
                        }
                    }
                }
            }
            completionHandler(.success(()))
        }
    }
    
    private func updateAssetsIndex(inCache cache: [String: Any], with result: PHFetchResult<PHAsset>) {
        Dispatch.dispatchPrecondition(condition: .onQueue(self.processingQueue))
        
        var cachedAssetIdsToInvalidate = [String]()
        
        let writeBatch = self.indexedAssets.writeBatch()
        result.enumerateObjects { asset, count, stop in
            if let cacheHit = cache[asset.localIdentifier] as? KBPhotoAsset {
                if let whenCached = cacheHit.cacheUpdatedAt,
                   whenCached.compare(asset.modificationDate ?? .distantPast) == .orderedAscending {
                    // Asset was modified since cached -> remove from the persistent cache
                    cachedAssetIdsToInvalidate.append(asset.localIdentifier)
                }
            } else {
                let kvsAssetValue = KBPhotoAsset(for: asset, usingCachingImageManager: self.imageManager)
                writeBatch.set(value: kvsAssetValue, for: asset.localIdentifier)
            }
        }
        do {
            try writeBatch.write()
            try self.indexedAssets.removeValues(for: cachedAssetIdsToInvalidate)
        }
        catch {
            log.error("Unable to save in-memory cache to disk: \(error.localizedDescription)")
        }
    }
    
    public func updateAssetsIndex(with assets: [PHAsset], completionHandler: @escaping KBActionCompletion) {
        self.processingQueue.async {
            let cache: [String: Any]
            do {
                cache = try self.indexedAssets.dictionaryRepresentation()
            } catch {
                cache = [:]
            }
            
            var cachedAssetIdsToInvalidate = [String]()
            let writeBatch = self.indexedAssets.writeBatch()
            
            for asset in assets {
                if let cacheHit = cache[asset.localIdentifier] as? KBPhotoAsset {
                    if let whenCached = cacheHit.cacheUpdatedAt,
                       whenCached.compare(asset.modificationDate ?? .distantPast) == .orderedAscending {
                        // Asset was modified since cached -> remove from the persistent cache
                        cachedAssetIdsToInvalidate.append(asset.localIdentifier)
                    }
                } else {
                    autoreleasepool {
                        let kvsAssetValue = KBPhotoAsset(for: asset, usingCachingImageManager: self.imageManager)
                        writeBatch.set(value: kvsAssetValue, for: asset.localIdentifier)
                    }
                }
            }
            
            do {
                try writeBatch.write()
                try self.indexedAssets.removeValues(for: cachedAssetIdsToInvalidate)
                completionHandler(.success(()))
            }
            catch {
                completionHandler(.failure(KBError.databaseNotReady))
            }
        }
    }
    
    
    // MARK: PHPhotoLibraryChangeObserver protocol
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let cameraRoll = self.cameraRollInMemoryCache else {
            log.warning("No assets were ever fetched. Ignoring change notification")
            return
        }
        
        self.ingestionQueue.async {
            let changeDetails = changeInstance.changeDetails(for: cameraRoll)
            if let changeDetails = changeDetails {
                self.cameraRollInMemoryCache = changeDetails.fetchResultAfterChanges
                let writeBatch = self.indexedAssets.writeBatch()
                for asset in changeDetails.insertedObjects {
                    writeBatch.set(value: KBPhotoAsset(for: asset), for: asset.localIdentifier)
                    for delegate in self.delegates.values {
                        delegate.wasAdded(asset: asset)
                    }
                }
                for asset in changeDetails.removedObjects {
                    for delegate in self.delegates.values {
                        delegate.wasRemoved(asset: asset)
                    }
                }
                
                if self.shouldIndexAssets {
                    do {
                        try writeBatch.write()
                        try self.indexedAssets.removeValues(for: changeDetails.removedObjects.map { $0.localIdentifier })
                    } catch {
                        log.error("Failed to update cache on library change notification: \(error.localizedDescription)")
                    }
                }
            } else {
                log.warning("No changes in camera roll")
            }
        }
    }
}

