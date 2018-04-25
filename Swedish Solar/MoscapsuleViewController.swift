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

class MoscapsuleViewController: UIViewController {
    
    var name = ""
    var awningId = ""
    var automationEnabled: Bool = false
    var currentAngle: Int!
    var setAngle: Int!
    weak var setupTimer: Timer?
    
    // indicates if "Disconnected" occurred from returning to main table view
    var backWasPressed : Bool!
    
    var topic : String!
    var thingName : String!
    
    // create new MQTT Connection
    var mqttClient: MQTTClient? = nil
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var setAngleLabel: UILabel!
    @IBOutlet weak var setAngleTitleLabel: UILabel!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var angle25button: UIButton!
    @IBOutlet weak var angle30button: UIButton!
    @IBOutlet weak var angle35button: UIButton!
    @IBOutlet weak var angle40button: UIButton!
    @IBOutlet weak var angle45button: UIButton!
    @IBOutlet weak var maxButton: UIButton!
    
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
    
    
    func setAngle(sentAngle: Int, displayAngle: Int) {
        if !automationEnabled {
            
            setAngle = displayAngle
            setAngleLabel.text = "\(displayAngle)°"
            
            
            // publish
            mqttClient?.publish(string: "{\"Op\": 1, \"Angle\": \(sentAngle)}", topic: topic, qos: 0, retain: false)
            print("{\"Op\": 1, \"Angle\": \(sentAngle)}")
        }  else {
            //
            // inform user to turn automation off
            //
            let alertController = UIAlertController(title: "Automation is on", message: "Turn off automation to manually adjust the awning's angle", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func angle25buttonPressed(_ sender: Any) {
        setAngle(sentAngle: 25, displayAngle: 20)
    }
    
    @IBAction func angle30buttonPressed(_ sender: Any) {
        setAngle(sentAngle: 30, displayAngle: 28)
    }
    
    @IBAction func angle35buttonPressed(_ sender: Any) {
        setAngle(sentAngle: 35, displayAngle: 36)
    }
    
    @IBAction func angle40buttonPressed(_ sender: Any) {
        setAngle(sentAngle: 40, displayAngle: 42)
    }
    
    @IBAction func angle45buttonPressed(_ sender: Any) {
        setAngle(sentAngle: 45, displayAngle: 50)
    }
    
    @IBAction func maxButtonPressed(_ sender: Any) {
        setAngle(sentAngle: 50, displayAngle: 60)
    }
    
    @IBAction func closedButtonPressed(_ sender: UIButton) {
        if !automationEnabled {
            
            setAngle = 0
            setAngleLabel.text = "0°"
            
            // publish
            mqttClient?.publish(string: "{\"Op\": 2, \"Angle\": 0}", topic: topic, qos: 0, retain: false)
            print("{\"Op\": 2, \"Angle\": 0}")
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
        automationEnabled = automationSwitch.isOn
        
        //
        // if automation on:
        // disallow user from interacting with stepper and automation switch
        // desired angle labels invisible
        //
        if automationEnabled {
            closeButton.backgroundColor = UIColor.lightGray
            angle25button.backgroundColor = UIColor.lightGray
            angle30button.backgroundColor = UIColor.lightGray
            angle35button.backgroundColor = UIColor.lightGray
            angle40button.backgroundColor = UIColor.lightGray
            angle45button.backgroundColor = UIColor.lightGray
            maxButton.backgroundColor = UIColor.lightGray
            
            setAngleLabel.textColor = UIColor.lightGray
            setAngleTitleLabel.textColor = UIColor.lightGray

        } else {
            self.closeButton.backgroundColor = self.view.tintColor
            self.angle25button.backgroundColor = self.view.tintColor
            self.angle30button.backgroundColor = self.view.tintColor
            self.angle35button.backgroundColor = self.view.tintColor
            self.angle40button.backgroundColor = self.view.tintColor
            self.angle45button.backgroundColor = self.view.tintColor
            self.maxButton.backgroundColor = self.view.tintColor
            
            self.setAngleLabel.textColor = UIColor.black
            self.setAngleTitleLabel.textColor = UIColor.black
        }
        
        mqttClient?.publish(string: "{\"Op\": 3}", topic: topic, qos: 0, retain: false)
        print("{\"Op\": 3}")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
//        moscapsule_init()
        
        topic = awningId == "ArduinoRev3" ? "localgateway_to_awsiot" : "iPhone_to_Arduino_\(awningId)"
        
        // set MQTT Client Configuration
        let mqttConfig = MQTTConfig(clientId: "cid", host: "34.192.243.16", port: 1883, keepAlive: 60)
        
        mqttConfig.onConnectCallback = { returnCode in
            NSLog("Return Code is \(returnCode.description)")
        }
        
        mqttConfig.onMessageCallback = { mqttMessage in
            let jsonString = mqttMessage.payloadString!
            NSLog("MQTT Message received: payload=\(jsonString)")
            print(jsonString)
            let json = JSON.init(jsonString)
            if json["Op"].int == 6 {
                self.automationEnabled = json["optimizationState"].string == "On" ? true : false
                self.automationSwitch.isOn = self.automationEnabled
                self.currentAngle = self.interpretCurrentPos(reported: json["currentPos"].int!)
                self.setAngleLabel.text = "\(self.currentAngle)"
            }
            
            
            
//            self.enableInteraction()
            SVProgressHUD.dismiss()
        }
        
        // create new MQTT Connection
        mqttClient = MQTT.newConnection(mqttConfig)
        
        mqttClient?.subscribe("localgateway_to_awsiot", qos: 0)
    }
    
    func interpretCurrentPos(reported: Int) -> Int {
        switch(reported) {
        case 0:
            return 0
        case 25:
            return 20
        case 30:
            return 28
        case 35:
            return 36
        case 40:
            return 42
        case 45:
            return 50
        case 50:
            return 60
        default:
            return -1
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //        name = "ArduinoRev3"
        //        thingName = "ArduinoRev3"
        thingName = awningId
        //        thingName = "AwningArduino\(awningId)"
        nameLabel.text = name
        
        automationSwitch.isOn = false
        
//        //
//        // until state has loaded:
//        // - disallow user from interacting with stepper and automation switch
//        // - and make all labels light gray
//        //
//        closeButton.backgroundColor = UIColor.lightGray
//        angle25button.backgroundColor = UIColor.lightGray
//        angle30button.backgroundColor = UIColor.lightGray
//        angle35button.backgroundColor = UIColor.lightGray
//        angle40button.backgroundColor = UIColor.lightGray
//        angle45button.backgroundColor = UIColor.lightGray
//        maxButton.backgroundColor = UIColor.lightGray
//
//        nameLabel.textColor = UIColor.lightGray
//        currentAngleLabel.textColor = UIColor.lightGray
//        currentAngleTitleLabel.textColor = UIColor.lightGray
//        setAngleLabel.textColor = UIColor.lightGray
//        setAngleTitleLabel.textColor = UIColor.lightGray
//        automationLabel.textColor = UIColor.lightGray
//
//        automationSwitch.isUserInteractionEnabled = false

        // indicate a connection is attempting to be established
        SVProgressHUD.show(withStatus: "Establishing a connection...")
        SVProgressHUD.dismiss(withDelay: 5)
//        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(MoscapsuleViewController.enableInteraction), userInfo: nil, repeats: false)
    }
    
//    @objc func enableInteraction() {
//        self.closeButton.backgroundColor = self.view.tintColor
//        self.angle25button.backgroundColor = self.view.tintColor
//        self.angle30button.backgroundColor = self.view.tintColor
//        self.angle35button.backgroundColor = self.view.tintColor
//        self.angle40button.backgroundColor = self.view.tintColor
//        self.angle45button.backgroundColor = self.view.tintColor
//        self.maxButton.backgroundColor = self.view.tintColor
//
//        self.nameLabel.textColor = UIColor.black
//        self.currentAngleLabel.textColor = UIColor.black
//        self.currentAngleTitleLabel.textColor = UIColor.black
//        self.setAngleLabel.textColor = UIColor.black
//        self.setAngleTitleLabel.textColor = UIColor.black
//        self.automationLabel.textColor = UIColor.black
//
//        self.automationSwitch.isUserInteractionEnabled = true
//
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // disconnection is from switching views, so no error returned
        backWasPressed = true
        
        mqttClient?.disconnect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
