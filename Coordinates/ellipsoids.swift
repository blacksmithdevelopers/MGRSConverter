//
//  ellipsoids.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/1/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

public enum Ellipsoid {
    case WGS84
    case Airy1830
    case AiryModified
    case Bessel1841
    case Clarke1866
    case Clarke1880IGN
    case GRS80
    case Intl1924
    case WGS72
    
    public var a: Double {
        switch self {
        case .WGS84:
            return 6378137
        case .Airy1830:
            return 6377563.396
        case .AiryModified:
            return 6377340.189
        case .Bessel1841:
            return 6377397.155
        case .Clarke1866:
            return 6378206.4
        case .Clarke1880IGN:
            return 6378249.2
        case .GRS80:
            return 6378137
        case .Intl1924:
            return 6378388
        case .WGS72:
            return 6378135
        }
    }
    
    public var b: Double {
        switch self{
        case .WGS84:
            return 6356752.314245
        case .Airy1830:
            return 6356256.909
        case .AiryModified:
            return 6356034.448
        case .Bessel1841:
            return 6356078.962818
        case .Clarke1866:
            return 6356583.8
        case .Clarke1880IGN:
            return 6356515.0
        case .GRS80:
            return 6356752.314140
        case .Intl1924:
            return 6356911.946
        case .WGS72:
            return 6356750.5
        }
    }
    
    public var f: Double {
        switch self{
        case .WGS84:
            return 1/298.257223563
        case .Airy1830:
            return 1/299.3249646
        case .AiryModified:
            return 1/299.3249646
        case .Bessel1841:
            return 1/299.1528128
        case .Clarke1866:
            return 1/294.978698214
        case .Clarke1880IGN:
            return 1/293.466021294
        case .GRS80:
            return 1/298.257222101
        case .Intl1924:
            return 1/297
        case .WGS72:
            return 1/298.26
        }
    }
}
