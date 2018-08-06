//
//  dms.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/1/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

public enum DMSFormat{
    case degrees
    case degreesMinutes
    case degreesMinutesSeconds
}
public enum DMS {
    public static func castToDouble(_ data: String) -> Double {
        if let data = Double(data){
            return data
        } else{
            var mod = data
            var i = mod.count
            repeat{
                mod = String(mod[..<mod.index(mod.endIndex, offsetBy: -1)])
                i = mod.count
                if let newParse = Double(mod){
                    return newParse
                }
            } while i > 0
            return 0
        }
    }
    
    public static func parseDMS(degMinSec: String) -> Double {
        if let parsed = Double(degMinSec) {
            return parsed
        }
        var dms = degMinSec.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        var regex = try! NSRegularExpression(pattern: "^-")
        //    var range =  Range(0, in: dms.characters.count)
        var range = NSMakeRange(0, dms.count)
        dms = regex.stringByReplacingMatches(in: dms, options: [], range: range, withTemplate: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        regex = try! NSRegularExpression(pattern: "[NSEWnsew]$")
        range = NSMakeRange(0, dms.count)
        dms = regex.stringByReplacingMatches(in: dms, options: [], range: range, withTemplate: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        regex = try! NSRegularExpression(pattern: "[0-9.,]+")
        range = NSMakeRange(0, dms.count)
        let matches = regex.matches(in: dms, range: range)
        
        var results = zip(matches, matches.dropFirst().map { Optional.some($0) } + [nil]).map{ current, next -> String in
            let newRange = current.range(at: 0)
            let start = String.UTF16Index(encodedOffset: newRange.location)
            let end = next.map {$0.range(at: 0)}.map { String.UTF16Index(encodedOffset: $0.location)} ?? String.UTF16Index(encodedOffset: dms.utf16.count)
            return String(dms.utf16[start..<end])!
        }
        results = results.map {$0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)}
        //    results = results.map {
        //        if let _ = Double($0){
        //            return $0 }
        //        else{
        //            return String($0[..<$0.index($0.endIndex, offsetBy: -1)]) }
        //        }
        
        var deg: Double = 0
        
        switch results.count{
        case 3: //interpret this as d/m/s
            deg = castToDouble(results[0]) + castToDouble(results[1])/60 + castToDouble(results[2])/3600
        case 2: //interpret this as d/m
            deg = castToDouble(results[0]) + castToDouble(results[1])/60
        case 1: //interpret this as d
            deg = castToDouble(results[0])
        default:
            return 0
        }
        
        regex = try! NSRegularExpression(pattern: "^-|[WSws]$")
        range = NSMakeRange(0, degMinSec.count)
        if regex.numberOfMatches(in: degMinSec, options: [], range: range) > 0{
            deg = deg * -1
        }
        
        return deg
    }
    
    public static func toDMS(deg: Double, format: DMSFormat, decimalPlaces: UInt) -> String{
        let degrees: Double
        let dp = Int(decimalPlaces)
        let roundingNumber = Double(truncating: pow(10, dp) as NSNumber)
        degrees = deg < 0 ? deg * -1 : deg
        
        var d: Int = 0
        var m: Double = 0
        var s: Double = 0
        var dms: String
        
        switch format {
        case .degrees:
            dms = "\(String(format: "%.\(dp)f", degrees))°"
            dms = degrees < 100 ? degrees < 10 ? "00\(dms)" : "0\(dms)" : "\(dms)"
        case .degreesMinutes:
            d = Int(degrees.rounded(.towardZero))
            m = (degrees * 60).truncatingRemainder(dividingBy: 60)
            m = (round(roundingNumber * m))/roundingNumber
            if (m == 60) {
                d += 1
                m = 0
            }
            var minutes = String(format: "%.\(dp)f", m)
            minutes = m < 10 ? "0\(minutes)" : minutes
            dms = d < 100 ? d < 10 ? "00\(d)" : "0\(d)" : "\(d)"
            dms = "\(dms)° \(minutes)'"
        case .degreesMinutesSeconds:
            d = Int(degrees.rounded(.towardZero))
            m = ((degrees * 3600)/60).truncatingRemainder(dividingBy: 60)
            var min = Int(m)
            s = (degrees * 3600).truncatingRemainder(dividingBy: 60)
            s = (round(roundingNumber * s))/roundingNumber
            if (s == 60){
                s = 0
                min += 1
            }
            if (min == 60){
                min = 0
                d += 1
            }
            
            let minutes = min < 10 ? "0\(min)" : "\(min)"
            var seconds = String(format: "%.\(dp)f", s)
            seconds = s < 10 ? "0\(seconds)" : seconds
            dms = d < 100 ? d < 10 ? "00\(d)" : "0\(d)" : "\(d)"
            dms = "\(dms)° \(minutes)' \(seconds)\""
        }
        
        return dms
    }
    
    public static func toLat(deg : Double, format: DMSFormat, decimalPlaces: UInt) -> String{
        var lat = toDMS(deg: deg, format: format, decimalPlaces: decimalPlaces)
        lat = String(lat[lat.index(lat.startIndex, offsetBy: 1)..<lat.endIndex])
        return "\(deg < 0 ? "S" : "N") \(lat)"
    }
    
    public static func toLon(deg: Double, format: DMSFormat, decimalPlaces: UInt) -> String{
        let lon = toDMS(deg: deg, format: format, decimalPlaces: decimalPlaces)
        return "\(deg < 0 ? "W" : "E") \(lon)"
    }
    
    public static func toBrng(deg: Double, format: DMSFormat, decimalPlaces: UInt) -> String{
        let degrees = (deg + 360).truncatingRemainder(dividingBy: 360)
        var brng = toDMS(deg: degrees, format: format, decimalPlaces: decimalPlaces)
        brng = brng.replacingOccurrences(of: "360", with: "0")
        return brng
    }
    
    public static func compassPoint(bearing: Double, precision: UInt) -> String{
        let dp = Int(precision)
        let brng = (bearing.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        
        var cardinals = [
            "N", "NNE", "NE", "ENE",
            "E", "ESE", "SE", "SSE",
            "S", "SSW", "SW", "WSW",
            "W", "WNW", "NW", "NNW"
        ]
        let n = Double(truncating: 4 * (pow(2, dp-1)) as NSNumber);
        let idx = Int(round(brng * n/360).truncatingRemainder(dividingBy: n) * 16/n)
        return cardinals[idx]
    }
}
