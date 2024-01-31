import Foundation

@objc(KBPaginationOptions)
public class KBPaginationOptions : NSObject, NSSecureCoding {
    
    let page: Int /// The page number
    let per: Int  /// The items per page
    
    public init?(page: Int, per: Int) {
        if page >= 1 {
            self.page = page
            self.per = per
        } else {
            return nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case per
        case page
    }
    
    public static var supportsSecureCoding: Bool = true
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.page, forKey: CodingKeys.page.rawValue)
        aCoder.encode(self.per, forKey: CodingKeys.per.rawValue)
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        let page = aDecoder.decodeInteger(forKey: CodingKeys.page.rawValue)
        let per = aDecoder.decodeInteger(forKey: CodingKeys.per.rawValue)
        
        self.init(page: page, per: per)
    }
}

public enum KBSortDirection: String {
    case ascending = "asc", descending = "desc"
}
