import UIKit
import AWSCore
import AWSDynamoDB
import AWSMobileClient
import AWSIoT
import SwiftyJSON
import SVProgressHUD
import Moscapsule

//let CertificateSigningRequestCommonName = "IoT Sample"
//let CertificateSigningRequestCountryName = "USA"
//let CertificateSigningRequestOrganizationName = "Swedish Solar"
//let CertificateSigningRequestOrganizationalUnitName = "App User"
//let PolicyName = "Swedish-Solar-IoT-policy"

class ShadowViewController: UIViewController {
    
    var name = ""
    var awningId = ""
    var automationEnabled: Bool = true
    var currentAngle: Int!
    var setAngle: Int!
    weak var setupTimer: Timer?
    
    // indicates if "Disconnected" occurred from returning to main table view
    var backWasPressed : Bool!
    
    var iotDataManager: AWSIoTDataManager!
    var iotDataManagerName : String!
    var thingName : String!
    
    // create new MQTT Connection
    var mqttClient: MQTTClient? = nil
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var setAngleLabel: UILabel!
    @IBOutlet weak var setAngleTitleLabel: UILabel!
    @IBOutlet weak var currentAngleLabel: UILabel!
    @IBOutlet weak var currentAngleTitleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var automationLabel: UILabel!
    @IBOutlet weak var automationSwitch: UISwitch!
    
    
    @IBAction func renameButtonTapped(_ sender: UIButton!) {
        let alertController = UIAlertController(title: "Rename", message: "", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addTextField { (textField : UITextField!) in
            textField.placeholder = "Enter New Name"
            textField.text = self.name
        }
        let saveAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: { alert in
            if let textField = alertController.textFields![0] as UITextField? {
                self.nameLabel.text = textField.text
                
                let userAwning = User_has_Awning()
                userAwning?.identityId = AWSIdentityManager.default().identityId
                userAwning?.awningId = self.awningId
                userAwning?.name = textField.text
                
                let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
                
                SVProgressHUD.show(withStatus: "Changing name in database...")
                //        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                
                dynamoDBObjectMapper.save(userAwning!) .continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> AnyObject? in
                    if let error = task.error as NSError? {
                        print("Error: \(error)")
                        
                        SVProgressHUD.dismiss()
                        //                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        let alertController = UIAlertController(title: "Failed to change the data in the database.", message: error.description, preferredStyle: UIAlertControllerStyle.alert)
                        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        SVProgressHUD.dismiss()
                        //                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        let alertController = UIAlertController(title: "Succeeded", message: "Successfully changed the data in the database.", preferredStyle: UIAlertControllerStyle.alert)
                        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                    
                    return nil
                })
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {
            (action : UIAlertAction!) in })
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func setAngle(angle: Int) {
        //
        // Initialize the control JSON object
        //
        let controlJson = JSON(["state": [
            "desired": [
                "angle": angle
            ]
            ]])
        
        //
        // desired angle labels only visible if automation off
        // stepper unresponsive if automation on
        //
        if !automationEnabled {
            
            setAngle = angle
            setAngleLabel.text = "\(angle)°"
            
            //            //
            //            // desired angle labels invisible if same as current angle
            //            //
            //            if setAngle == currentAngle {
            //                setAngleLabel.textColor = UIColor.white
            //                setAngleTitleLabel.textColor = UIColor.white
            //            }
            
            self.iotDataManager.updateShadow( thingName, jsonString: controlJson.rawString()! )
            
            
            
            // publish and subscribe
            mqttClient?.publish(string: "{\"Op\": 2, \"Dist\": \(angle)}", topic: "localgateway_to_awsiot", qos: 0, retain: false)
            print("{\"Op\": 1, \"Dist\": \(angle)}")
        }  else {
            //
            // inform user to turn automation off
            //
            let alertController = UIAlertController(title: "Automation is on", message: "Turn off automation to manually close the awning", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func button5Pressed(_ sender: Any) {
        setAngle(angle: 5)
    }
    
    @IBAction func button10Pressed(_ sender: Any) {
        setAngle(angle: 10)
    }
    
    @IBAction func button15Pressed(_ sender: Any) {
        setAngle(angle: 15)
    }
    
    @IBAction func button20Pressed(_ sender: Any) {
        setAngle(angle: 20)
    }
    
    @IBAction func button24Pressed(_ sender: Any) {
        setAngle(angle: 24)
    }
    
    @IBAction func button25Pressed(_ sender: Any) {
        setAngle(angle: 25)
    }
    
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        //
        // Initialize the control JSON object
        //
        let controlJson = JSON(["state": [
            "desired": [
                "angle": 0
            ]
            ]])
        
        //
        // desired angle labels only visible if automation off
        // stepper unresponsive if automation on
        //
        if !automationEnabled {
            
            setAngle = 0
            setAngleLabel.text = "0°"
            
            //            //
            //            // desired angle labels invisible if same as current angle
            //            //
            //            if setAngle == currentAngle {
            //                setAngleLabel.textColor = UIColor.white
            //                setAngleTitleLabel.textColor = UIColor.white
            //            }
            
            self.iotDataManager.updateShadow( thingName, jsonString: controlJson.rawString()! )
            
            
            
            // publish and subscribe
            mqttClient?.publish(string: "{\"Op\": 2, \"Dist\": 0}", topic: "localgateway_to_awsiot", qos: 0, retain: false)
            print("{\"Op\": 2, \"Dist\": 0}")
        }  else {
            //
            // inform user to turn automation off
            //
            let alertController = UIAlertController(title: "Automation is on", message: "Turn off automation to manually close the awning", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func automationSwitchChanged(_ sender: UISwitch) {
        //
        // Initialize the control JSON object
        //
        let controlJson = JSON(["state": [
            "desired": [
                "automation": sender.isOn
            ],
            "reported": [
                "automation": sender.isOn
            ]
            ]])
        
        
        automationEnabled = sender.isOn
        self.iotDataManager.updateShadow( thingName, jsonString: controlJson.rawString()! )
        
        //
        // if automation on:
        // disallow user from interacting with stepper and automation switch
        // desired angle labels invisible
        //
        if automationEnabled {
            closeButton.backgroundColor = UIColor.lightGray
        } else {
            closeButton.backgroundColor = self.view.tintColor
        }
        
        mqttClient?.publish(string: "{\"Op\": 3}", topic: "localgateway_to_awsiot", qos: 0, retain: false)
        print("{\"Op\": 3}")
    }
    
    func updateControl(json: JSON) {
        if let automation = json["state"]["reported"]["automation"].bool,
            let current = json["state"]["reported"]["angle"].int,
            let set = json["state"]["desired"]["angle"].int {
            
            automationSwitch.isOn = automation
            automationEnabled = automation
            
            currentAngle = Int(current)
            currentAngleLabel.text = "\(currentAngle!)°"
            
            //
            // if automation on:
            // disallow user from interacting with stepper and automation switch
            // desired angle labels invisible
            //
            if automationEnabled {
                closeButton.backgroundColor = UIColor.lightGray
            } else {
                closeButton.backgroundColor = self.view.tintColor
            }
            
            setAngle = set
            setAngleLabel.text = "\(setAngle!)°"
        }
    }
    
    func thingShadowTimeoutCallback( _ thingName: String, json: JSON, payloadString: String ) {
    }
    func thingShadowDeltaCallback( _ thingName: String, json: JSON, payloadString: String ) {
        updateControl(json : json)
    }
    func thingShadowAcceptedCallback( _ thingName: String, json: JSON, payloadString: String ) {
        updateControl(json : json)
    }
    func thingShadowRejectedCallback( _ thingName: String, json: JSON, payloadString: String ) {
        print("operation rejected on: \(thingName)")
    }
    
    @objc func getThingState() {
        self.iotDataManager.getShadow(thingName)
        
        //
        // if automation on:
        // disallow user from interacting with stepper and automation switch
        // desired angle labels invisible
        //
        if automationEnabled {
            closeButton.backgroundColor = UIColor.lightGray
        } else {
            closeButton.backgroundColor = self.view.tintColor
        }
    }
    
    
    func deviceShadowCallback(name:String, operation:AWSIoTShadowOperationType, operationStatus:AWSIoTShadowOperationStatusType, clientToken:String, payload:Data){
        DispatchQueue.main.async {
            guard let json = try? JSON(data: (payload as NSData) as Data) else {
                print("Could not get JSON")
                
                return
            }
            let stringValue = NSString(data: payload, encoding: String.Encoding.utf8.rawValue)
            
            switch(operationStatus) {
            case .accepted:
                print("accepted on \(name)")
                self.thingShadowAcceptedCallback( name, json: json, payloadString: stringValue! as String)
            case .rejected:
                print("rejected on \(name)")
                self.thingShadowRejectedCallback( name, json: json, payloadString: stringValue! as String)
            case .delta:
                print("delta on \(name)")
                self.thingShadowDeltaCallback( name, json: json, payloadString: stringValue! as String)
            case .timeout:
                print("timeout on \(name)")
                self.thingShadowTimeoutCallback( name, json: json, payloadString: stringValue! as String)
                
            default:
                print("unknown operation status: \(operationStatus.rawValue)")
            }
        }
    }
    
    func mqttEventCallback( _ status: AWSIoTMQTTStatus )
    {
        DispatchQueue.main.async {
            print("connection status = \(status.rawValue)")
            switch(status)
            {
            case .connecting:
                print( "Connecting..." )
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                SVProgressHUD.show(withStatus: "Connecting...")
                
            case .connected:
                print( "Connected" )
                
                //
                // Register the device shadow once connected.
                //
                self.iotDataManager.register(withShadow: self.thingName, options:nil, eventCallback: self.deviceShadowCallback )
                
                //
                // every second after registering the device shadow, retrieve the current state.
                //
                Timer.scheduledTimer( timeInterval: 1, target: self, selector: #selector(ShadowViewController.getThingState), userInfo: nil, repeats: true )
                
                //
                // after initial device state received, enable interaction
                //
                SVProgressHUD.dismiss(withDelay: 0.5)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.closeButton.isUserInteractionEnabled = true
                self.automationSwitch.isUserInteractionEnabled = true
                
                self.currentAngleLabel.textColor = UIColor.black
                self.currentAngleTitleLabel.textColor = UIColor.black
                self.setAngleLabel.textColor = UIColor.black
                self.setAngleTitleLabel.textColor = UIColor.black
                self.nameLabel.textColor = UIColor.black
                self.automationLabel.textColor = UIColor.black
                
            case .disconnected:
                print( "Disconnected" )
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                SVProgressHUD.dismiss()
                
                // if "Disconnected" didn't occur from returning to main table view
                // present error
                if !self.backWasPressed {
                    let alertController = UIAlertController(title: "Error: Disconnected.", message: "A problem occurred attempting to connect.", preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .connectionRefused:
                print( "Connection Refused" )
                
            case .connectionError:
                print( "Connection Error" )
                
            case .protocolError:
                print( "Protocol Error" )
                
            default:
                print("unknown state: \(status.rawValue)")
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //        appDelegate.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DetailViewController")
        
        
        
        // set MQTT Client Configuration
        let mqttConfig = MQTTConfig(clientId: "cid", host: "34.192.243.16", port: 1883, keepAlive: 60)
        mqttConfig.onConnectCallback = { returnCode in
            NSLog("Return Code is \(returnCode.description)")
        }
        mqttConfig.onMessageCallback = { mqttMessage in
            NSLog("MQTT Message received: payload=\(mqttMessage.payloadString!)")
        }
        
        // create new MQTT Connection
        mqttClient = MQTT.newConnection(mqttConfig)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //        name = "ArduinoRev3"
        //        thingName = "ArduinoRev3"
        thingName = awningId
        //        thingName = "AwningArduino\(awningId)"
        nameLabel.text = name
        
        iotDataManagerName = "\(thingName)IoTDataManager"
        
        //
        // until state has loaded:
        // - disallow user from interacting with stepper and automation switch
        // - and make all labels light gray
        //
        closeButton.isUserInteractionEnabled = false
        closeButton.backgroundColor = UIColor.lightGray
        automationSwitch.isUserInteractionEnabled = false
        
        nameLabel.textColor = UIColor.lightGray
        currentAngleLabel.textColor = UIColor.lightGray
        currentAngleTitleLabel.textColor = UIColor.lightGray
        setAngleLabel.textColor = UIColor.lightGray
        setAngleTitleLabel.textColor = UIColor.lightGray
        automationLabel.textColor = UIColor.lightGray
        
        automationSwitch.isOn = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        SVProgressHUD.show(withStatus: "Establishing a connection...")
        
        //
        // Init IOT
        //
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: iotDataManagerName)
        iotDataManager = AWSIoTDataManager(forKey: iotDataManagerName)
        
        
        //
        // Connect via WebSocket
        //
        self.iotDataManager.connectUsingWebSocket(withClientId: UUID().uuidString, cleanSession:true, statusCallback: mqttEventCallback)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // disconnection is from switching views, so no error returned
        backWasPressed = true
        
        iotDataManager.unregister(fromShadow: thingName)
        iotDataManager.disconnect()
        
        mqttClient?.disconnect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
