import UIKit
import AWSMobileClient
import AWSDynamoDB
import SVProgressHUD

class AddViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var arduinoMacTextField: UITextField!
    
    var userAwning:User_has_Awning?
    
    var dataChanged = false
    
    var identityId : String!
//    let identityId = "user identity"
    
    
    func insertTableRow(_ userAwning: User_has_Awning) {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        SVProgressHUD.show(withStatus: "Adding new Awning...")
//        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        dynamoDBObjectMapper.save(userAwning) .continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> AnyObject? in
            if let error = task.error as NSError? {
                print("Error: \(error)")
                
                SVProgressHUD.dismiss()
//                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                let alertController = UIAlertController(title: "Failed to insert the data into the table.", message: error.description, preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                SVProgressHUD.dismiss()
//                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                let alertController = UIAlertController(title: "Succeeded", message: "Successfully inserted the data into the table.", preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                
                self.nameTextField.text = nil
                self.arduinoMacTextField.text = nil
                
                self.dataChanged = true
            }
            
            return nil
        })
    }
    
    @IBAction func submit(_ sender: UIBarButtonItem) {
        
        if self.nameTextField.text!.utf16.count == 0 {
            let alertController = UIAlertController(title: "Error: Invalid Input", message: "Name Value cannot be empty.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        } else if self.arduinoMacTextField.text!.utf16.count == 0 {
            let alertController = UIAlertController(title: "Error: Invalid Input", message: "MAC Address Value cannot be empty.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        } else {
            let userAwning = User_has_Awning()
            userAwning?.identityId = identityId
            userAwning?.awningId = self.arduinoMacTextField.text
            userAwning?.name = self.nameTextField.text
            
            // CHECKS IF GIVEN awningId IS ALREADY IN Awning TABLE
            // ADD User_has_Awning ROW IF TRUE
            // RETURN ERROR MESSAGE IF FALSE
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
            dynamoDBObjectMapper.load(Awning.self, hashKey: (userAwning?.awningId)!, rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                if let error = task.error as NSError? {
                    print("The request failed. Error: \(error)")
                    let alertController = UIAlertController(title: "Error: Invalid Input", message: "That Awning does not exist", preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    self.insertTableRow(userAwning!)
                }
                return nil
            })
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        identityId = AWSIdentityManager.default().identityId
        
        self.nameTextField.isEnabled = true
        self.arduinoMacTextField.isEnabled = true

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (self.dataChanged) {
            let c = self.navigationController?.viewControllers.count
            let mainTableViewController = self.navigationController?.viewControllers [c! - 1] as! MainTableViewController
            mainTableViewController.needsToRefresh = true
        }
    }
    
}

