//
//  MGRS.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/2/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

public enum MgrsError: Error{
    case invalidBand(String)
    case invalidZone(String)
    case invalidEasting(String)
    case invalidNorthing(String)
    case invalidGrid(String)
    case invalidFormat(String)
}

public struct Mgrs: CustomStringConvertible {
    
    static let latBands: String = "CDEFGHJKLMNPQRSTUVWXX"
    static let e100kLetters: [String] = [ "ABCDEFGH", "JKLMNPQR", "STUVWXYZ"]
    static let n100kLetters: [String] = ["ABCDEFGHJKLMNPQRSTUV", "FGHJKLMNPQRSTUVABCDE"]
    
    public var description: String {
        return self.toString()
    }
    public var zone: Int {
        didSet (oldValue) {
            if zone < 0 || zone > 60 {
                zone = oldValue
            }
        }
    }
    var band: Character
    var e100k: Character
    var n100k: Character
    var easting: Double
    var northing: Double
    var datum: Datum
    
    private let wgs84Datum : Datum
    private let datumStore: [Datum]
    private func getDatum(targetDatum: Datum) -> Datum{
        if datumStore.contains(targetDatum) {
            return targetDatum
        } else {
            return datumStore.filter { $0.name == Datums.wgs84 }.first!
        }
    }
    
    public init(zone: Int, band: Character, e100k: Character, n100k: Character, easting: Double, northing: Double, datum: Datum) throws {
        guard let _ = Mgrs.latBands.index(of: Character(String(band).uppercased())) else {
            throw MgrsError.invalidBand("Invalid band provided")
        }
        guard zone >= 0 && zone <= 60 else{
            throw MgrsError.invalidZone("Invalid zone provided")
        }
        
        self.datumStore = Datums().datums
        self.zone = zone
        self.band = Character(String(band).uppercased())
        self.e100k = Character(String(e100k).uppercased())
        self.n100k = Character(String(n100k).uppercased())
        self.easting = easting
        self.northing = northing
        self.wgs84Datum = datumStore.filter { $0.name == Datums.wgs84 }.first!
        self.datum = datumStore.filter { $0.name == Datums.wgs84 }.first!
        self.datum = getDatum(targetDatum: datum)
    }
    
    public func toUTM() throws -> Utm {
        let zone = self.zone
        let band = self.band
        let e100k = self.e100k
        let n100k = self.n100k
        let easting = self.easting
        let northing = self.northing
        let char: Character = "N"
        let hemisphere: Hemisphere = band >= char ? .n : .s

        // get easting specified by e100k
        let zoneIndex = Mgrs.e100kLetters.index(Mgrs.e100kLetters.startIndex, offsetBy: (zone - 1) % 3)
        let col = Mgrs.e100kLetters[zoneIndex].getPositionOfCharacter(e100k) + 1
        guard col >= 0 else {
            throw MgrsError.invalidEasting("An invalid easting was provided")
        }
        let e100kNum = Double(col) * 100e3 //e100k in meters
        
        // get northing specified by n100k
        let rowIndex = Mgrs.n100kLetters.index(Mgrs.n100kLetters.startIndex, offsetBy: (zone - 1) % 2)
        let row = Mgrs.n100kLetters[rowIndex].getPositionOfCharacter(n100k)
        guard row >= 0 else {
            throw MgrsError.invalidNorthing("An invalid northing was provided")
        }
        let n100kNum = Double(row) * 100e3 //n100k in meters
        
        // get latitude of (bottom of) band
        var latBand = Mgrs.latBands.getPositionOfCharacter(band)
        guard latBand >= 0 else {
            throw MgrsError.invalidBand("An invalid band was provided")
        }
        latBand = (latBand - 10) * 8
        
        // northing of bottom of band, extended to include entirety of bottom-most 100km square
        // (100km square boundaries are aligned with 100km UTM northing intervals
        let nBand: Double = (try LatLon(lat: Double(latBand), lon: 0.0, datum: self.datum).toUTM().northing / 100e3).rounded(.towardZero) * 100e3
        
        // 100km grid square row letters repeat every 2,000km north; add enough 2,000km blocks to
        // get into required band
        var n2m: Double = 0 //northing of 2,000 km block
        
        while ((n2m + n100kNum + northing) < nBand){
            n2m += 2000e3
        }
        
        return try Utm(zone: zone, hemisphere: hemisphere, easting: (e100kNum + easting), northing: (n2m + n100kNum + northing), datum: self.datum)
    }
    
