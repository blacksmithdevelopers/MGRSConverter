//
//  String+getIntegerPosition.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/2/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

extension String {
    func getPositionOfCharacter(_ val: Character) -> Int {
        var pos: Int = 0
        for char in self {
            if (char == val){
                return pos
            }
            pos += 1
        }
        return -1
    }
    
    static func getPositionOfCharacter(_ val: Character, string: String) -> Int{
        return string.getPositionOfCharacter(val)
    }
}
