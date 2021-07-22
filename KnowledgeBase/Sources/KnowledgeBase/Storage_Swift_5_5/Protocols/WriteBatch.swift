//
//  WriteBatch.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/18/21.
//

extension KBKVStoreWriteBatch {
    func write() async throws {
        throw KBError.notSupported
    }
}

extension KBSQLWriteBatch {
    func write() async throws {
        try await KBModernAsyncMethodReturningVoid(self.write(completionHandler:))
    }
}

extension KBUserDefaultsWriteBatch {
    func write() async throws {
        try await KBModernAsyncMethodReturningVoid(self.write(completionHandler:))
    }
}

extension KBCloudKitSQLWriteBatch {
    func write() async throws {
        try await KBModernAsyncMethodReturningVoid(self.write(completionHandler:))
    }
}
