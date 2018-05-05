//
//  latlon-ellipsoidal.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/1/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

enum LatLonError: Error{
    case parseError(String)
}

struct LatLon : CustomStringConvertible {
    
    var description: String {
        return self.toString(format: .degreesMinutesSeconds, decimalPlaces: 4)
    }
    var lat: Double
    var lon: Double
    var datum: Datum
    private let wgs84Datum : Datum
    private let datumStore: [Datum]
    
    init(lat: Double, lon: Double, datum: Datum) {
        datumStore = Datums().datums
        self.lat = lat
        self.lon = lon
        self.wgs84Datum = datumStore.filter { $0.name == Datums.wgs84 }.first!
        self.datum = datumStore.filter { $0.name == Datums.wgs84 }.first!
        self.datum = getDatum(targetDatum: datum)
    }
    
    init(lat: Double, lon: Double){
        datumStore = Datums().datums
        self.lat = lat
        self.lon = lon
        self.wgs84Datum = datumStore.filter { $0.name == Datums.wgs84 }.first!
        self.datum = datumStore.filter { $0.name == Datums.wgs84 }.first!
        self.datum = getDatum(targetDatum: datum)
    }
    
    func toString(format: DMSFormat, decimalPlaces: UInt, newLinesForEachCoord: Bool) -> String{
        
        
        return "\(DMS.toLat(deg: self.lat, format: format, decimalPlaces: decimalPlaces)), \(newLinesForEachCoord ? "\n" : "")\(DMS.toLon(deg: self.lon, format: format, decimalPlaces: decimalPlaces))"
    }
    
    func toString(format: DMSFormat, decimalPlaces: UInt) -> String {
        return self.toString(format: format, decimalPlaces: decimalPlaces, newLinesForEachCoord: false)
    }
    
    private func getDatum(targetDatum: Datum) -> Datum{
        if datumStore.contains(targetDatum) {
            return targetDatum
        } else {
            return datumStore.filter { $0.name == Datums.wgs84 }.first!
        }
    }
    
    mutating func convertDatum(toDatum: Datum) -> LatLon{
        let target = getDatum(targetDatum: toDatum)
        var transform: Transform? = nil
        
        if self.datum == wgs84Datum {
            transform = target.transform
        }
        
        if (target == wgs84Datum) {
            let temp = self.datum.transform
            transform = Transform(tx: -1 * temp.tx, ty: -1 * temp.ty, tz: -1 * temp.tz, s: -1 * temp.s, rx: -1 * temp.rx, ry: -1 * temp.ry, rz: -1 * temp.rz)
        }
        
        if (transform == nil){
            //neither this nor the target datum are WGS84; convert to WGS84 first
            self = convertDatum(toDatum: wgs84Datum)
            transform = target.transform
        }
        
        let oldCartesian = self.toCartesian()
        let newCartesian =  applyTransform(point: oldCartesian, transform: transform!)
        let newLatLon = makeLatLonE(vector: newCartesian, datum: target)
        
        return newLatLon
    }
    
    func toCartesian() -> Vector {
        let ɸ = self.lat.toRadians()
        let λ = self.lon.toRadians()
        let h = 0.0 //height above ellipsoid, this is not currently used
        let a = self.datum.ellipsoid.a
        let f = self.datum.ellipsoid.f
        
        let sinɸ = sin(ɸ)
        let cosɸ = cos(ɸ)
        let sinλ = sin(λ)
        let cosλ = cos(λ)
        
        let eSq: Double = 2 * f - f * f //1st eccentricity squared ==> (a^2 - b^2)/a^2
        let v = a / sqrt(1 - eSq * sinɸ * sinɸ) //radius of curvature in prime vertical
        
        let x = (v + h) * cosɸ * cosλ
        let y = (v + h) * cosɸ * sinλ
        let z = (v * (1 - eSq) + h) * sinɸ
        
        return Vector(x: x, y: y, z: z)
    }
    
    func makeLatLonE(vector point:Vector, datum ref: Datum) -> LatLon{
        let x = point.x
        let y = point.y
        let z = point.z
        let a = ref.ellipsoid.a
        let b = ref.ellipsoid.b
        let f = ref.ellipsoid.f
        let e2 = 2 * f - f * f //1st eccentricity squared ==> (a^2 - b^2)/a^2
        let ε2 = e2 / (1 - e2) //2nd eccentricity squared ==> (a^2 - b^2)/a^2
        let p = sqrt(x * x + y * y) //distance from minor axis
        let r = sqrt(p * p + z * z) //polar radius
        
        //parametric latitude
        let tanβ = (b * z) / (a * p) * (1 + ε2 * b / r)
        let sinβ = tanβ / sqrt(1 + tanβ * tanβ)
        let cosβ = sinβ / tanβ
        
        //geodetic latitude
        let ɸ = cosβ.isNaN ? 0 : sqrt(atan2(z + ε2 * b * sinβ * sinβ * sinβ, p - e2 * a * cosβ * cosβ * cosβ))
        let λ = atan2(y, x)
        
        //height above ellipsoid, not currently used
        //        let sinɸ = sin(ɸ)
        //        let cosɸ = cos(ɸ)
        //        let v = a / sqrt(1 - e2 * sinɸ * sinɸ) //length of the normal terminated by the minor axis
        //        let h = p * cosɸ + z * sinɸ - (a * a / v)
        
        return LatLon(lat: ɸ.toDegrees(), lon: λ.toDegrees(), datum: ref)
    }
    
