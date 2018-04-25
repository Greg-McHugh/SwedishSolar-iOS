import UIKit
import AWSCore
import AWSDynamoDB
import AWSAuthUI
import AWSMobileClient
import AWSIoT
import SVProgressHUD
import AWSLambda

class MainTableViewController: UITableViewController {
    
    var tableRows:Array<TableRow>?
    var lock:NSLock?
    var lastEvaluatedKey:[String : AWSDynamoDBAttributeValue]!
    var doneLoading = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let credentialsProvider = AWSMobileClient.sharedInstance().getCredentialsProvider()
    var identityId : String?
    var needsToRefresh = false
    
    
//    @IBAction func unwindToMainTableViewControllerFromSearchViewController(_ unwindSegue:UIStoryboardSegue) {
//        let searchVC = unwindSegue.source as! DDBSearchViewController
//        self.tableRows?.removeAll(keepingCapacity: true)
//
//        if searchVC.pagniatedOutput != nil{
//            for item in searchVC.pagniatedOutput!.items as! [User_has_Awning] {
//                self.tableRows?.append(item)
//            }
//        }
//
//        self.doneLoading = true
//
//        DispatchQueue.main.async {
//            self.tableView.reloadData()
//        }
//    }
    
    func getTable(_ startFromBeginning: Bool)  {
        if (self.lock?.try() != nil) {
            if startFromBeginning {
                self.lastEvaluatedKey = nil
                self.doneLoading = false
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            SVProgressHUD.show(withStatus: "Retrieving your awnings...")
            
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
            let scanExpression = AWSDynamoDBScanExpression()
            scanExpression.exclusiveStartKey = self.lastEvaluatedKey
//            scanExpression.limit = 20
            scanExpression.filterExpression = "identityId = :id"
            scanExpression.expressionAttributeValues = [":id": identityId!]
            dynamoDBObjectMapper.scan(User_has_Awning.self, expression: scanExpression).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> AnyObject? in
                
                if self.lastEvaluatedKey == nil {
                    self.tableRows?.removeAll(keepingCapacity: true)
                }
                
                if let paginatedOutput = task.result {
                    for item in paginatedOutput.items as! [User_has_Awning] {
                        let row = TableRow()
                        row.userAwning = item
                        row.awning = Awning()
                        
                        self.tableRows?.append(row)
                    }
                    
                    self.lastEvaluatedKey = paginatedOutput.lastEvaluatedKey
                    if paginatedOutput.lastEvaluatedKey == nil {
                        self.doneLoading = true
                    }
                }
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.tableView.reloadData()
                SVProgressHUD.dismiss()
                
                if let error = task.error as NSError? {
                    print("Error: \(error)")
                }
                
                return nil
            })
        }
    }
    
    func deleteTableRow(_ row: TableRow) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.remove(row.userAwning!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> AnyObject? in

            UIApplication.shared.isNetworkActivityIndicatorVisible = false

            if let error = task.error as NSError? {
                print("Error: \(error)")

                let alertController = UIAlertController(title: "Failed to delete a row.", message: error.description, preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }

            return nil
        })

    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
