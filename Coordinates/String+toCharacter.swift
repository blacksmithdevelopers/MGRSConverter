//
//  Character+Convert.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/2/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import Foundation

extension String {
    
    static func toCharacter(_ val: String) -> Character{
        var rtn: Character = "`"
        for char in val{
            rtn = char
            break
        }
        return rtn
    }
    
    func toCharacter() -> Character{
        return String.toCharacter(self)
    }
}
