//
//  RectBorderButton.swift
//  Equal
//
//  Created by 泉华 官 on 14/11/27.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import UIKit

@IBDesignable
class RectBorderButton: UIButton {
    private var borderColor:UIColor!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        borderColor = UIColor(white: 1, alpha: 0.9)
        layer.borderColor = borderColor.CGColor
        layer.borderWidth = 0.5
    }
}