    public static func parse(fromString: String) throws -> Mgrs {
        var mgrsString = fromString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        var regex = try! NSRegularExpression(pattern: "\\s")
        var matches = regex.matches(in: mgrsString, options: [], range: NSMakeRange(0, mgrsString.count))
        
        if (matches.count != 3){ //it counts the number of "found" whitespaces, not the returned items
            mgrsString = regex.stringByReplacingMatches(in: mgrsString, options: [], range: NSMakeRange(0, mgrsString.count), withTemplate: "")
            let zoneIdx = mgrsString.index(mgrsString.startIndex, offsetBy: 2)
            let strZone = mgrsString[mgrsString.startIndex..<zoneIdx]
            
            let bandIdx = mgrsString.index(zoneIdx, offsetBy: 1)
            let strBand = mgrsString[zoneIdx..<bandIdx]
            
            let eIdx = mgrsString.index(bandIdx, offsetBy: 1)
            let strEast = mgrsString[bandIdx..<eIdx]
            
            let nIdx = mgrsString.index(eIdx, offsetBy: 1)
            let strNorth = mgrsString[eIdx..<nIdx]
            
            let grid = mgrsString[nIdx..<mgrsString.endIndex]
            
//            if (grid.count % 2 != 0){
//                throw MgrsError.invalidGrid("Grid provided has an odd number of digits")
//            }
            guard (grid.count % 2 == 0) else {
                throw MgrsError.invalidGrid("Grid provided has an odd number of digits")
            }
            let half = grid.count / 2
            let eGridIdx = grid.index(grid.startIndex, offsetBy: half)
            let strEastGrid = grid[grid.startIndex..<eGridIdx]
            let strNorthGrid = grid[eGridIdx..<grid.endIndex]

            mgrsString = "\(strZone)\(strBand) \(strEast)\(strNorth) \(strEastGrid) \(strNorthGrid)"
        }
        
        regex = try! NSRegularExpression(pattern: "\\S+")
        matches = regex.matches(in: mgrsString, options: [], range: NSMakeRange(0, mgrsString.count))
        
        var results = zip(matches, matches.dropFirst().map { Optional.some($0) } + [nil]).map{ current, next -> String in
            let newRange = current.range(at: 0)
            let start = String.UTF16Index(encodedOffset: newRange.location)
            let end = next.map {$0.range(at: 0)}.map { String.UTF16Index(encodedOffset: $0.location)} ?? String.UTF16Index(encodedOffset: mgrsString.utf16.count)
            return String(mgrsString.utf16[start..<end])!
        }
        results = results.map {$0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)}
        guard results.count == 4 else{
            throw MgrsError.invalidFormat("Data provided is incomplete or invalid")
        }
        
        let gridZone: String = results[0]
        let zIdx = gridZone.index(gridZone.startIndex, offsetBy: 2)
        guard let zone = Int(gridZone[gridZone.startIndex..<zIdx]) else{
            throw MgrsError.invalidZone("Zone provided is not a number")
        }

        
        let band = String(gridZone[zIdx..<gridZone.endIndex]).toCharacter()
        let en100k: String = results[1]
        let enIdx = en100k.index(en100k.startIndex, offsetBy: 1)
        let e100k = String(en100k[en100k.startIndex..<enIdx]).toCharacter()
        let n100k = String(en100k[enIdx..<en100k.endIndex]).toCharacter()
        
        guard var eastGrid = Double(results[2]), var northGrid = Double(results[3]) else {
            throw MgrsError.invalidGrid("The grid provided could not be converted to a number")
        }
        eastGrid = fixGrid(grid: eastGrid)
        northGrid = fixGrid(grid: northGrid)
        
        let wgsDatum = Datums().datums.filter {$0.name == Datums.wgs84}.first!
        
        return try Mgrs(zone: zone, band: band, e100k: e100k, n100k: n100k, easting: eastGrid, northing: northGrid, datum: wgsDatum)
    }
    
    static func fixGrid(grid: Double) -> Double {
        var newGrid = grid
        while (newGrid <= 100_000){
            newGrid *= 10
        }
        if newGrid >= 100_000{
            newGrid /= 10
        }
        
        return newGrid
    }
    
    public func toString() -> String{
        return self.toString(precision: 5)
    }
    
    public func toString(precision: UInt) -> String{
        let stringFormat = "%0\(precision).0f"
        
        let zoneFormatted = String(format: "%02d", self.zone)
        let eRounded = easting.truncateDigits(toDesiredDigits: precision)
        let nRounded = northing.truncateDigits(toDesiredDigits: precision)
        let eastingFormatted = String(format: stringFormat, eRounded)
        let northingFormatted = String(format: stringFormat, nRounded)
        
        return "\(zoneFormatted)\(band) \(e100k)\(n100k) \(eastingFormatted) \(northingFormatted)"
    }
}
