//
//  datums.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/1/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

public struct Datum : Equatable {
    public let name: String
    public let ellipsoid: Ellipsoid
    public let transform: Transform
    
    public static func ==(lhs: Datum, rhs: Datum) -> Bool {
        return (lhs.ellipsoid == rhs.ellipsoid) && (lhs.name == rhs.name) && (lhs.transform == rhs.transform)
    }
}

public struct Transform: Equatable{
    let tx: Double
    let ty: Double
    let tz: Double
    let s: Double
    let rx: Double
    let ry: Double
    let rz: Double
    
    public static func ==(lhs: Transform, rhs: Transform) -> Bool {
        return (lhs.tx == rhs.tx) && (lhs.ty == rhs.ty) && (lhs.tz == rhs.tz) && (lhs.s == rhs.s) && (lhs.tx == rhs.tx) && (lhs.ty == rhs.ty) && (lhs.tz == rhs.tz)
    }
}

public struct Datums{
    let datums: [Datum]
    static let wgs84 = "WGS84"
    init(){
        let ed50Transform = Transform(tx: 89.5, ty: 93.8, tz: 123.1, s: -1.2, rx: 0.0, ry: 0.0, rz: 0.156)
        let irl75Transform = Transform(tx: -482.530, ty: 130.596, tz:-564.557,  s:-8.150,  rx:-1.042,  ry:-0.214,  rz:-0.631)
        let nad27Transform = Transform(tx: 8, ty: -160, tz: -176, s: 0, rx: 0, ry: 0, rz: 0)
        let nad83Transform = Transform(tx: 1.004, ty: -1.910, tz: -0.515, s: -0.0015, rx: 0.0267, ry: 0.00034, rz: 0.011)
        let ntfTransform = Transform(tx: 168, ty: 60, tz: -320, s: 0, rx: 0, ry: 0, rz: 0)
        let osgbTransform = Transform(tx: -446.448, ty: 125.157, tz: -542.060, s: 20.4894, rx: -0.1502, ry: -0.2470, rz: -0.8421)
        let potsdamTransform = Transform(tx: -582, ty: -105, tz: -414, s: -8.3, rx: 1.04, ry: 0.35, rz: -3.08)
        let tokyoTransform = Transform(tx: 148, ty: -507, tz: -685, s: 0, rx: 0, ry: 0, rz: 0)
        let wgs72Transform = Transform(tx: 0, ty: 0, tz: -4.5, s: -0.22, rx: 0, ry: 0, rz: 0)
        let wgs84Transform = Transform(tx: 0, ty: 0, tz: 0, s: 0, rx: 0, ry: 0, rz: 0)
        
        let ed50 = Datum(name: "ED50", ellipsoid: .Intl1924, transform: ed50Transform)
        let irl75 = Datum(name: "Irl1975", ellipsoid: .AiryModified, transform: irl75Transform)
        let nad27 = Datum(name: "NAD27", ellipsoid: .Clarke1866, transform: nad27Transform)
        let nad83 = Datum(name: "NAD83", ellipsoid: .GRS80, transform: nad83Transform)
        let ntf = Datum(name: "NTF", ellipsoid: .Clarke1880IGN, transform: ntfTransform)
        let osgb = Datum(name: "OSGB36", ellipsoid: .Airy1830, transform: osgbTransform)
        let potsdam = Datum(name: "Potsdam", ellipsoid: .Bessel1841, transform: potsdamTransform)
        let tokyo = Datum(name: "TokyoJapan", ellipsoid: .Bessel1841, transform: tokyoTransform)
        let wgs72 = Datum(name: "WGS72", ellipsoid: .WGS72, transform: wgs72Transform)
        let wgs84 = Datum(name: "WGS84", ellipsoid: .WGS84, transform: wgs84Transform)
        
        datums = [ed50, irl75, nad27, nad83, ntf, osgb, potsdam, tokyo, wgs72, wgs84]
    }
}

public struct DatumFinder {
    public static func getDatum(desiredDatum target: Datum) -> Datum {
        let store = Datums().datums
        if (store.contains(target)){
            return target
        } else{
            return store.filter { $0.name == Datums.wgs84 }.first!
        }
    }
}

