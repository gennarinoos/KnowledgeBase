//
//  main.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/29/21.
//

import Foundation
import KnowledgeBase

import os

let log = Logger(subsystem: "com.gf.knowledgebase", category: KnowledgeBaseXPCServiceBundleIdentifier)

let listener = NSXPCListener(machServiceName: KnowledgeBaseXPCServiceBundleIdentifier)
let delegate = KBStorageServiceDelegate()
listener.delegate = delegate
listener.resume()

let photoUploaderDelegate = EncryptedPhotoUploaderDelegate()
let photosIndexer = KBPhotosIndexer()
photosIndexer.shouldIndexAssets = false
photosIndexer.addDelegate(photoUploaderDelegate)
let sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
photosIndexer.updateCameraRollCache { _ in }

RunLoop.main.run()
