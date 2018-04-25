//
//  Constants.swift
//  SwedishSolar
//
//  Created by Gregory McHugh on 3/29/18.
//  Copyright © 2018 Swedish Solar. All rights reserved.
//

import AWSCore

let IoTPolicyName = "mqttbridge"
let IOT_ENDPOINT = "https://a117ok0422c79p.iot.us-east-1.amazonaws.com"
var iotDataConfiguration: AWSServiceConfiguration!

let AwsRegion = AWSRegionType.USEast1 // e.g. AWSRegionType.USEast1
let CognitoIdentityPoolId = "us-east-1:b4a7d1aa-f21e-4175-ad45-caf009663f91"

//let CertificateSigningRequestCommonName = "IoT Sample"
//let CertificateSigningRequestCountryName = "USA"
//let CertificateSigningRequestOrganizationName = "Swedish Solar"
//let CertificateSigningRequestOrganizationalUnitName = "App User"
//let PolicyName = "Swedish-Solar-IoT-policy"

var tableFirst = false