//        self.performSegue(withIdentifier: "SeguePushAddViewController", sender: (Any).self)
        
        
        var userAwning = User_has_Awning()
        presentAddAwningID(userAwning: userAwning, backPressed: false)
    }
    
    func presentAddAwningID(userAwning : User_has_Awning?, backPressed : Bool) {
        let alertController = UIAlertController(title: "Add a New Awning", message: "What's awning's ID number?", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Awning ID"
            
            if backPressed {
                textField.text = userAwning?.awningId
            }
        }
        
        let nextAction = UIAlertAction(title: "Next", style: .default, handler: {(action: UIAlertAction!) in
            if let textField = alertController.textFields![0] as UITextField? {
                userAwning?.awningId = textField.text
                self.presentAddAwningName(userAwning: userAwning, backPressed: backPressed)
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(nextAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentAddAwningName(userAwning : User_has_Awning?, backPressed : Bool) {
        let alertController = UIAlertController(title: "Add a Name", message: "What would you like to name your new awning?", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Give a name"
            
            if backPressed {
                textField.text = userAwning?.name
            }
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default, handler: {(action: UIAlertAction!) in
            if let textField = alertController.textFields![0] as UITextField? {
                userAwning?.name = textField.text
                self.addNewAwning(userAwning: userAwning)
            }
        })
        let backAction = UIAlertAction(title: "Back", style: .cancel, handler: {(action: UIAlertAction!) in
            self.presentAddAwningID(userAwning: userAwning, backPressed: true)
        })
        
        alertController.addAction(addAction)
        alertController.addAction(backAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func addNewAwning(userAwning : User_has_Awning?) {
        userAwning?.identityId = AWSIdentityManager.default().identityId
        
        SVProgressHUD.show(withStatus: "Adding new Awning...")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.save(userAwning!) .continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> AnyObject? in
            if let error = task.error as NSError? {
                print("Error: \(error)")
                
                SVProgressHUD.dismiss()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                let alertController = UIAlertController(title: "Failed to add your new awning.", message: error.description, preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                SVProgressHUD.dismiss()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                let alertController = UIAlertController(title: "Succeeded", message: "Successfully added your new awning.", preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                
                self.getTable(false)
            }
            
            return nil
        })
    }

    @IBOutlet weak var deleteButton: UIBarButtonItem!

    @IBAction func deleteButtonPressed(_ sender: Any) {
        if self.tableView.isEditing {
            self.tableView.isEditing = false
            deleteButton.tintColor = navigationController!.navigationBar.tintColor
        } else {
            self.tableView.isEditing = true
            deleteButton.tintColor = UIColor.red
        }
    }

    @IBAction func refreshButtonPressed(_ sender: Any) {
        self.getTable(true)
    }

    @IBAction func signoutButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Do you want to signout?", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            self.signout()
            self.signin() // make user signin again (possibly with different account)
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func attachPrincipalPolicy() {
        let iotService = AWSIoT.default()
        let attachPrinciplePolicyToID = AWSIoTAttachPrincipalPolicyRequest()
        attachPrinciplePolicyToID?.policyName = IoTPolicyName
        attachPrinciplePolicyToID?.principal = self.identityId
        iotService.attachPrincipalPolicy(attachPrinciplePolicyToID!)
        
//        let lambdaInvoker = AWSLambdaInvoker.default()
//        let jsonObject: [String: Any] = ["policyName" : IoTPolicyName,
//                                         "principal" : identityId!]
//
//        lambdaInvoker.invokeFunction("attachPrincipalPolicy", jsonObject: jsonObject)
//            .continueWith(block: {(task:AWSTask<AnyObject>) -> Any? in
//                if( task.error != nil) {
//                    print("Error: \(task.error!)")
//                } else if let result = task.result {
//                    print(result)
//                    // Handle response in task.result
//                }
//                return nil
//            })
    }
    
    func signin() {
        let config = AWSAuthUIConfiguration()
        config.enableUserPoolsUI = true
        config.canCancel = false
        config.logoImage = UIImage(named: "Swedish Solar flag")
        
        AWSAuthUIViewController
            .presentViewController(with: self.navigationController!,
                                   configuration: config,
                                   completionHandler: { (provider: AWSSignInProvider, error: Error?) in
                                    if error != nil {
                                        print("Error occurred: \(String(describing: error))")
                                    } else {
                                        self.identityId = AWSIdentityManager.default().identityId
                                        print("Login successful for \(self.identityId!)")
                                        self.initializeServiceConfiguration()
                                        self.attachPrincipalPolicy()
                                        self.getTable(true)
                                    }
            })
    }
    
    func signout() {
        if (AWSSignInManager.sharedInstance().isLoggedIn) {
            AWSSignInManager.sharedInstance().logout(completionHandler: {(result: Any?, error: Error?) in
//                self.navigationController!.popToRootViewController(animated: false)
            })
             print("Logout Successful");
        } else {
            assert(false)
        }
    }
    
    func initializeServiceConfiguration() {
        let credentialsProvider = AWSMobileClient.sharedInstance().getCredentialsProvider()
        let iotEndPoint = AWSEndpoint(urlString: IOT_ENDPOINT)
        iotDataConfiguration = AWSServiceConfiguration(
            region: AwsRegion,
            endpoint: iotEndPoint,
            credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = iotDataConfiguration
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableRows = []
        lock = NSLock()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Instantiate sign-in UI from the SDK library
        if AWSSignInManager.sharedInstance().isLoggedIn {
            identityId = AWSIdentityManager.default().identityId
            initializeServiceConfiguration()
            getTable(true)
        } else {
            signin()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if let rowCount = self.tableRows?.count {
            return rowCount
        } else {
            return 0
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Configure the cell...
        if let myTableRows = self.tableRows {
            let item = myTableRows[indexPath.row]
            cell.textLabel?.text = item.userAwning?.name!
            
//            if let myDetailTextLabel = cell.detailTextLabel {
//                myDetailTextLabel.text = item.userAwning?.awningId!
//            }
            
            if indexPath.row == myTableRows.count - 1 && !self.doneLoading {
                self.getTable(false)
            }
        }
        
        return cell
    }
    
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if self.tableView.isEditing {
            // Delete the row from the data source
            if var myTableRows = self.tableRows {
                let item = myTableRows[indexPath.row]
                self.deleteTableRow(item)
                myTableRows.remove(at: indexPath.row)
                self.tableRows = myTableRows
                
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        // push to detail view controller when cell selected
//        self.performSegue(withIdentifier: "SeguePushDetailViewController", sender: tableView.cellForRow(at: indexPath)) // necessary if segue is form view instead of cell
//    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if segue.identifier == "SeguePushDetailViewController" {
            let detailViewController = segue.destination as! MoscapsuleViewController
            let cell = sender as! UITableViewCell
            let indexPath = self.tableView.indexPath(for: cell)
            let tableRow = self.tableRows?[indexPath!.row]
            detailViewController.name = (tableRow?.userAwning?.name)!
            detailViewController.awningId = (tableRow?.userAwning?.awningId)!
            detailViewController.backWasPressed = false
        }
//        else if segue.identifier == "SegueAddViewController" {
//            let detailViewController = segue.destination as! DDBAddViewController
//            if sender != nil {
//                if sender is UIAlertController {
//                    detailViewController.viewType = .insert
//                } else if sender is UITableViewCell {
//                    let cell = sender as! UITableViewCell
//                    detailViewController.viewType = .update
//
//                    let indexPath = self.tableView.indexPath(for: cell)
//                    let tableRow = self.tableRows?[indexPath!.row]
//                    detailViewController.tableRow = tableRow
//                }
//            }
//        }
    }
    
//    func allowMultipleLines(tableViewCell: UITableViewCell) {
//        tableViewCell.textLabel?.numberOfLines = 0
//        tableViewCell.textLabel?.lineBreakMode = .byWordWrapping
//    }
//
//    cell.textLabel.numberOfLines = 0
//    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap
//    
//    tableView.rowHeight = UITableViewAutomaticDimension

}
