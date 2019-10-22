//
//  BinaryFloatingPoint.swift
//  VideoEditControl
//
//  Created by Bogdan Pashchenko on 22.10.2019.
//  Copyright © 2019 Алексей Воронов. All rights reserved.
//

import CoreGraphics

extension BinaryFloatingPoint {
    var cg: CGFloat { CGFloat(self) }
    var flt: Float { Float(self) }
    var dbl: Double { Double(self) }
}
