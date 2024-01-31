import Foundation

@objc(KBPaginationOptions)
public class KBPaginationOptions : NSObject, NSSecureCoding {
    
    let limit: Int
    let offset: Int
    
    public init?(limit: Int, offset: Int) {
        if limit > 0, offset >= 0 {
            self.limit = limit
            self.offset = offset
        } else {
            return nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case limit
        case offset
    }
    
    public static var supportsSecureCoding: Bool = true
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.limit, forKey: CodingKeys.limit.rawValue)
        aCoder.encode(self.offset, forKey: CodingKeys.offset.rawValue)
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        let limit = aDecoder.decodeInteger(forKey: CodingKeys.limit.rawValue)
        let offset = aDecoder.decodeInteger(forKey: CodingKeys.offset.rawValue)
        
        self.init(limit: limit, offset: offset)
    }
}

public enum KBSortDirection: String {
    case ascending = "asc", descending = "desc"
}
