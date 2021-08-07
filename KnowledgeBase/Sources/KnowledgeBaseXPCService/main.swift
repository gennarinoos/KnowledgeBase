//
//  main.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/29/21.
//

import Foundation
import os

let log = Logger(subsystem: "com.gf.knowledgebase", category: "XPC")

let listener = NSXPCListener.service()
let delegate = KBStorageServiceDelegate()
listener.delegate = delegate;
listener.resume()
RunLoop.main.run()
