import Foundation
import AWSDynamoDB

@objcMembers
class User_has_Awning :AWSDynamoDBObjectModel ,AWSDynamoDBModeling  {
    
    var identityId:String?
    var awningId:String?
    
    var name:String? = ""
    
    //should be ignored according to ignoreAttributes
    var internalName:String?
    var internalState:NSNumber?
    
    class func dynamoDBTableName() -> String {
        return "User_has_Awning"
    }
    
    class func hashKeyAttribute() -> String {
        return "identityId"
    }
    
    class func rangeKeyAttribute() -> String {
        return "awningId"
    }
    
    class func ignoreAttributes() -> [String] {
        return ["internalName", "internalState"]
    }
}
