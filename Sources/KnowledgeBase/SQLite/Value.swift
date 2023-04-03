//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

/// - Warning: `Binding` is a protocol that SQLite.swift uses internally to
///   directly map SQLite types to Swift types.
///
///   Do not conform custom types to the Binding protocol. See the `Value`
///   protocol, instead.
protocol Binding {}

protocol Number : Binding {}

protocol Value { // extensions cannot have inheritance clauses

    associatedtype ValueType = Self

    associatedtype Datatype : Binding

    static var declaredDatatype: String { get }

    static func fromDatatypeValue(_ datatypeValue: Datatype) -> ValueType

    var datatypeValue: Datatype { get }
}

extension Double : Number, Value {
    static let declaredDatatype = "REAL"

    static func fromDatatypeValue(_ datatypeValue: Double) -> Double {
        return datatypeValue
    }

    var datatypeValue: Double {
        return self
    }
}

extension Int64 : Number, Value {
    static let declaredDatatype = "INTEGER"

    static func fromDatatypeValue(_ datatypeValue: Int64) -> Int64 {
        return datatypeValue
    }

    var datatypeValue: Int64 {
        return self
    }
}

extension String : Binding, Value {
    static let declaredDatatype = "TEXT"

    static func fromDatatypeValue(_ datatypeValue: String) -> String {
        return datatypeValue
    }

    var datatypeValue: String {
        return self
    }
}

extension Blob : Binding, Value {
    static let declaredDatatype = "BLOB"

    static func fromDatatypeValue(_ datatypeValue: Blob) -> Blob {
        return datatypeValue
    }

    var datatypeValue: Blob {
        return self
    }
}

extension Bool : Binding, Value {
    static var declaredDatatype = Int64.declaredDatatype

    static func fromDatatypeValue(_ datatypeValue: Int64) -> Bool {
        return datatypeValue != 0
    }

    var datatypeValue: Int64 {
        return self ? 1 : 0
    }
}

extension Int : Number, Value {
    static var declaredDatatype = Int64.declaredDatatype

    static func fromDatatypeValue(_ datatypeValue: Int64) -> Int {
        return Int(datatypeValue)
    }

    var datatypeValue: Int64 {
        return Int64(self)
    }
}

extension Data : Value {
    static var declaredDatatype = Blob.declaredDatatype

    static func fromDatatypeValue(_ dataValue: Blob) -> Data {
        return Data(dataValue.bytes)
    }

    var datatypeValue: Blob {
        return withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Blob in
            return Blob(bytes: pointer.baseAddress!, length: count)
        }
    }
}

extension Date : Value {
    static var declaredDatatype = String.declaredDatatype

    static func fromDatatypeValue(_ stringValue: String) -> Date {
        return dateFormatter.date(from: stringValue)!
    }

    var datatypeValue: String {
        return dateFormatter.string(from: self)
    }
}

/// A global date formatter used to serialize and deserialize `NSDate` objects.
/// If multiple date formats are used in an application’s database(s), use a
/// custom `Value` type per additional format.
var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = KBDefaultDateFormat
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()
