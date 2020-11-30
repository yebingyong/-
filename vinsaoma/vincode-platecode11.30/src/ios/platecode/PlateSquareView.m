//
//  PlateSquareView
//  PlateDemo
//
//  Created by DXY on 2017/7/13.
//  Copyright © 2017年 DXY. All rights reserved.
//

#import "PlateSquareView.h"

@implementation PlateSquareView {
    
    CGPoint leftBottom; //竖屏左下角
    CGPoint rightBottom; //竖屏右下角
    CGPoint leftTop;  //竖屏左上角
    CGPoint rightTop;  //竖屏右上角
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        CGRect rect_screen = [[UIScreen mainScreen]bounds];
        CGFloat width = rect_screen.size.width;
        CGFloat height = rect_screen.size.height;
        
        CGFloat hRatio = height/568.0;
        
        //        if(width == 320&&height==480){ //iphone 4/4s
        //            leftBottom = CGPointMake(0, 140);
        //            rightBottom = CGPointMake(0, 340);
        //            leftTop = CGPointMake(width, 140);
        //            rightTop = CGPointMake(width, 340);
        //            self.centerRect = CGRectMake(0, 140, width, 200);
        //        }
        //        else { //iphone 5/5s/6/6 plus/6s/6s plus
        leftTop = CGPointMake(0, 184*hRatio);
        leftBottom = CGPointMake(0, 384*hRatio);
        rightTop = CGPointMake(width, 184*hRatio);
        rightBottom = CGPointMake(width, 384*hRatio);
        self.squareFrame = CGRectMake(0, 184*hRatio, width, 200*hRatio);
        //        }
        
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    [[UIColor greenColor] set];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    //设置线宽
    CGContextSetLineWidth(context, 2.0f);
    
    //画角线
    CGContextMoveToPoint(context,leftBottom.x+1, leftBottom.y-20);
    CGContextAddLineToPoint(context, leftBottom.x+1, leftBottom.y);
    CGContextAddLineToPoint(context, leftBottom.x+20, leftBottom.y);
    
    CGContextMoveToPoint(context, rightBottom.x-2,rightBottom.y-20);
    CGContextAddLineToPoint(context, rightBottom.x-2,rightBottom.y);
    CGContextAddLineToPoint(context, rightBottom.x-20,rightBottom.y);
    
    CGContextMoveToPoint(context, leftTop.x+20,leftTop.y);
    CGContextAddLineToPoint(context, leftTop.x+1,leftTop.y);
    CGContextAddLineToPoint(context, leftTop.x+1,leftTop.y+20);
    
    CGContextMoveToPoint(context, rightTop.x-2, rightTop.y+20);
    CGContextAddLineToPoint(context, rightTop.x-2, rightTop.y);
    CGContextAddLineToPoint(context, rightTop.x-20, rightTop.y);
    CGContextStrokePath(context);
    
    [[UIColor whiteColor] set];
    context = UIGraphicsGetCurrentContext();
    //设置线宽
    CGContextSetLineWidth(context, 0.2f);
    //画边线
    CGContextMoveToPoint(context,leftBottom.x, leftBottom.y);
    CGContextAddLineToPoint(context, leftBottom.x, rightBottom.y);
    CGContextAddLineToPoint(context, rightTop.x, rightBottom.y);
    CGContextAddLineToPoint(context, rightTop.x, leftTop.y);
    CGContextAddLineToPoint(context, leftBottom.x, leftTop.y);
    CGContextStrokePath(context);
}

@end
