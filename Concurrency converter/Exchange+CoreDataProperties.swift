import Foundation
import CoreData

extension Exchange {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exchange> {
        return NSFetchRequest<Exchange>(entityName: "Exchange")
    }
    @NSManaged public var from: String
    @NSManaged public var to: String
    @NSManaged public var quantity: Double
    @NSManaged public var rate: Double
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isHistory: Bool

    
    func text() -> String {
        return "\(round(quantity*10000)/10000) \(from) = \(round(rate*quantity*10000)/10000) \(to)"
    }
}
