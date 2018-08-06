//
//  UTM+toMGRS.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/2/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

extension Utm {
    
    public func toMGRS() throws -> Mgrs{
        let zone = self.zone
        let latLon = self.toLatLonE()
        let mgrsLatBands = Mgrs.latBands
        let mgrsIdx = mgrsLatBands.index(mgrsLatBands.startIndex, offsetBy: Int((latLon.lat/8 + 10).rounded(.towardZero)))
        let selBand = mgrsLatBands[mgrsIdx]
        
        let col = Int((self.easting / 100e3).truncatingRemainder(dividingBy: 20))
        let mgrsE100KLetters = Mgrs.e100kLetters
        let subEIdx = mgrsE100KLetters.index(mgrsE100KLetters.startIndex, offsetBy: (zone - 1) % 3)
        let subELetters = mgrsE100KLetters[subEIdx]
        let e100kIdx = subELetters.index(subELetters.startIndex, offsetBy: col - 1)
        let selE100k = subELetters[e100kIdx]
        
        let row = Int((self.northing / 100e3).truncatingRemainder(dividingBy: 20))
        let mgrsN100KLetters = Mgrs.n100kLetters
        let subNIdx = mgrsN100KLetters.index(mgrsN100KLetters.startIndex, offsetBy: (zone - 1) % 2)
        let subNLetters = mgrsN100KLetters[subNIdx]
        let n100kIdx = subNLetters.index(subNLetters.startIndex, offsetBy: row)
        let selN100k = subNLetters[n100kIdx]
        
        var easting = self.easting.truncatingRemainder(dividingBy: 100e3)
        var northing = self.northing.truncatingRemainder(dividingBy: 100e3)
        
        easting = easting.toFixed(6)
        northing = northing.toFixed(6)
        
        return try Mgrs(zone: zone, band: selBand, e100k: selE100k, n100k: selN100k, easting: easting, northing: northing, datum: self.datum)
    }
}
