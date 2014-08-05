//
//  CoolButton.m
//  CoolButton
//
//  Created by Brian Moakley on 2/21/13.
//  Copyright (c) 2013 Razeware. All rights reserved.
//

#import "CoolButton.h"

@implementation CoolButton

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    int outR = 36;
    int outWidth = 7;
    int inR = 30;
    int inWidth = 1;
    
    CGContextRef outerCircleContext = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(outerCircleContext, outWidth);
    
    CGContextSetStrokeColorWithColor(outerCircleContext, [UIColor whiteColor].CGColor);
    
    CGRect outerRectangle = CGRectMake(CGRectGetMidX(rect) - outR, CGRectGetMidY(rect) - outR, outR * 2,outR * 2);
    
    CGContextAddEllipseInRect(outerCircleContext, outerRectangle);
    
    CGContextStrokePath(outerCircleContext);
    
    CGContextRef innerCircleContext = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(innerCircleContext, inWidth);
    
    if (self.state == UIControlStateHighlighted) {
        CGContextSetFillColorWithColor(innerCircleContext, [UIColor redColor].CGColor);
    }else{
        CGContextSetFillColorWithColor(innerCircleContext, [UIColor whiteColor].CGColor);
    }
    
    CGRect innerRectangle = CGRectMake(CGRectGetMidX(rect) - inR, CGRectGetMidY(rect) - inR , inR * 2, inR * 2);
    
    CGContextAddEllipseInRect(innerCircleContext, innerRectangle);
    
    CGContextFillPath(innerCircleContext);
}

-(void) setHue:(CGFloat)hue
{
    [self setNeedsDisplay];
}

-(void) setSaturation:(CGFloat)saturation
{
    [self setNeedsDisplay];
}

-(void) setBrightness:(CGFloat)brightness
{
    [self setNeedsDisplay];
}

- (void)hesitateUpdate
{
    [self setNeedsDisplay];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    [self setNeedsDisplay];
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [self setNeedsDisplay];
    [self performSelector:@selector(hesitateUpdate) withObject:nil afterDelay:0.1];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self setNeedsDisplay];
    [self performSelector:@selector(hesitateUpdate) withObject:nil afterDelay:0.1];
}

@end