    func applyTransform(point: Vector, transform: Transform) -> Vector {
        let x1 = point.x
        let y1 = point.y
        let z1 = point.z
        let sFloat: Double = 1e6
        let tx = transform.tx
        let ty = transform.ty
        let tz = transform.tz
        let s1 = transform.s / sFloat + 1
        let rx = (transform.rx / 3600).toRadians()
        let ry = (transform.ry / 3600).toRadians()
        let rz = (transform.rz / 3600).toRadians()
        
        let x2 = tx + x1 * s1 - y1 * rz + z1 * ry
        let y2 = ty + x1 * rz + y1 * s1 - z1 * rx
        let z2 = tz + x1 * ry + y1 * rx + z1 * s1
        
        return Vector(x: x2, y: y2, z: z2)
    }
    
    static func parseLatLon(stringToParse val: String) throws -> LatLon {
        guard var idx = val.index(of: ",") else{
            throw LatLonError.parseError("Invalid string")
        }
        let strLat =  val[val.startIndex..<idx].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        idx = val.index(after: idx)
        let strLon = val[idx..<val.endIndex].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        guard strLat.count > 0 && strLon.count > 0 else {
            throw LatLonError.parseError("Invalid string")
        }
        var matchFound: Bool = false
        var regex = try! NSRegularExpression(pattern: "\\A[Nn]")
        var range = NSMakeRange(0, strLat.count)
        var changes = regex.stringByReplacingMatches(in: strLat, options: [], range: range, withTemplate: "")
        if strLat.count != changes.count{
            changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) N"
            matchFound = true
        }
        if !matchFound {
            regex = try! NSRegularExpression(pattern: "[Nn]$")
            changes = regex.stringByReplacingMatches(in: strLat, options: [], range: range, withTemplate: "")
            if strLat.count != changes.count{
                changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) N"
                matchFound = true
            }
        }
        
        if !matchFound {
            regex = try! NSRegularExpression(pattern: "\\A[Ss]")
            changes = regex.stringByReplacingMatches(in: strLat, options: [], range: range, withTemplate: "")
            if (strLat.count != changes.count){
                changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) S"
                matchFound = true
            }
        }
        
        if !matchFound {
            regex = try! NSRegularExpression(pattern: "[Ss]$")
            changes = regex.stringByReplacingMatches(in: strLat, options: [], range: range, withTemplate: "")
            if (strLat.count != changes.count){
                changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) S"
                matchFound = true
            }
        }
        
        if !matchFound {
            regex = try! NSRegularExpression(pattern: "\\A([-])")
            changes = regex.stringByReplacingMatches(in: strLat, options: [], range: range, withTemplate: "")
            if (strLat.count != changes.count){
                changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) S"
                matchFound = true
            }
            else {
                changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) N"
                matchFound = true
            }
        }
        
        range = NSMakeRange(0, changes.count)
        regex = try! NSRegularExpression(pattern: "[abcdefghijklmopqrtuvwxyzABCDEFGHIJKLMOPQRTUVWXYZ]+")
        changes = regex.stringByReplacingMatches(in: changes, options: [], range: range, withTemplate: "")
        
        guard matchFound else {
            throw LatLonError.parseError("Invalid string")
        }
        let convertableLat = changes //we've got one, so we can store it
        matchFound = false
        
        regex = try! NSRegularExpression(pattern: "\\A[Ee]")
        range = NSMakeRange(0, strLon.count)
        changes = regex.stringByReplacingMatches(in: strLon, options: [], range: range, withTemplate: "")
        if strLon.count != changes.count{
            changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) E"
            matchFound = true
        }
        if !matchFound {
            regex = try! NSRegularExpression(pattern: "[Ee]$")
            changes = regex.stringByReplacingMatches(in: strLon, options: [], range: range, withTemplate: "")
            if strLon.count != changes.count{
                changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) E"
                matchFound = true
            }
        }
        
        if !matchFound {
            regex = try! NSRegularExpression(pattern: "\\A[Ww]")
            changes = regex.stringByReplacingMatches(in: strLon, options: [], range: range, withTemplate: "")
            if (strLon.count != changes.count){
                changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) W"
                matchFound = true
            }
        }
        
        if !matchFound {
            regex = try! NSRegularExpression(pattern: "[Ww]$")
            changes = regex.stringByReplacingMatches(in: strLon, options: [], range: range, withTemplate: "")
            if (strLon.count != changes.count){
                changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) S"
                matchFound = true
            }
        }
        
        if !matchFound {
            regex = try! NSRegularExpression(pattern: "\\A([-])")
            changes = regex.stringByReplacingMatches(in: strLon, options: [], range: range, withTemplate: "")
            if (strLon.count != changes.count){
                changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) W"
                matchFound = true
            }
            else {
                changes = "\(changes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) E"
                matchFound = true
            }
        }
        
        range = NSMakeRange(0, changes.count)
        regex = try! NSRegularExpression(pattern: "[abcdfghijklmnopqrstuvxyzABCDFGHIJKLMNOPQRSTUVXYZ]+")
        changes = regex.stringByReplacingMatches(in: changes, options: [], range: range, withTemplate: "")
        
        guard matchFound else {
            throw LatLonError.parseError("Invalid string")
        }
        
        let convertableLon = changes
        
        let lat = DMS.parseDMS(degMinSec: convertableLat)
        let lon = DMS.parseDMS(degMinSec: convertableLon)
        let wgsDatum = Datums().datums.filter {$0.name == Datums.wgs84}.first!
        
        return LatLon(lat: lat, lon: lon, datum: wgsDatum)
    }
}
