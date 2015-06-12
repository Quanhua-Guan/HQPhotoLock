//
//  RectBorderButton.swift
//  Equal
//
//  Created by 泉华 官 on 14/11/27.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import UIKit

@IBDesignable
class RectBorderLabel: UILabel {
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
        borderColor = UIColor(white: 1, alpha: 0.5)
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let ctx = UIGraphicsGetCurrentContext()
        borderColor.set()
        //CGContextAddRect(ctx, CGRectMake(rect.origin.x, rect.origin.y, rect.width, 1.0))
        CGContextAddRect(ctx, CGRectMake(rect.origin.x, rect.origin.y + rect.height - CGFloat(1), rect.width, 1.0))
        CGContextFillPath(ctx)
        CGContextStrokePath(ctx)
    }
}
