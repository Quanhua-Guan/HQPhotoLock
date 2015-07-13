//
//  CircleButton.m
//  Think24
//
//  Created by 泉华 官 on 14-3-3.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

#import "CircleButton.h"

// CircleButton
@implementation CircleButton
{
    UIColor *realBackgroundColor;
}

#pragma mark - Init, Reset the frame after initialization.

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.frame = self.frame;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = self.frame;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    realBackgroundColor = backgroundColor;
    super.backgroundColor = [UIColor clearColor];
    [self setNeedsDisplay];
}

/**
 Set both width and height of frame to the shorter one of them(width and height).
 */
- (void)setFrame:(CGRect)frame
{
    CGFloat length = frame.size.width > frame.size.height ? frame.size.height : frame.size.width;
    super.frame = CGRectMake(frame.origin.x, frame.origin.y, length, length);
}

#pragma mark - Hit Test

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    point = [self.superview convertPoint:point fromView:self];// Convert point.
    CALayer *layer = (CALayer *)(self.layer.presentationLayer);
    CGFloat r = self.bounds.size.width / 2;
    CGFloat x = point.x - layer.position.x;
    CGFloat y = point.y - layer.position.y;
    return x * x + y * y < r * r;
}

#pragma mark - drawRect

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShouldAntialias(context, YES);
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetFlatness(context, 1.0f);
    //
    CGContextBeginPath(context);
    [realBackgroundColor set];
    CGContextFillEllipseInRect(context, CGRectInset(rect, 0, 0));
}

@end
