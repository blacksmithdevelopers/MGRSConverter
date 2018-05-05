//
//  Double+Sign.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/1/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

extension Double {
    func sign() -> Double {
        return (self < 0.0 ? -1.0 : 1.0)
    }
    
    static func sign(_ val: Double) -> Double{
        return (val < 0.0 ? -1.0 : 1.0)
    }
    
    func toRadians() -> Double {
        return self * Double.pi / 180
    }
    
    func toDegrees() -> Double {
        return self * 180 / Double.pi
    }
    
    func toFixed(_ digits: UInt) -> Double {
        let power = pow(10, Double(digits))
        
        var val = (self * power).rounded()
        val /= power
        return val
    }
    
    func abs() -> Double {
        return self < 0 ? self * -1 : self
    }
    
    static func abs(_ val: Double) -> Double {
        return val.abs()
    }
    
    func truncateDigits(toDesiredDigits: UInt) -> Double {
        let top: Double = (pow(10, Double(toDesiredDigits))) - 1
        if (self <= top) {
            return self
        } else {
            var newDouble = self
            while (newDouble > top){
                newDouble = (newDouble / 10).rounded(FloatingPointRoundingRule.toNearestOrEven)
            }
            return newDouble
        }
    }
}
