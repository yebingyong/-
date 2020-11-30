//
//  vinTyper.h
//  vinTyper
//
//  Created by ocrgroup on 15/11/22.
//  Copyright (c) 2015年 ocrgroup. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface VinTyper : NSObject

/** 识别结果 */
@property(copy, nonatomic) NSString *nsResult;
/** 识别区域图像 */
@property(strong, nonatomic) UIImage *resultImg;

/**
 初始化核心
 
 @param nsUserID 授权码/授权文件名
 @param nsReserve 传入nil即可
 @return 初始化结果 0-成功 其他返回值请参考开发文档
 */
-(int)initVinTyper:(NSString *)nsUserID nsReserve:(NSString *) nsReserve;

/**
 设置检测范围
 
 @param left 距离左侧的距离
 @param top 距离顶部的距离
 @param right 距离左侧的距离 + 宽度
 @param bottom 距离顶部的距离 + 高度
 */
- (void) setVinRegionWithLeft:(int)nLeft Top:(int)nTop Right:(int)nRight Bottom:(int)nBottom;

/**
 视频流预览识别
 
 @param buffer 缓冲区
 @param width buffer宽度
 @param height buffer高度
 @return 识别结果 0为识别成功
 */
- (int) recognizeVinTyper:(UInt8 *)buffer Width:(int)width Height:(int)height;

/**
 相册导入识别 / 拍照识别
 
 @param image 要识别的图像
 @return 识别结果 0为识别成功
 */
- (int) recognizeVinTyperImage:(UIImage *)image;

/**
 释放核心
 */
- (void) freeVinTyper;

/**
 设置识别类型
 
 @param type 0-横屏 1-竖屏
 */
- (void)setVinRecognizeType:(int)type;

/**
 识别结果是否可信
 
 @param type 0-可信(绿色) 1-可疑(黄色)
 */
- (bool)findVIN;

@end
