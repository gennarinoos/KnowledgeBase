//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 8/10/21.
//

import Foundation
import Photos

let kKBPhotosAssetIdCacheStoreName = "com.gf.knowledgebase.PhotosAssetIdCache"
let kKBPhotosIndexStoreName = "com.gf.knowledgebase.PhotosIndexStore"
let kKBPhotosAuthorizationStatusKey = "com.gf.knowledgebase.indexer.photos.authorizationStatus"


public protocol KBPhotoAssetChangeDelegate {
    func wasAdded(asset: PHAsset)
    func wasRemoved(asset: PHAsset)
}

public class KBPhotosIndexer : NSObject, PHPhotoLibraryChangeObserver, KBPhotoAssetChangeDelegate {
    public var identifier: String {
        "\(self.hashValue)"
    }
    
    var delegates = [String: KBPhotoAssetChangeDelegate]()
    
    let photosIndexerDefaults = KBKVStore.userDefaultsStore()
    let assetIdsCache: KBKVStore // The local identifiers of the PHAssets that have already been indexed
    let photosKnowledgeGraph: KBKnowledgeStore
    public var shouldIndexPhotosInKnowledgeGraph = false
    
    private var cameraRollAssets: PHFetchResult<PHAsset>?
    
    var authorizationStatus: PHAuthorizationStatus = .notDetermined
    let serialQueue = DispatchQueue(label: "com.gf.knowledgebase.indexer.photos.serialQueue")
    
    public override init() {
        self.assetIdsCache = KBKVStore.store(withName: kKBPhotosAssetIdCacheStoreName)
        self.photosKnowledgeGraph = KBKnowledgeStore.store(withName: kKBPhotosIndexStoreName)
        super.init()
        // TODO: Maybe this can be handled better by overriding Hashable/Equatable? It also makes it unnecessarily complex
        self.delegates[String(describing: self)] = self
        self.requestAuthorization()
//        PHPhotoLibrary.shared().register(self)
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
    
    // TODO: Support parameter `since: Date`
    public func ingestCameraRoll(completionHandler: @escaping (Swift.Result<Void, Error>) -> ()) {
        self.serialQueue.async {
            let cachedAssetIds: [String]
            do { cachedAssetIds = try self.assetIdsCache.keys() }
            catch {
                cachedAssetIds = []
                log.warning("Unable to read from the cache in \(kKBPhotosAssetIdCacheStoreName): \(error.localizedDescription)")
            }
            
            // Get all the camera roll photos and videos
            let fetchResults = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
            fetchResults.enumerateObjects { collection, count, stop in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                
                var predicate = NSPredicate(format: "(mediaType = %d || mediaType = %d) && NOT (mediaSubtype & %d) != 0)", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue, PHAssetMediaSubtype.photoScreenshot.rawValue)
                if cachedAssetIds.count > 0 {
                    let skipCachedIdsPredicate = NSPredicate(format: "NOT (localIdentifier IN %@)", cachedAssetIds)
                    predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, skipCachedIdsPredicate])
                }
                fetchOptions.predicate = predicate
                
                self.cameraRollAssets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                completionHandler(.success(()))
            }
        }
    }
    
    public func wasAdded(asset: PHAsset) {
        do { try self.assetIdsCache.set(value: Date(), for: asset.localIdentifier) }
        catch {
            log.warning("Unable to add item to the cache in \(kKBPhotosAssetIdCacheStoreName): \(error.localizedDescription)")
        }
        
        
        if self.shouldIndexPhotosInKnowledgeGraph {
            let assetEntityId = KBHexastore.JOINER.combine(kKBEntityPhAssetPrefix, asset.localIdentifier)
            let assetEntity = self.photosKnowledgeGraph.entity(withIdentifier: assetEntityId)
            do {
                // link the asset to its approximate location in the graph
                if let location = asset.location {
                    let approxLat = floor(location.coordinate.latitude * 1000)
                    let approxLon = floor(location.coordinate.longitude * 1000)
                    
                    let approxLatLonEntity = self.photosKnowledgeGraph.entity(withIdentifier: "latlon:\(approxLat),\(approxLon)")
                    try assetEntity.link(to: approxLatLonEntity, withPredicate: KBGraphPredicate.approximateLatLon.rawValue)
                }
                
                // link the asset to its approximate date in the graph
                if let createdDate = asset.creationDate {
                    let components = createdDate.dateTimeComponents()
                    let dayEntity = self.photosKnowledgeGraph.entity(withIdentifier: "DTd:\(String(describing: components.day))")
                    try assetEntity.link(to: dayEntity, withPredicate: KBGraphPredicate.day.rawValue)
                    let monthEntity = self.photosKnowledgeGraph.entity(withIdentifier: "DTM:\(String(describing: components.month))")
                    try assetEntity.link(to: monthEntity, withPredicate: KBGraphPredicate.month.rawValue)
                    let yearEntity = self.photosKnowledgeGraph.entity(withIdentifier: "DTy:\(String(describing: components.year))")
                    try assetEntity.link(to: yearEntity, withPredicate: KBGraphPredicate.year.rawValue)
                }
                
                // TODO: People's faces in the photos?
            } catch {
                log.error("Unable to ingest asset into the graph: \(error.localizedDescription)")
            }
        }
    }
    
    public func wasRemoved(asset: PHAsset) {
        do { try self.assetIdsCache.removeValue(for: asset.localIdentifier) }
        catch {
            log.warning("Unable to remove item from the cache in \(kKBPhotosAssetIdCacheStoreName): \(error.localizedDescription)")
        }
        
        if self.shouldIndexPhotosInKnowledgeGraph {
            do {
                let assetEntityId = KBHexastore.JOINER.combine(kKBEntityPhAssetPrefix, asset.localIdentifier)
                let assetEntity = self.photosKnowledgeGraph.entity(withIdentifier: assetEntityId)
                try assetEntity.remove()
            } catch {
                log.error("Unable to ingest asset into the graph: \(error.localizedDescription)")
            }
        }
    }
    
    
    // MARK: PHPhotoLibraryChangeObserver protocol
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let cameraRoll = self.cameraRollAssets else {
            log.warning("No assets were ever fetched. Ignoring change notification")
            return
        }
        
        self.serialQueue.async {
            let changeDetails = changeInstance.changeDetails(for: cameraRoll)
            self.cameraRollAssets = (changeDetails?.fetchResultAfterChanges)!
            if let changeDetails = changeDetails {
                for asset in changeDetails.insertedObjects {
                    for delegate in self.delegates.values {
                        delegate.wasAdded(asset: asset)
                    }
                }
                for asset in changeDetails.removedObjects {
                    for delegate in self.delegates.values {
                        delegate.wasRemoved(asset: asset)
                    }
                }
            } else {
                log.warning("No changes in camera roll")
            }
        }
    }
}

