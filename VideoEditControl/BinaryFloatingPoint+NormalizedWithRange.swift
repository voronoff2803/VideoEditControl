//
//  BinaryFloatingPoint+NormalizedWithRange.swift
//  VideoEditControl
//
//  Created by Bogdan Pashchenko on 24.10.2019.
//  Copyright © 2019 Алексей Воронов. All rights reserved.
//

import Foundation

extension BinaryFloatingPoint {
    func normalized(with range: ClosedRange<Self>) -> Self {
        return (self - range.lowerBound) / range.width
    }
    
    func deNormalized(with range: ClosedRange<Self>) -> Self {
        return self * range.width + range.lowerBound
    }
}

extension ClosedRange where Bound: Numeric {
    var width: Bound { upperBound - lowerBound }
}
