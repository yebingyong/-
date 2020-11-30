#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVPluginResult.h>

@protocol PlateCameraDelegate <NSObject>

@required
//车牌初始化结果，判断核心是否初始化成功
- (void)initPlateWithResult:(int)nInit;

@optional

@end

//车牌识别接口相关实现
@interface PlateCode : CDVPlugin

//视频流获取vin
- (void)scan : (CDVInvokedUrlCommand *)command;
//返回成功识别车牌和颜色 key：plate 、color
- (void)returnSuccess:(NSString*)scannedText color:(NSString*)color callback:(NSString*)callback;
//返回识别失败信息
- (void)returnError:(NSString*)message callback:(NSString*)callback;

@end



@interface PlateCameraController : UIViewController


@property (assign, nonatomic) id<PlateCameraDelegate>delegate;

@property(strong, nonatomic) UIImage *resultImg;



/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 * 最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;


- (id)initWithAuthorizationCode:(NSString *)authorizationCode plugin:(PlateCode*)plugin callback:(NSString*)callback;

@end
