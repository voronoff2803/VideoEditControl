//
//  UIView+roundCorners.swift
//  VideoEditControl
//
//  Created by Алексей Воронов on 15.10.2019.
//  Copyright © 2019 Алексей Воронов. All rights reserved.
//

import UIKit

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
