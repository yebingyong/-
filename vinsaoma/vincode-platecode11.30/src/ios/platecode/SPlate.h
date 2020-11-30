//
//  SPlate.h
//  SPlate
//
//  Created by ocrgroup on 16/3/19.
//  Copyright © 2016年 ocrgroup. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface SPlate : NSObject

//识别结果

/** 识别结果 */
@property(copy, nonatomic) NSString *nsPlateNo;
/** 车牌颜色 */
@property(copy, nonatomic) NSString *nsPlateColor;
/** 车牌图像200*45 */
@property(strong, nonatomic) UIImage *plateImg;

/**
 初始化核心
 
 @param nsUserID 授权文件名 / 授权码
 @param nsReserve 传nil即可
 @return 是否初始化成功 0为初始化成功
 */
-(int)initSPlate:(NSString *)nsUserID nsReserve:(NSString *) nsReserve;

/**
 设置检测范围
 
 @param left 距离左侧的距离
 @param top 距离顶部的距离
 @param right 距离左侧的距离 + 宽度
 @param bottom 距离顶部的距离 + 高度
 */
-(void)setRegionWithLeft:(int)left Top:(int)top Right:(int)right Bottom:(int)bottom;

/**
 预览识别
 
 @param buffer 缓冲区
 @param width buffer宽度
 @param height buffer高度
 @param type 类型
 @return 是否识别成功 0为成功
 */
-(int) recognizeSPlate:(UInt8 *)buffer Width:(int)width Height:(int)height Type:(int)type;

/**
 图像识别

 @param image 图片
 @param type 横/竖屏拍摄(0-横屏 1-竖屏)
 @return 是否识别成功 0为成功
 */
-(int) recognizeSPlateImage:(UIImage*)image Type:(int)type;

/**
 释放核心
 */
- (void) freeSPlate;

@end
