//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/28/21.
//

import Foundation

let KBDefaultDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

extension Date {
    func toString(_ format: String) -> String? {
        let formatter:DateFormatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
