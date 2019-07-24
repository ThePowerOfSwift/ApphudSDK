//
//  ApphudExtensions.swift
// Apphud
//
//  Created by ren6 on 26/06/2019.
//  Copyright © 2019 Softeam Inc. All rights reserved.
//

import Foundation
import StoreKit

internal func apphudLog(_ text : String) {
    if ApphudUtils.shared.isLoggingEnabled {
        print("[Apphud] \(text)")
    }
}

internal func currentDeviceParameters() -> [String : String]{
    
    let family : String
    if UIDevice.current.userInterfaceIdiom == .phone {
        family = "iPhone"
    } else {
        family = "iPad"
    }    
    let app_version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    
    let params : [String : String] = ["locale" : Locale.current.identifier, 
                                      "time_zone" : TimeZone.current.identifier,
                                      "device_type" : UIDevice.current.apphudModelName, 
                                      "device_family" : family, 
                                      "platform" : "iOS", 
                                      "app_version" : app_version, 
                                      "start_app_version" : app_version, 
                                      "sdk_version" : sdk_version, 
                                      "os_version" : UIDevice.current.systemVersion,
    ]
    return params
}

extension UIDevice {
    var apphudModelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}


internal func receiptDataString() -> String? {
    guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
        return nil
    }
    var receiptData: Data? = nil
    do {
        receiptData = try Data(contentsOf: appStoreReceiptURL)
    }
    catch {}
    
    let string = receiptData?.base64EncodedString()
    return string
}

extension SKProduct {
    
    func submittableParameters() -> [String : Any] {
        
        var params : [String : Any] = [
                        "product_id" : productIdentifier,
                        "price" : price.floatValue
        ]

        if let countryCode = priceLocale.regionCode {
            params["country_code"] = countryCode
        }
        if let currencyCode = priceLocale.currencyCode {
            params["currency_code"] = currencyCode
        }
        
        if #available(iOS 11.2, *) {
            if let introData = introParameters() {
                params.merge(introData, uniquingKeysWith: {$1})
            }
            if subscriptionPeriod != nil {
                let units_count = subscriptionPeriod!.numberOfUnits
                params["unit"] = unitStringFrom(periodUnit: subscriptionPeriod!.unit)
                params["units_count"] = units_count                
            }
        }
        
        return params
    }
    
    private func unitStringFrom(periodUnit : SKProduct.PeriodUnit) -> String {
        var unit = ""
        switch periodUnit {
        case .day:
            unit = "day"
        case .week:
            unit = "week"
        case .month:
            unit = "month"
        case .year:
            unit = "year"
        default:
            break
        }
        return unit
    }
    
    private func introParameters() -> [String : Any]? {
        
        if let intro = introductoryPrice {
            let intro_periods_count = intro.numberOfPeriods
            
            let intro_unit_count = intro.subscriptionPeriod.numberOfUnits
            
            var mode :String?
            switch intro.paymentMode {
            case .payUpFront:
                mode = "pay_up_front"
            case .payAsYouGo:
                mode = "pay_as_you_go"
            case .freeTrial:
                mode = "trial"
            default:
                break
            }
            
            let intro_unit = unitStringFrom(periodUnit: intro.subscriptionPeriod.unit)
            
            if let aMode = mode{
                return ["intro_unit" : intro_unit, "intro_units_count" : intro_unit_count, "intro_periods_count" : intro_periods_count, "intro_mode" : aMode, "intro_price" : intro.price.floatValue]                
            }
        }
        
        return nil
    }
}