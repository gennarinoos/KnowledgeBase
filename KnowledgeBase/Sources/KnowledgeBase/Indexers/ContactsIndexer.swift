//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/14/21.
//

import Foundation
import Contacts

internal extension CNContact {
    class func relevantPredicateLabels() -> [String] {
        return [KBCanonicalName.givenName,
                KBCanonicalName.familyName,
                KBCanonicalName.nickName,
                KBCanonicalName.organizationName]
    }

    class func relevantKeysToFetch() -> [String] {
        return [CNContactIdentifierKey,
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactNicknameKey,
                CNContactOrganizationNameKey]
    }
}


public protocol KBAddressBookChangesDelegate {
    func wasDeleted(contactIdentifier: String) async throws
    func wasUpdated(contactIdentifier: String, toContact contact: CNContact) async throws
}

public class KBAddressBookIndexer : KBKnowledgeStore, KBAddressBookChangesDelegate {
    
    lazy var cnStore: CNContactStore = {
        let store = CNContactStore()
        store.requestAccess(for: CNEntityType.contacts, completionHandler: {
            (granted, error) in
            if let e = error {
                log.error("\(e.localizedDescription, privacy: .public)")
            } else {
                log.info("access to CNContactStore entity type (CNEntityType = \(CNEntityType.contacts.rawValue, privacy: .public) has been granted")
            }
            
        })
        return store
    }()
    
    public func run() async throws {
        let allContacts = try self.cnStore.unifiedContacts(matching: NSPredicate(value: true), keysToFetch: [])
        for contact in allContacts {
            try await self.wasUpdated(contactIdentifier: contact.identifier, toContact: contact)
        }
    }

    public func wasDeleted(contactIdentifier: String) async throws {
        let contactId = self.entity(withIdentifier: contactIdentifier)
        try await contactId.remove()
    }

    public func wasUpdated(contactIdentifier: String, toContact contact: CNContact) async throws {
        // Invalidate previous connections
        // TODO: Should we be less agressisve, and invalidate/update only changed fields?
        try await self.wasDeleted(contactIdentifier: contactIdentifier)

        let contactId = self.entity(withIdentifier: contactIdentifier)

        // Link the relevant names associated to this contact
        try await contactId.link(to: self.entity(withIdentifier: contact.givenName),
                                 withPredicate: KBCanonicalName.givenName)
        try await contactId.link(to: self.entity(withIdentifier: contact.familyName),
                                 withPredicate: KBCanonicalName.familyName)
        try await contactId.link(to: self.entity(withIdentifier: contact.nickname),
                                 withPredicate: KBCanonicalName.nickName)
        try await contactId.link(to: self.entity(withIdentifier: contact.organizationName),
                                 withPredicate: KBCanonicalName.organizationName)
    }
}
