import Foundation
import AWSDynamoDB

@objcMembers
class Awning :AWSDynamoDBObjectModel ,AWSDynamoDBModeling  {
    
    var awningId:String?
    
    var arduinoIP: String? = " "
    var angle: NSNumber? = 0
    var automation: String? = "On"
    var status: String? = "Connected"
    var timezone: String? = " "
    
    //should be ignored according to ignoreAttributes
    var internalName:String?
    var internalState:NSNumber?
    
    class func dynamoDBTableName() -> String {
        return "Awning"
    }
    
    class func hashKeyAttribute() -> String {
        return "arduinoId"
    }
    
    class func ignoreAttributes() -> [String] {
        return ["internalName", "internalState"]
    }
}
