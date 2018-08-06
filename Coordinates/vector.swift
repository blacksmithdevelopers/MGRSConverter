//
//  vector.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/1/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

public struct Vector: Equatable, CustomStringConvertible {
    
    public var description:String {
        let xString = String(format: "%.5f", self.x)
        let yString = String(format: "%.5f", self.y)
        let zString = String(format: "%.5f", self.z)
        return "[\(xString), \(yString), \(zString)]"
    }
    
    public var x: Double
    public var y: Double
    public var z: Double
    
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public static func ==(lhs: Vector, rhs: Vector) -> Bool {
        return (lhs.x == rhs.x) && (lhs.y == rhs.y) && (lhs.z == rhs.z)
    }
    
    public static func +(lhs: Vector, rhs: Vector) -> Vector{
        return Vector(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    public static func -(lhs: Vector, rhs: Vector) -> Vector{
        return Vector(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    public static func *(lhs: Vector, rhs: Vector) -> Double{
        return (lhs.x * rhs.x) + (lhs.y * rhs.y) + (lhs.z * rhs.z)
    }
    
    public static func /(lhs: Vector, rhs: Vector) -> Double{
        return (lhs.x / rhs.x) + (lhs.y / rhs.y) + (lhs.z / rhs.z)
    }
    
    public func times(x: Double) -> Vector{
        return Vector(x: self.x * x, y: self.y * x, z: self.z * x)
    }
    
    public func divideBy(x: Double) -> Vector{
        return Vector(x: self.x / x, y: self.y / y, z: self.z / z)
    }
    
    public func dot(secondVector: Vector) -> Double{
        return self * secondVector
    }
    
    public func cross(secondVector: Vector) -> Vector {
        let x = (self.y * secondVector.z) - (self.z * secondVector.y)
        let y = (self.z * secondVector.x) - (self.x * secondVector.z)
        let z = (self.x * secondVector.y) - (self.y * secondVector.x)
        return Vector(x: x, y: y, z: z)
    }
    
    public func negate() -> Vector {
        return Vector(x: self.x * -1, y: self.y * -1, z: self.z * -1)
    }
    
    public func length() -> Double{
        return sqrt((self.x * self.x) + (self.y * self.y) + (self.z + self.z))
    }
    
    public func unit() -> Vector{
        let norm = self.length()
        if (norm == 1) { return self }
        if (norm == 0) { return self }
        
        let x = self.x / norm
        let y = self.y / norm
        let z = self.z / norm
        return Vector(x: x, y: y, z: z)
    }
    
    //returns angle in radians
    public func angleTo(vector1: Vector, planeNormal: Vector = Vector(x: 999, y: 999, z: 999)) -> Double{
        
        let mathSign: Double
        if (planeNormal == Vector(x: 999, y: 999, z: 999)){
            mathSign = 1.0
        } else {
            mathSign = Double.sign(self.cross(secondVector: vector1).dot(secondVector: planeNormal))
        }
        
        let sinTheta = self.cross(secondVector: vector1).length() * mathSign
        let cosTheta = self.dot(secondVector: vector1)
        
        return atan2(sinTheta, cosTheta)
    }
    
    public func rotateAround(axis: Vector, theta: Double) -> Vector{
        let p1 = self.unit()
        let p = [p1.x, p1.y, p1.z] //the point being rotated
        let a = axis.unit() //the axis being rotated around
        let s = sin(theta)
        let c = cos(theta)
        let q1 = Vector(x: a.x * a.x * (1 - c) + c, y: a.x * a.y * (1 - c) - a.z * s, z: a.x * a.z * (1 - c) + a.y * s)
        let q2 = Vector(x: a.y * a.x * (1 - c) + a.z * s, y: a.y * a.y * (1 - c) + c, z: a.y * a.z * (1 - c) - a.x * s)
        let q3 = Vector(x: a.z * a.x * (1 - c) - a.y * s, y: a.z * a.y * (1 - c) + a.x * s, z: a.z * a.z * (1 - c) + c)
        /*let q = [
            [ a.x * a.x * (1 - c) + c,       a.x * a.y * (1 - c) - a.z * s, a.x * a.z * (1 - c) + a.y * s ],
            [ a.y * a.x * (1 - c) + a.z * s, a.y * a.y * (1 - c) + c,       a.y * a.z * (1 - c) - a.x * s ],
            [ a.z * a.x * (1 - c) - a.y * s, a.z * a.y * (1 - c) + a.x * s, a.z * a.z * (1 - c) + c ]
        ]*/
        let q = [
            [ q1.x, q1.y, q1.z],
            [ q2.x, q2.y, q2.z],
            [ q3.x, q3.y, q3.z]
        ]
        
        var qp: [Double] = [0, 0, 0]
        for i in 0...2 {
            for j in 0...2{
                qp[i] += q[i][j] *  p[j]
            }
        }
        return Vector(x: qp[0], y: qp[1], z: qp[3])
    }
}
