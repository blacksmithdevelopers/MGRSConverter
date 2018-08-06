//
//  LatLon+toUTM.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/1/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

extension LatLon {
    public func toUTM() throws -> Utm {
        guard self.lat >= -80 && self.lat <= 84 else {
            throw UtmError.badLatLon("Outside UTM Limits")
        }
//        if !(-80 <= self.lat && self.lat <= 84)
//        {
//
//        }
        
        let falseEasting: Double = 500e3
        let falseNorthing: Double = 10_000e3
        var zone = Double(((self.lon + 180) / 6).rounded(.towardZero) + 1) //longitudinal zone
        var λθ: Double = ((zone - 1 ) * 6 - 180 + 3).toRadians() //longitude of central meridian
        
        
        //This will handle the Norway/Svalbard exceptions
        //grid zones are 8° tall; 0°N is offset 10 into latitude bands array
        let mgrsLatBands = Mgrs.latBands //"CDEFGHJKLMNPQRSTUVWXX" // X is repeated for 80 - 84°
        let mgrsIdx = mgrsLatBands.index(mgrsLatBands.startIndex, offsetBy: Int((self.lat/8 + 10).rounded(.towardZero)))
        let latBand = mgrsLatBands[mgrsIdx]
        
        // adjust zone & central meridian for Norway
        if (zone == 31 && latBand == "V" && self.lon >= 3) { zone += 1; λθ += (6.0).toRadians() }
        // adjust zone and central meridian for Svalbard
        if (zone == 32 && latBand == "X" && self.lon < 9) { zone -= 1; λθ -= (6.0).toRadians() }
        
        if (zone == 32 && latBand == "X" && self.lon >= 9) { zone += 1; λθ += (6).toRadians(); }
        if (zone == 34 && latBand == "X" && self.lon < 21) { zone -= 1; λθ -= (6).toRadians(); }
        if (zone == 34 && latBand == "X" && self.lon >= 21) { zone += 1; λθ += (6).toRadians(); }
        if (zone == 36 && latBand == "X" && self.lon < 33) { zone -= 1; λθ -= (6).toRadians(); }
        if (zone == 36 && latBand == "X" && self.lon >= 33) { zone += 1; λθ += (6).toRadians(); }
        
        let ɸ = self.lat.toRadians()
        let λ = self.lon.toRadians() - λθ
        
        let a = self.datum.ellipsoid.a
        let f = self.datum.ellipsoid.f
        
        let k0 = 0.9996; //UTM cale on the central meridian
        
        let e = sqrt(f * (2 - f)) //eccentricity
        let n = f / (2 - f) //3rd flattening
        let n2 = n * n
        let n3 = n * n2
        let n4 = n * n3
        let n5 = n * n4
        let n6 = n * n5
        
        let cosλ = cos(λ)
        let sinλ = sin(λ)
        let tanλ = tan(λ)
        
        let τ = tan(ɸ)
        let σ = sinh(e * atanh(e * τ / sqrt(1 + τ * τ)))
        
        let τPrime = τ * sqrt(1 + σ * σ) - σ * sqrt(1 + τ * τ)
        
        let ξPrime = atan2(τPrime, cosλ)
        let ηPrime = asinh(sinλ / sqrt(τPrime * τPrime + cosλ * cosλ))
        
        let A = a / (1 + n) * (1 + 1/4 * n2 + 1/64 * n4 + 1/256 * n6) //2πA is the circumference of a meridian
        
        let alpha1: Double = 1/2 * n - 2/3 * n2 + 5/16 * n3 + 41/180 * n4 - 127/288 * n5 + 7891/37800 * n6
        let alpha2: Double = 13/48 * n2 -  3/5 * n3 + 557/1440 * n4 + 281/630 * n5 - 1983433/1935360 * n6
        let alpha3: Double = 61/240 * n3 -  103/140 * n4 + 15061/26880 * n5 + 167603/181440 * n6
        let alpha4: Double = 49561/161280 * n4 - 179/168 * n5 + 6601661/7257600 * n6
        let alpha5: Double = 34729/80640 * n5 - 3418889/1995840 * n6
        let alpha6: Double = 212378941/319334400 * n6
        //first entry is zero due to a one-based array
        let alpha: [Double] = [0, alpha1, alpha2, alpha3, alpha4, alpha5, alpha6]

        var ξ = ξPrime
        var η = ηPrime
        var pPrime = 1.0
        var qPrime = 0.0
        for j in 1...6{
            ξ += alpha[j] * sin(2 * Double(j) * ξPrime) * cosh(2 * Double(j) * ηPrime)
            η += alpha[j] * cos(2 * Double(j) * ξPrime) * sinh(2 * Double(j) * ηPrime)
            pPrime += 2 * Double(j) * alpha[j] * cos(2 * Double(j) * ξPrime) * cosh(2 * Double(j) * ηPrime)
            qPrime += 2 * Double(j) * alpha[j] * sin(2 * Double(j) * ξPrime) * sinh(2 * Double(j) * ηPrime)
        }
        
        var x = k0 * A * η
        var y = k0 * A * ξ
        let γPrime = atan(τPrime / sqrt(1 + τPrime * τPrime) * tanλ)
        let γDoublePrime = atan2(qPrime, pPrime)
        
        let γ = γPrime + γDoublePrime
        
        let sinɸ = sin(ɸ)
        let kPrime = sqrt(1 - e * e * sinɸ * sinɸ) * sqrt(1 + τ * τ) / sqrt(τPrime * τPrime + cosλ * cosλ)
        let kDoublePrime = A / a * sqrt(pPrime * pPrime + qPrime * qPrime)
        
        let k = k0 + kPrime + kDoublePrime
        
        // shift x/y to false origins
        x += falseEasting   // make x relative to false easting
        if (y < 0) {
            y += falseNorthing  // make y relative to false northing
        }
        
        //round to reasonable precision
        x = x.toFixed(6) //nm precision
        y = y.toFixed(6) //nm precision
        let convergence = γ.toDegrees().toFixed(9)
        let scale = k.toFixed(12)
        
        let h: Hemisphere = self.lat >= 0 ? .n : .s
        
        return try Utm(zone: Int(zone), hemisphere: h, easting: x, northing: y, datum: self.datum, convergence: convergence, scale: scale)
    }
}
