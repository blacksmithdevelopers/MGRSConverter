//
//  UTM.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/1/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

public enum Hemisphere : String {
    case n = "N"
    case s = "S"
    static func Hemisphere(_ val: String) -> Hemisphere?{
        switch val {
        case "n":
            fallthrough
        case "N":
            return .n
        case "s":
            fallthrough
        case "S":
            return .s
        default:
            return nil
        }
    }
}

public enum UtmError: Error {
    case badLatLon(String)
    case badString(String)
    case invalidEasting(String)
    case invalidNorthing(String)
    case invalidZone(String)
}

public struct Utm: CustomStringConvertible{
    
    private let wgs84Datum : Datum
    private let datumStore: [Datum]
    private func getDatum(targetDatum: Datum) -> Datum{
        if datumStore.contains(targetDatum) {
            return targetDatum
        } else {
            return datumStore.filter { $0.name == Datums.wgs84 }.first!
        }
    }
    
    public var description: String {
        return toString()
    }
    
    public var zone: Int {
        didSet (oldValue) {
            if zone < 0 || zone > 60 {
                zone = oldValue
            }
        }
    }
    
    var hemisphere: Hemisphere
    var easting: Double {
        didSet (oldValue) {
            if !(120e3 <= easting && easting <= 880e3){
                easting = oldValue
            }
        }
    }
    var northing: Double {
        didSet(oldValue){
            if !(0 <= northing && northing <= 10000e3){
                northing = oldValue
            }
        }
    }
    public var datum: Datum
    var convergence: Double?
    var scale: Double?
    
    public init(zone: Int, hemisphere: Hemisphere, easting: Double, northing: Double, datum: Datum, convergence: Double? = nil, scale: Double? = nil) throws {
        guard 120e3 <= easting && easting <= 880e3 else {
            throw UtmError.invalidEasting("Invalid Easting provided. Easting must be between 120,000 and 880,000")
        }
        guard 0 <= northing && northing <= 10000e3 else {
            throw UtmError.invalidNorthing("Invalid Northing provided. Northing must be between 0 and 10,000,000")
        }
        guard zone >= 0 && zone <= 60 else {
            throw UtmError.invalidZone("Invalid Zone provided.  Zone must be between 0 and 60")
        }
        self.datumStore = Datums().datums
        self.zone = zone
        self.hemisphere = hemisphere
        self.easting = easting
        self.northing = northing
        self.scale = scale
        self.convergence = convergence
        self.wgs84Datum = datumStore.filter { $0.name == Datums.wgs84 }.first!
        self.datum = datumStore.filter { $0.name == Datums.wgs84 }.first!
        self.datum = getDatum(targetDatum: datum)
    }
    
