#import <UIKit/UIKit.h>
#import "SVProgressHUD.h"
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVPluginResult.h>

typedef enum : NSUInteger {
    kVinPhoneDirectionUp,
    kVinPhoneDirectionUpsideDown,
    kVinPhoneDirectionLeft,
    kVinPhoneDirectionRight,
} VinPhoneDirection;

@protocol CameraDelegate <NSObject>

@required
//vin码初始化结果
- (void)initVinTyperWithResult:(int)nInit;

@end

//vin接口相关实现
@interface VinCode : CDVPlugin

//视频流获取vin
- (void)scan : (CDVInvokedUrlCommand *)command;
//相册导入获取vin
- (void)getImage : (CDVInvokedUrlCommand *)command;
//拍照获取vin
- (void)recognizeImageFile : (CDVInvokedUrlCommand *)command;
//返回成功识别vin
- (void)returnSuccess:(NSString*)scannedText callback:(NSString*)callback;
//返回识别失败信息
- (void)returnError:(NSString*)message callback:(NSString*)callback;

@end


@interface VinCameraController : UIViewController

@property (assign, nonatomic) id<CameraDelegate>delegate;


- (instancetype)initWithAuthorizationCode:(NSString *)authorizationCode;

@end

@interface VinMainController : UIViewController

- (instancetype)initWithAuthorizationCode:(NSString *)authorizationCode;

@end
