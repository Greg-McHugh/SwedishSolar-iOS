//
//  TestViewController.swift
//  Swedish Solar
//
//  Created by Gregory McHugh on 4/11/18.
//  Copyright © 2018 Swedish Solar. All rights reserved.
//

import UIKit
import Moscapsule


class TestViewController: UIViewController {

    // create new MQTT Connection
    var mqttClient: MQTTClient? = nil
    
    @IBAction func awsiot_to_localgatewayButtonPressed(_ sender: Any) {
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
        
        // publish and subscribe
        mqttClient?.publish(string: "{\"Op\": 1}", topic: "awsiot_to_localgateway", qos: 0, retain: false)
        //        mqttClient?.subscribe("localgateway_to_awsiot", qos: 0)
        
        
    }
    
    @IBAction func localgateway_to_awsiotButtonPressed(_ sender: Any) {
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
        
        // publish and subscribe
        mqttClient?.publish(string: "{\"Op\": 1}", topic: "localgateway_to_awsiot", qos: 0, retain: false)
        //        mqttClient?.subscribe("localgateway_to_awsiot", qos: 0)
        
        
    }
    
    func setAngle(angle: Int) {
        // publish and subscribe
            mqttClient?.publish(string: "{\"Op\": 1, \"Dist\": \(angle)}", topic: "localgateway_to_awsiot", qos: 0, retain: false)
            print("{\"Op\": 1, \"Dist\": \(angle)}")
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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func viewWillDisappear(_ animated: Bool) {
        // disconnect
        mqttClient?.disconnect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