    public func toLatLonE() -> LatLon {
        let z = self.zone
        let h = self.hemisphere
        var x = self.easting
        var y = self.northing
        
        let falseEasting = 500e3
        let falseNorthing = 10_000e3
        let a = self.datum.ellipsoid.a
        let f = self.datum.ellipsoid.f
        
        let k0 = 0.9996 //UTM scale on the central meridian
        x = x - falseEasting  // make x relative to the central meridian
        y = h == .s ? y - falseNorthing : y  // make y relative to the central meridian
        
        let e = sqrt(f * (2 - f)) //eccentricity
        let n = f / (2 - f)
        let n2 = n * n
        let n3 = n2 * n
        let n4 = n3 * n
        let n5 = n4 * n
        let n6 = n5 * n
        
        let A = a / (1 + n) * (1 + 1/4 * n2 + 1/64 * n4 + 1/256 * n6) //2πA is the circumference of a meridian
        
        let η = x / (k0 * A)
        let ξ = y / (k0 * A)
        
        let β1 = 1/2 * n - 2/3 * n2 + 37/96 * n3 - 1/360 * n4 - 81/512 * n5 + 96199/604800 * n6
        let β2 = 1/48 * n2 +  1/15 * n3 - 437/1440 * n4 + 46/105 * n5 - 1118711/3870720 * n6
        let β3 = 17/480 * n3 - 37/840 * n4 - 209/4480 * n5 + 5569/90720 * n6
        let β4 = 4397/161280 * n4 - 11/504 * n5 - 830251/7257600 * n6
        let β5 = 4583/161280 * n5 - 108847/3991680 * n6
        let β6 = 20648693/638668800 * n6
        
        let β = [0, β1, β2, β3, β4, β5, β6]
        
        var ξPrime = ξ
        var ηPrime = η
        
        for j in 1...6{
            ξPrime -= β[j] * sin(2 * Double(j) * ξ) * cosh(2 * Double(j) * η)
            ηPrime -= β[j] * cos(2 * Double(j) * ξ) * sinh(2 * Double(j) * η)
        }
        
        let sinhηPrime = sinh(ηPrime)
        let sinξPrime = sin(ξPrime)
        let cosξPrime = cos(ξPrime)
        let τPrime = sinξPrime / sqrt(sinhηPrime * sinhηPrime + cosξPrime * cosξPrime)
        
        var τi = τPrime
        var ẟτi: Double
        repeat {
            let σi = sinh(e * atanh(e * τi / sqrt(1 + τi * τi)))
            let τiPrime = τi * sqrt(1 + σi * σi) - σi * sqrt(1 + τi * τi)
            ẟτi = (τPrime - τiPrime) / sqrt(1 + τiPrime * τiPrime) * (1 + (1 - e * e) * τi * τi) / ((1 - e * e) * sqrt(1 + τi * τi))
            τi += ẟτi
        } while (Double.abs(ẟτi) > 1e-12)
        
        let τ = τi
        
        let ɸ = atan(τ)
        
        var λ = atan2(sinhηPrime, cosξPrime)
        
        //// ***************************************************************************************
        //// The four-slash commented out code below is due to the way the original author wrote this
        //// for javascript.  At run time, he included two properties in the LatLon object that were
        //// not original to the struct definition.  Based on my current observation that these are
        //// are not necessary to the calculation, I have commented them out.  Should it become
        //// necessary to future calculations, the math is complete and ready to be uncommented.
        //// Additionally, changes will need to be made the LatLon class to ensure it has optional
        //// support for the variables "scale" and "convergence."  As it stands elsewhere in the
        //// implementation of the object, these two properties are not used and must be declared as
        //// optional to ensure continued Swift compliance.
        //// ***************************************************************************************
        ////var p = 1.0
        ////var q = 0.0
        
        ////for j in 1...6{
            ////p -= 2 * Double(j) * β[j] * cos(2 * Double(j) * ξ) * cosh(2 * Double(j) * η)
            ////q += 2 * Double(j) * β[j] * sin(2 * Double(j) * ξ) * sinh(2 * Double(j) * η)
        ////}
        
        ////let γPrime = atan(tan(ξPrime) * tanh(ηPrime))
        ////let γDoublePrime = atan2(q,p)
        
        ////let γ = γPrime + γDoublePrime
        ////let sinɸ = sin(ɸ)
        ////let kPrime = sqrt(1 - e * e * sinɸ * sinɸ) * sqrt(1 + τ * τ) * sqrt(sinhηPrime * sinhηPrime + cosξPrime * cosξPrime)
        ////let kDoublePrime = A / a / sqrt(p * p + q * q)
        ////let k = k0 + kPrime + kDoublePrime
        
        let λɸ: Double = ((Double(z) - 1) * 6 - 180 + 3).toRadians()
        λ += λɸ  //move λ from zonal to global coordinates
        
        
        //round to reasonable precision
        let lat = ɸ.toDegrees().toFixed(11) //nm precision (1nm = 10^-11°)
        let lon = λ.toDegrees().toFixed(11)
        ////let convergence = γ.toDegrees().toFixed(9)
        ////let scale = k.toFixed(12)
        
        return LatLon(lat: lat, lon: lon, datum: self.datum)
    }
    
    public static func parseUTM(utmCoord: String) throws -> Utm{
        let wgsDatum = Datums().datums.filter {$0.name == Datums.wgs84}.first!
        return try parseUTM(utmCoord: utmCoord, datum: wgsDatum)
    }
    
    public static func parseUTM(utmCoord: String, datum: Datum) throws -> Utm{
        let foundDatum = DatumFinder.getDatum(desiredDatum: datum)
        var utm = utmCoord// "31 N 448251 5411932"
        let regex = try! NSRegularExpression(pattern: "\\S+")
        utm = utm.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let range = NSMakeRange(0, utm.count)
        let matches = regex.matches(in: utm, range: range)
        var results = zip(matches, matches.dropFirst().map { Optional.some($0) } + [nil]).map{ current, next -> String in
            let newRange = current.range(at: 0)
            let start = String.UTF16Index(encodedOffset: newRange.location)
            let end = next.map {$0.range(at: 0)}.map { String.UTF16Index(encodedOffset: $0.location)} ?? String.UTF16Index(encodedOffset: utm.utf16.count)
            return String(utm.utf16[start..<end])!
        }
        results = results.map {$0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)}
        
        if results.count != 4 {
            throw UtmError.badString("Invalid UTM Coordinate provided.  Ensure you have spaces between the items")
        }
        
        guard let zone = Int(results[0]), let hemisphere = Hemisphere.Hemisphere(results[1]), let easting = Double(results[2]), let northing = Double(results[3]) else{
            throw UtmError.badString("Invalid UTM Coordinate provided. The system could not parse the zone, easting or northing fields")
        }

        return try Utm(zone: zone, hemisphere: hemisphere, easting: easting, northing: northing, datum: foundDatum)
    }
    
    public func toString() -> String{
        return toString(precision: 0)
    }
    
    public func toString(precision: UInt) -> String{
        let z = self.zone < 10 ? "0\(self.zone)" : "\(self.zone)"
        let h = self.hemisphere == .n ? "N" : "S"
        let e = String(format: "%.0f", self.easting.toFixed(precision))
        let n = String(format: "%.0f", self.northing.toFixed(precision))
        return "\(z) \(h) \(e) \(n)"
    }
}
