//
//  Optional+Assert.swift
//  VideoEditControl
//
//  Created by Bogdan Pashchenko on 22.10.2019.
//  Copyright © 2019 Алексей Воронов. All rights reserved.
//

extension Optional {
    var assertingNonNil: Wrapped? {
        assert(self != nil)
        return self
    }
}

extension Optional where Wrapped: BinaryFloatingPoint {
    var assertNonNilOrDefaultValue: Wrapped {
        switch self {
        case .none: assertionFailure(); return Wrapped(0)
        case .some(let v): return v
        }
    }
}
