
#import "VinCameraController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreMotion/CoreMotion.h>
#import "VinSquareView.h"
#import "AppDelegate.h"
#import "vinTyper.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define AUTHCODE @"66A26DF01048DD276FA6"

//顶部安全区
#define SafeAreaTopHeight (SCREENH == 812.0 ? 34 : 10)


#define SCREENH [UIScreen mainScreen].bounds.size.height
#define SCREENW [UIScreen mainScreen].bounds.size.width
#define SCREENRECT [UIScreen mainScreen].bounds

@class VinCode;
@class VinMainController;
@class VinCameraController;


@interface VinCameraController ()<UIAlertViewDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>


@property (nonatomic, strong) UITapGestureRecognizer * singleTap;

//@property (nonatomic, strong) UIButton * photoBtn;
@property (nonatomic, strong) UIButton * flashBtn;
@property (nonatomic, strong) UIButton * backBtn;
//@property (nonatomic, strong) UIButton * changeBtn;
//"将框置于VIN码前"
@property (nonatomic, strong) UILabel * centerLabel;
//"点击继续拍照"拍完照之后的提示Label
@property (nonatomic, strong) UILabel * topLabel;
//检测结果和保存成功提示label
@property (nonatomic, strong) UILabel * resultLabel;
//检测的结果图片
@property (nonatomic, strong) UIImageView * resultImageView;
//扫描线
@property (retain ,nonatomic) UIImageView * scanLine;

//方框View
@property (nonatomic, strong) VinSquareView * squareView;
//检测视图层
@property (nonatomic, strong) CAShapeLayer * detectLayer;

@property (nonatomic, strong) CMMotionManager * motionManager;

@property (nonatomic, assign) VinPhoneDirection phoneDirection;
/** 横/竖屏 */
@property (nonatomic, assign) BOOL isHorizontal;

//相机相关
@property (nonatomic, strong) AVCaptureSession * captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput * captureInput;
@property (nonatomic, strong) AVCaptureStillImageOutput * captureOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * captureDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * capturePreviewLayer;
@property (nonatomic, strong) AVCaptureDevice * captureDevice;

@property (nonatomic, retain) VinCode*           plugin;
@property (nonatomic, retain) NSString*        callback;
@property (nonatomic, retain) NSTimer*         nsTimer;
@property (nonatomic, retain) NSString*        nsResult;

- (id)initWithAuthorizationCode:(NSString *)authorizationCode plugin:(VinCode*)plugin callback:(NSString*)callback;
@end


@interface VinCode ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) CDVInvokedUrlCommand * command;
@property (nonatomic, retain) NSString*              callback;

@end

@implementation VinCode{
    VinTyper * _vinTyper;
}

//视频流获取vin
- (void)scan : (CDVInvokedUrlCommand *)command
{
    NSString*       callback;
    callback = command.callbackId;
    //ios 9以下会出现问题所以先放在主线程中
    //[self.commandDelegate runInBackground:^{
        VinCameraController * myCameraVC = [[VinCameraController alloc] initWithAuthorizationCode:AUTHCODE plugin:self callback:callback];
        [self.viewController presentViewController:myCameraVC animated:YES completion:nil];
    //}];
}

//拍照获取vin
- (void)recognizeImageFile : (CDVInvokedUrlCommand *)command
{

    self.command = command;
    self.callback = command.callbackId;

    UIImagePickerController * pickerVC = [[UIImagePickerController alloc] init];
    pickerVC.delegate = self;
    pickerVC.allowsEditing = YES;
    pickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self.viewController presentViewController:pickerVC animated:YES completion:nil];

}

//相册导入获取vin
- (void)getImage : (CDVInvokedUrlCommand *)command
{
    self.command = command;
    self.callback = command.callbackId;
    //判断相册资源是否可打开
    bool isPhotoLibraryAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
    if (isPhotoLibraryAvailable) {

        //子线程初始化识别核心
        [self performSelectorInBackground:@selector(initRecogKernal) withObject:nil];

        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        NSMutableArray *mediaTypes = [NSMutableArray array];
        [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
        controller.mediaTypes = mediaTypes;
        controller.allowsEditing = YES;
        controller.delegate = self;
        [self.viewController presentViewController:controller animated:YES completion:^(void){
            //            NSLog(@"Picker View Controller is presented");
        }];
    }else{
        [self returnError:@"打开相册失败，请确保有权限打开相册" callback:self.callback];
    }

}
//初始化识别核心
- (void)initRecogKernal {
    _vinTyper = [[VinTyper alloc] init];
    //[self initRecognizeCore];
}


- (void)initRecognizeCore{
    //初始化识别核心
    int nRet = [_vinTyper initVinTyper:AUTHCODE nsReserve:@""];
    if (nRet != 0) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        NSArray * appleLanguages = [defaults objectForKey:@"AppleLanguages"];
        NSString * systemLanguage = [appleLanguages objectAtIndex:0];
        if (![systemLanguage isEqualToString:@"zh-Hans"]) {
            NSString *initStr = [NSString stringWithFormat:@"Init Error!Error code:%d",nRet];
            UIAlertView *alertV = [[UIAlertView alloc]initWithTitle:@"Tips" message:initStr delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertV show];
        }else{
            NSString *initStr = [NSString stringWithFormat:@"初始化失败!错误代码:%d",nRet];
            UIAlertView *alertV = [[UIAlertView alloc]initWithTitle:@"提示" message:initStr delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertV show];
        }

    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *image = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    if (!image) {
        image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    }
    _vinTyper.nsResult = @"";
    [SVProgressHUD showWithStatus:@"正在努力识别中..."];

    [self initRecognizeCore];  //初始化核心
    if (image.size.width > image.size.height) {//横向
        [_vinTyper setVinRecognizeType:0];
    }else{//纵向
        [_vinTyper setVinRecognizeType:1];
    }
    [picker dismissViewControllerAnimated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(0, 0), ^{//开启子线程识别
            int bSuccess = [_vinTyper recognizeVinTyperImage:image];
            if (bSuccess == 0) {//识别成功，回到主线程
                dispatch_async(dispatch_get_main_queue(), ^{
                    //self.resultArr[0] = _vinTyper.nsResult;
                    NSLog(@"result: %@", _vinTyper.nsResult);
                    [SVProgressHUD dismiss];
                    //震动
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

                    [self deletelloc];
                    [self returnSuccess:_vinTyper.nsResult callback:self.callback];
                });
            }else{//识别失败，回到主线程刷新UI
                dispatch_async(dispatch_get_main_queue(), ^{
                    //self.resultArr[0] = @"识别失败";
                    NSLog(@"result: %@", _vinTyper.nsResult);
                    [SVProgressHUD dismiss];
                    [self deletelloc];
                    [self returnError:@"识别失败，请确保图片中包含VIN码" callback:self.callback];
                });
            }

        });
    }];
}
//释放资源
- (void)deletelloc {
    [_vinTyper freeVinTyper]; //释放核心
}


- (void)returnSuccess:(NSString*)scannedText callback:(NSString*)callback{

    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_OK
                               messageAsString: scannedText
                               ];
    [self.commandDelegate sendPluginResult:result callbackId:callback];
}

//--------------------------------------------------------------------------
- (void)returnError:(NSString*)message callback:(NSString*)callback{
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_ERROR
                               messageAsString: message
                               ];

    [self.commandDelegate sendPluginResult:result callbackId:callback];
}

@end

@implementation VinCameraController {
    NSString * _authorizationCode;  //公司名 / 授权码
    VinTyper * _vinTyper; //识别核心

    BOOL _isCameraAuthor; //是否有打开摄像头权限
    BOOL _isRecognize; //是否识别
    BOOL _flash; //控制闪光灯
    BOOL _isScan; //控制扫描线
    CGPoint _linePoint;//扫描线初始位置
    BOOL _isFocusing;//是否正在对焦
    BOOL _isFocusPixels;//是否相位对焦
    GLfloat _FocusPixelsPosition;//相位对焦下镜头位置
    GLfloat _curPosition;//当前镜头位置
}

@synthesize plugin               = _plugin;
@synthesize callback             = _callback;
@synthesize nsTimer              = _nsTimer;
@synthesize nsResult             = _nsResult;

SystemSoundID _soundVinFileObject;

- (id)initWithAuthorizationCode:(NSString *)authorizationCode plugin:(VinCode*)plugin callback:(NSString*)callback{
    if (self = [super init]) {
        _authorizationCode = authorizationCode;
    }
    self.plugin               = plugin;
    self.callback             = callback;

    CFURLRef soundFileURLRef  = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("VinImageResource.bundle/vin"), CFSTR ("caf"), NULL);
    AudioServicesCreateSystemSoundID(soundFileURLRef, &_soundVinFileObject);


    return self;
}

#pragma mark - Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBarHidden = YES;

    //子线程初始化识别核心
    [self performSelectorInBackground:@selector(initRecogKernal) withObject:nil];
    //设置默认为竖屏
    self.phoneDirection=kVinPhoneDirectionUp;
    //初始化相机
    [self initCamera];
    //UI
    [self prepareUI];

}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    [self performSelector:@selector(moveScanline)];
    _isRecognize = YES;
    AVCaptureDevice * camDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //注册通知
    [camDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
    if (_isFocusPixels) {
        [camDevice addObserver:self forKeyPath:@"lensPosition" options:NSKeyValueObservingOptionNew context:nil];
    }
    [self startMotionManager];
    //监听切换到前台事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];

    [self initRecognizeCore];

}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _isRecognize = NO;
    //移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //释放核心
    [_vinTyper freeVinTyper];
    AudioServicesRemoveSystemSoundCompletion(_soundVinFileObject);
    AudioServicesDisposeSystemSoundID(_soundVinFileObject);
    self.callback = nil;
    self.plugin = nil;
    self.nsTimer = nil;
    self.nsResult = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    AVCaptureDevice * camDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [camDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    if (_isFocusPixels) {
        [camDevice removeObserver:self forKeyPath:@"lensPosition"];
    }
    [self.captureSession stopRunning];

}


#pragma mark - 屏幕适配
- (CGFloat)getRatio {
    return SCREENH / 568.0;
}

#pragma mark - 初始化


- (BOOL)prefersStatusBarHidden {
    return YES;
}

//初始化识别核心
- (void)initRecogKernal {
    _vinTyper = [[VinTyper alloc] init];
}

- (void)initRecognizeCore {
    //初始化识别核心
    int nRet = [_vinTyper initVinTyper:_authorizationCode nsReserve:@""];
    if (nRet != 0) {
        if (_isCameraAuthor == NO) {
            [self.captureSession stopRunning];
            NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
            NSArray * appleLanguages = [defaults objectForKey:@"AppleLanguages"];
            NSString * systemLanguage = [appleLanguages objectAtIndex:0];
            if (![systemLanguage isEqualToString:@"zh-Hans"]) {
                NSString *initStr = [NSString stringWithFormat:@"Init Error!Error code:%d",nRet];
                UIAlertView *alertV = [[UIAlertView alloc]initWithTitle:@"Tips" message:initStr delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertV show];
            }else{
                NSString *initStr = [NSString stringWithFormat:@"初始化失败!错误代码:%d",nRet];
                UIAlertView *alertV = [[UIAlertView alloc]initWithTitle:@"提示" message:initStr delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertV show];
            }
        }
    }
}

//初始化相机
- (void)initCamera {
    //判断摄像头是否授权
    _isCameraAuthor = NO;
    AVAuthorizationStatus authorStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authorStatus == AVAuthorizationStatusRestricted || authorStatus == AVAuthorizationStatusDenied){
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        NSArray * allLanguages = [userDefaults objectForKey:@"AppleLanguages"];
        NSString * preferredLang = [allLanguages objectAtIndex:0];
        if (![preferredLang isEqualToString:@"zh-Hans"]) {
            UIAlertView * alt = [[UIAlertView alloc] initWithTitle:@"Please allow to access your device’s camera in “Settings”-“Privacy”-“Camera”" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alt show];
        }else{
            UIAlertView * alt = [[UIAlertView alloc] initWithTitle:@"未获得授权使用摄像头" message:@"请在 '设置-隐私-相机' 中打开" delegate:self cancelButtonTitle:nil otherButtonTitles:@"知道了", nil];
            [alt show];
        }
        _isCameraAuthor = YES;
        return;
    }

    //创建、配置输入
    NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == AVCaptureDevicePositionBack){
            self.captureDevice = device;
            self.captureInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        }
    }
    //输入设备
    [self.captureSession addInput:self.captureInput];
    //输出设备
    [self.captureSession addOutput:self.captureDataOutput];
    //输出设备
    [self.captureSession addOutput:self.captureOutput];
    //添加预览层
    [self.view.layer addSublayer:self.capturePreviewLayer];
    //开启相机
    [self.captureSession startRunning];


    //判断是否相位对焦
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
        AVCaptureDeviceFormat *deviceFormat = self.captureDevice.activeFormat;
        if (deviceFormat.autoFocusSystem == AVCaptureAutoFocusSystemPhaseDetection){
            _isFocusPixels = YES;
        }
    }
//    if (self.direction == kAudioDirectionHorizontal) {
//        [_vinTyper setVinRecognizeType:0];
//    }else{
//        [_vinTyper setVinRecognizeType:1];
//    }
//    //计算设置vin码的检测区域
//
//    [self setVinDetectArea];
}

- (void)setVinDetectArea {
    CGFloat x,y,h,w;
    int left,top,right,bottom;
    if (_isHorizontal) {
        //横屏
        x = self.squareView.squareFrame.origin.y;
        y = self.squareView.squareFrame.origin.x;
        h = self.squareView.squareFrame.size.width;
        w = self.squareView.squareFrame.size.height;

        //计算参数

        left = x / SCREENH * 1280;
        top = y / SCREENW * 720;
        right = (x + w) / SCREENH * 1280;
        bottom = (y + h) / SCREENW * 720;
    }else{
        //竖屏
        x = self.squareView.squareFrame.origin.x;
        y = self.squareView.squareFrame.origin.y;
        h = self.squareView.squareFrame.size.height;
        w = self.squareView.squareFrame.size.width;
        //计算参数
        left = x / SCREENW * 720;
        top = y / SCREENH * 1280;
        right = (x + w) / SCREENW * 720;
        bottom = (y + h) / SCREENH * 1280;
    }

    NSLog(@"left%d top%d right%d bottom%d",left,top,right,bottom);
    [_vinTyper setVinRegionWithLeft:left Top:top Right:right Bottom:bottom];
}

- (void)prepareUI {

    //设置检测视图层
    [self.view.layer addSublayer:self.detectLayer];
    self.view.layer.masksToBounds = YES;

    [self.view addSubview:self.squareView];

    [self.view addGestureRecognizer:self.singleTap];


    [self.view addSubview:self.flashBtn];

    [self.view addSubview:self.backBtn];

//    [self.view addSubview:self.changeBtn];


    [self.view addSubview:self.centerLabel];


    [self.view addSubview:self.resultLabel];

    [self.view addSubview:self.topLabel];

    [self.view addSubview:self.scanLine];

    [self.view addSubview:self.resultImageView];

    if (_isHorizontal) {
        [self frameSetupHorizontal];
    }else{
        [self frameSetupVertical];
    }

}

//横屏布局
- (void)frameSetupHorizontal {

    CGFloat ratio = [self getRatio];

    CGFloat width;
    width = 60 * ratio;


    self.flashBtn.frame = CGRectMake(SCREENW - width - 10, SafeAreaTopHeight, width, width);

//    self.changeBtn.frame = CGRectMake(0, 0, width, width);
//    self.changeBtn.center = CGPointMake(SCREENW * 0.5, width * 0.5);


    self.backBtn.frame = CGRectMake(10, SafeAreaTopHeight, width, width);


    CGPoint center;
    center.x = SCREENW * 0.5;
    center.y = SCREENH * 0.5;

    //"将框置于VIN码前"
    self.centerLabel.frame = CGRectMake(0, 0, 147, 25);
    self.centerLabel.center = center;
    self.centerLabel.layer.cornerRadius = self.centerLabel.frame.size.height / 2;
    self.centerLabel.layer.masksToBounds = YES;

    //"点击继续拍照"拍完照之后的提示Label
    self.topLabel.frame = CGRectMake(0, 0, 320, 25);
    CGPoint topLabelCenter = center;
    topLabelCenter.x = SCREENW - self.topLabel.frame.size.height / 2 - 10;
    self.topLabel.center = topLabelCenter;
    self.topLabel.layer.cornerRadius = self.topLabel.frame.size.height / 2;
    self.topLabel.layer.masksToBounds = YES;

    //检测结果和保存成功提示label
    self.resultLabel.frame = CGRectMake(0, 0, 355 * ratio, 60 * ratio);
    CGPoint resultLabelCenter = center;
    resultLabelCenter.x = center.x + self.squareView.squareFrame.size.width / 2 + self.resultLabel.frame.size.height / 2;
    self.resultLabel.center = resultLabelCenter;

    self.resultImageView.frame = CGRectMake(0, 0, self.squareView.squareFrame.size.height, self.squareView.squareFrame.size.width);
    self.resultImageView.center = center;

    //横屏则旋转
    if (self.phoneDirection == kVinPhoneDirectionLeft) {
        self.scanLine.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.resultImageView.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.centerLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.topLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.resultLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.backBtn.transform = CGAffineTransformMakeRotation(M_PI_2);
//        self.changeBtn.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.flashBtn.transform = CGAffineTransformMakeRotation(M_PI_2);
    }else if (self.phoneDirection == kVinPhoneDirectionRight) {
        self.scanLine.transform = CGAffineTransformMakeRotation(-M_PI_2);
        self.resultImageView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        self.centerLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);
        self.topLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);
        self.resultLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);
        self.backBtn.transform = CGAffineTransformMakeRotation(-M_PI_2);
//        self.changeBtn.transform = CGAffineTransformMakeRotation(-M_PI_2);
        self.flashBtn.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }
    [self moveScanline];

}

//竖屏布局
- (void)frameSetupVertical {
    CGFloat ratio = [self getRatio];

    CGFloat width;
    width = 60 * ratio;


    self.flashBtn.frame = CGRectMake(SCREENW - width - 10, SafeAreaTopHeight, width, width);

//    self.changeBtn.frame = CGRectMake(0, 0, width, width);
//    self.changeBtn.center = CGPointMake(SCREENW * 0.5, width * 0.5);
//

    self.backBtn.frame = CGRectMake(10, SafeAreaTopHeight, width, width);


    CGPoint center;
    center.x = SCREENW * 0.5;
    center.y = SCREENH * 0.5;

    //"将框置于VIN码前"
    self.centerLabel.frame = CGRectMake(0, 0, 147, 25);
    self.centerLabel.center = center;
    self.centerLabel.layer.cornerRadius = self.centerLabel.frame.size.height / 2;
    self.centerLabel.layer.masksToBounds = YES;


    //"点击继续拍照"拍完照之后的提示Label
    self.topLabel.frame = CGRectMake(0, 0, 320, 25);
    CGPoint topLabelCenter = center;
    topLabelCenter.y = width + self.topLabel.frame.size.height / 2 + 10 + SafeAreaTopHeight;//self.changeBtn.frame.size.height + self.topLabel.frame.size.height / 2 + 10;
    self.topLabel.center = topLabelCenter;
    self.topLabel.layer.cornerRadius = self.topLabel.frame.size.height / 2;
    self.topLabel.layer.masksToBounds = YES;

    //检测结果和保存成功提示label
    self.resultLabel.frame = CGRectMake(0, 0, 355 * ratio, 60 * ratio);
    CGPoint resultLabelCenter = center;
    resultLabelCenter.y -= self.squareView.squareFrame.size.height / 2 + self.resultLabel.frame.size.height / 2;
    self.resultLabel.center = resultLabelCenter;

    self.resultImageView.frame = CGRectMake(0, 0, self.squareView.squareFrame.size.width, self.squareView.squareFrame.size.height);
    self.resultImageView.center = center;

    if (self.phoneDirection == kVinPhoneDirectionUp) {
        self.scanLine.transform = CGAffineTransformMakeRotation(0);
        self.resultImageView.transform = CGAffineTransformMakeRotation(0);
        self.centerLabel.transform = CGAffineTransformMakeRotation(0);
        self.topLabel.transform = CGAffineTransformMakeRotation(0);
        self.resultLabel.transform = CGAffineTransformMakeRotation(0);
        self.backBtn.transform = CGAffineTransformMakeRotation(0);
        self.flashBtn.transform = CGAffineTransformMakeRotation(0);
    }else if (self.phoneDirection == kVinPhoneDirectionUpsideDown) {
        self.scanLine.transform = CGAffineTransformMakeRotation(M_PI);
        self.resultImageView.transform = CGAffineTransformMakeRotation(M_PI);
        self.centerLabel.transform = CGAffineTransformMakeRotation(M_PI);
        self.topLabel.transform = CGAffineTransformMakeRotation(M_PI);
        self.resultLabel.transform = CGAffineTransformMakeRotation(M_PI);
        self.backBtn.transform = CGAffineTransformMakeRotation(M_PI);
        self.flashBtn.transform = CGAffineTransformMakeRotation(M_PI);
    }
//    self.changeBtn.transform = CGAffineTransformMakeRotation(0);

    [self moveScanline];

}

- (void)clearSubViewsUp {

    [self.detectLayer removeFromSuperlayer];
    self.detectLayer = nil;

    [self.view removeGestureRecognizer:self.singleTap];

    [self.squareView removeFromSuperview];
    self.squareView = nil;
    [self.flashBtn removeFromSuperview];
    self.flashBtn = nil;
    [self.backBtn removeFromSuperview];
    self.backBtn = nil;
//    [self.changeBtn removeFromSuperview];
//    self.changeBtn = nil;
    [self.centerLabel removeFromSuperview];
    self.centerLabel = nil;
    [self.resultLabel removeFromSuperview];
    self.resultLabel = nil;
    [self.topLabel removeFromSuperview];
    self.topLabel = nil;
    [self.scanLine removeFromSuperview];
    self.scanLine = nil;
    [self.resultImageView removeFromSuperview];
    self.resultImageView = nil;
}


//计算检测视图层的空洞layer
- (CAShapeLayer *)getLayerWithHole {
    CGFloat offset = 1.0f;
    if ([UIScreen mainScreen].scale >= 2) {
        offset = 0.5;
    }

    CGRect topViewRect = self.squareView.squareFrame;

    CGRect centerRect = CGRectInset(topViewRect, -offset, -offset) ;
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(CGRectGetMinX(SCREENRECT), CGRectGetMinY(SCREENRECT))];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetMinX(SCREENRECT), CGRectGetMaxY(SCREENRECT))];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(SCREENRECT), CGRectGetMaxY(SCREENRECT))];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(SCREENRECT), CGRectGetMinY(SCREENRECT))];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetMinX(SCREENRECT), CGRectGetMinY(SCREENRECT))];
    [bezierPath moveToPoint:CGPointMake(CGRectGetMinX(centerRect), CGRectGetMinY(centerRect))];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetMinX(centerRect), CGRectGetMaxY(centerRect))];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(centerRect), CGRectGetMaxY(centerRect))];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(centerRect), CGRectGetMinY(centerRect))];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetMinX(centerRect), CGRectGetMinY(centerRect))];
    CAShapeLayer *layerWithHole = [CAShapeLayer layer];
    [layerWithHole setPath:bezierPath.CGPath];
    [layerWithHole setFillRule:kCAFillRuleEvenOdd];
    [layerWithHole setFillColor:[UIColor colorWithWhite:0 alpha:0.35].CGColor];

    return layerWithHole;

}

//监听对焦
-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"adjustingFocus"]){
        _isFocusing = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
    }
    if([keyPath isEqualToString:@"lensPosition"]){
        _FocusPixelsPosition = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
    }
}



- (void)didBecomeActive {
    [self performSelector:@selector(moveScanline)];
}


//移动扫描线
-(void)moveScanline{
    [self.scanLine setCenter:_linePoint];
    if (self.phoneDirection == kVinPhoneDirectionLeft) {
        [UIView animateWithDuration:2.5f delay:0.0f options:UIViewAnimationOptionRepeat animations:^{
            CGPoint center = _linePoint;
            center.x -= self.squareView.squareFrame.size.width;
            [self.scanLine setCenter:center];
        } completion:^(BOOL finished) {
        }];
    }else if (self.phoneDirection == kVinPhoneDirectionRight) {
        [UIView animateWithDuration:2.5f delay:0.0f options:UIViewAnimationOptionRepeat animations:^{
            CGPoint center = _linePoint;
            center.x += self.squareView.squareFrame.size.width;
            [self.scanLine setCenter:center];
        } completion:^(BOOL finished) {
        }];
    }else if(self.phoneDirection == kVinPhoneDirectionUp) {
        [UIView animateWithDuration:2.5f delay:0.0f options:UIViewAnimationOptionRepeat animations:^{
            CGPoint center = _linePoint;
            center.y += self.squareView.squareFrame.size.height;
            [self.scanLine setCenter:center];
        } completion:^(BOOL finished) {
        }];
    }else if (self.phoneDirection == kVinPhoneDirectionUpsideDown) {
        [UIView animateWithDuration:2.5f delay:0.0f options:UIViewAnimationOptionRepeat animations:^{
            CGPoint center = _linePoint;
            center.y -= self.squareView.squareFrame.size.height;
            [self.scanLine setCenter:center];
        } completion:^(BOOL finished) {
        }];
    }
}

#pragma mark - AVCaptureSession delegate
//从缓冲区获取图像数据进行识别
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);


    if(!_isFocusing){
        if (_isRecognize == YES) {
            if(_curPosition == _FocusPixelsPosition) {
                //开始识别
                int bSuccess = [_vinTyper recognizeVinTyper:baseAddress Width:(int)width Height:(int)height];
                //识别成功
                if(bSuccess == 0) {
                    //震动
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                    AudioServicesPlaySystemSound(_soundVinFileObject);
                    //显示区域图像
                    [self performSelectorOnMainThread:@selector(showResultAndImage:) withObject:_vinTyper.resultImg waitUntilDone:NO];
                    _isRecognize = NO;
                }
            }else{
                _curPosition=_FocusPixelsPosition;
            }
        }
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);

}

//显示结果跟图像
-(void)showResultAndImage:(UIImage *)image {
    self.resultImageView.image = image;
    self.resultLabel.text = _vinTyper.nsResult;
    self.centerLabel.text = @"";
    self.topLabel.hidden = NO;
    self.scanLine.hidden = YES;
    self.nsResult = [NSString stringWithFormat:@"%@",_vinTyper.nsResult];

    self.nsTimer =  [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(delayMethod) userInfo:nil repeats:NO];
}

- (void)delayMethod {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.plugin returnSuccess:self.nsResult callback:self.callback];
}

#pragma mark - Motion

- (void)startMotionManager{
    self.motionManager.deviceMotionUpdateInterval = 1 / 15.0;
    if (self.motionManager.deviceMotionAvailable) {
        //        NSLog(@"Device Motion Available");
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler: ^(CMDeviceMotion *motion, NSError *error){
            [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];

        }];
    } else {
        //        NSLog(@"No device motion on device.");
        [self setMotionManager:nil];
    }
}

- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion {

    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    double z = deviceMotion.gravity.z;
    //设置横竖屏识别的变化

//    NSLog(@"x:%.3lf，y:%.3lf，z:%lf",x,y,z);
    if (y < x && y<=-0.7 && z>-0.7) {
        //正竖屏
        if (self.phoneDirection != kVinPhoneDirectionUp) {
            NSLog(@"正");
            self.phoneDirection = kVinPhoneDirectionUp;
        }

    }else if(y >= x && y>0.6 && z>-0.7){
        //上下颠倒
        if (self.phoneDirection != kVinPhoneDirectionUpsideDown) {
            NSLog(@"倒");
            self.phoneDirection = kVinPhoneDirectionUpsideDown;
        }
    } else if(y < x && x>0.7 && z>-0.7){
        //右横屏
        if (self.phoneDirection != kVinPhoneDirectionRight) {
            NSLog(@"右");
            self.phoneDirection = kVinPhoneDirectionRight;
        }
    }else if (y >= x && x<=-0.6 && z > -0.7){
        //左横屏
        if (self.phoneDirection != kVinPhoneDirectionLeft) {
            NSLog(@"左");
            self.phoneDirection = kVinPhoneDirectionLeft;
        }
    }
}

#pragma mark - 点击事件

//返回按钮点击事件
- (void)backBtnClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}


//闪光灯按钮点击事件
- (void)flashBtnClick{

    if (!self.captureDevice.hasTorch) {
        //NSLog(@"no torch");
    }else{
        [self.captureDevice lockForConfiguration:nil];
        if(!_flash){
            [self.captureDevice setTorchMode: AVCaptureTorchModeOn];
            [self.flashBtn setImage:[UIImage imageNamed:@"VinImageResource.bundle/flash_off"] forState:UIControlStateNormal];
            _flash = YES;
        }
        else{
            [self.captureDevice setTorchMode: AVCaptureTorchModeOff];
            [self.flashBtn setImage:[UIImage imageNamed:@"VinImageResource.bundle/flash_on"] forState:UIControlStateNormal];
            _flash = NO;
        }
        [self.captureDevice unlockForConfiguration];
    }

}

//横屏 / 竖屏 切换
//- (void)changeBtnClick {
//
//    if (self.direction == kAudioDirectionHorizontal) {
//        self.direction = kAudioDirectionVertical;
//
//    }else{
//        self.direction = kAudioDirectionHorizontal;
//
//    }
//    _isRecognize = YES;
//    self.resultLabel.text = @"";
//    self.topLabel.hidden = YES;
//    self.centerLabel.text = @"将框置于VIN码前";
//    self.resultImageView.image = nil;
//    if (!self.captureSession.isRunning) {
//        [self.captureSession startRunning];
//    }
//    [self moveScanline];
//}

//单击手势
- (void)handleSingleFingerEvent:(UITapGestureRecognizer *)sender {
    if (sender.numberOfTapsRequired == 1) {
         [self.nsTimer invalidate];
        //单指单击
        _isRecognize = YES;
        self.resultLabel.text = @"";
        self.topLabel.hidden = YES;
        self.centerLabel.text = @"将框置于VIN码前";

        self.resultImageView.image = nil;
        self.scanLine.hidden = NO;
    }
    [self.captureSession startRunning];
}


- (AVCaptureDevice *)captureDevicePosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}


#pragma mark - 懒加载

#pragma mark - Setter
- (void)setIsHorizontal:(BOOL)isHorizontal {
    _isHorizontal = isHorizontal;
    [self clearSubViewsUp];

    [self prepareUI];

    [self setVinDetectArea];
}

- (void)setPhoneDirection:(VinPhoneDirection)phoneDirection {
    _phoneDirection = phoneDirection;
    _isRecognize = YES;
    if (_phoneDirection==kVinPhoneDirectionLeft) {
        self.isHorizontal = YES;
        [_vinTyper setVinRecognizeType:0];
    }else if (_phoneDirection==kVinPhoneDirectionRight){
        self.isHorizontal = YES;
        [_vinTyper setVinRecognizeType:2];
    }else if (_phoneDirection==kVinPhoneDirectionUp){
        self.isHorizontal = NO;
        [_vinTyper setVinRecognizeType:1];
    }else if (_phoneDirection==kVinPhoneDirectionUpsideDown){
        self.isHorizontal = NO;
        [_vinTyper setVinRecognizeType:3];
    }
}

#pragma mark - Getter

#pragma mark 相机相关

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        //创建会话层,视频浏览分辨率为1280*720
        _captureSession = [[AVCaptureSession alloc] init];
        [_captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    return _captureSession;
}

- (AVCaptureDeviceInput *)captureInput {
    if (!_captureInput) {
        _captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
    }
    return _captureInput;

}

- (AVCaptureStillImageOutput *)captureOutput {
    if (!_captureOutput) {
        //创建、配置输出
        _captureOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
        [_captureOutput setOutputSettings:outputSettings];
    }
    return _captureOutput;
}

- (AVCaptureVideoDataOutput *)captureDataOutput {
    if (!_captureDataOutput) {
        _captureDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _captureDataOutput.alwaysDiscardsLateVideoFrames = YES;
        dispatch_queue_t queue;
        queue = dispatch_queue_create("cameraQueue", NULL);
        [_captureDataOutput setSampleBufferDelegate:self queue:queue];
        NSString* formatKey = (NSString*)kCVPixelBufferPixelFormatTypeKey;
        NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
        NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:formatKey];
        [_captureDataOutput setVideoSettings:videoSettings];
    }
    return _captureDataOutput;
}

- (AVCaptureVideoPreviewLayer *)capturePreviewLayer {
    if (!_capturePreviewLayer) {
        _capturePreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
        _capturePreviewLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        _capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _capturePreviewLayer;
}

- (AVCaptureDevice *)captureDevice {
    if (!_captureDevice) {
        NSArray *deviceArr = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in deviceArr)
        {
            if (device.position == AVCaptureDevicePositionBack){
                _captureDevice = device;
                _captureInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            }
        }
    }
    return _captureDevice;
}

#pragma mark Motion
- (CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 1/15.0;
    }
    return _motionManager;
}


#pragma mark UI相关

- (UITapGestureRecognizer *)singleTap {
    if (!_singleTap) {
        _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleFingerEvent:)];

    }
    return _singleTap;
}


- (UIButton *)flashBtn {
    if (!_flashBtn) {
        _flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _flashBtn.tag = 1000;
        _flashBtn.hidden = NO;
        [_flashBtn setImage:[UIImage imageNamed:@"VinImageResource.bundle/flash_on"] forState:UIControlStateNormal];
        [_flashBtn addTarget:self action:@selector(flashBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashBtn;
}

- (UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _backBtn.tag = 1000;
        _backBtn.hidden = NO;
        [_backBtn setImage:[UIImage imageNamed:@"VinImageResource.bundle/back_btn"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (VinSquareView *)squareView {
    if (!_squareView) {
        _squareView = [[VinSquareView alloc] initWithIsHorizontal:self.isHorizontal];
        _squareView.backgroundColor = [UIColor clearColor];
    }
    return _squareView;
}

- (UILabel *)centerLabel {
    if (!_centerLabel) {
        _centerLabel = [[UILabel alloc] init];
        _centerLabel.text = @"将框置于VIN码前";
        _centerLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        _centerLabel.font = [UIFont fontWithName:@"Helvetica" size:15];
        _centerLabel.textColor = [UIColor whiteColor];
        _centerLabel.textAlignment = NSTextAlignmentCenter;

    }
    return _centerLabel;
}


- (UILabel *)topLabel {
    if (!_topLabel) {
        _topLabel = [[UILabel alloc] init];
        _topLabel.text = @"3秒后关闭，如果识别错误？点击屏幕重新识别";
        _topLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        _topLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        _topLabel.font = [UIFont fontWithName:@"Helvetica" size:15];
        _topLabel.textColor = [UIColor whiteColor];
        _topLabel.textAlignment = NSTextAlignmentCenter;

        _topLabel.hidden = YES;
    }
    return _topLabel;
}


- (UILabel *)resultLabel {
    if (!_resultLabel) {
        CGFloat ratio = SCREENH / 568.0;
        int nSize = 22;
        if(ratio>1.0) nSize = 30;
        _resultLabel = [[UILabel alloc] init];
        _resultLabel.text = @"";
        _resultLabel.font = [UIFont fontWithName:@"Helvetica" size:nSize];
        _resultLabel.textColor = [UIColor greenColor];
        _resultLabel.textAlignment = NSTextAlignmentCenter;

    }
    return _resultLabel;
}

- (UIImageView *)resultImageView {
    if (!_resultImageView) {
        _resultImageView = [[UIImageView alloc] init];
        _resultImageView.image = nil;

    }
    return _resultImageView;
}

- (UIImageView *)scanLine {
    if (!_scanLine) {
        CGFloat ratio = [self getRatio];
        if (_isHorizontal) {
            _scanLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.squareView.squareFrame.size.height, 3 * ratio)];
        }else{
            _scanLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.squareView.squareFrame.size.width, 3 * ratio)];
        }
        _scanLine.image = [UIImage imageNamed:@"VinImageResource.bundle/scan_line"];

        CGPoint center;
        center.x = SCREENW * 0.5;
        center.y = SCREENH * 0.5;
        CGPoint top = center;
        if (self.phoneDirection == kVinPhoneDirectionRight) {
            top.x -= self.squareView.squareFrame.size.width / 2;
        }else if(self.phoneDirection == kVinPhoneDirectionLeft){
            top.x += self.squareView.squareFrame.size.width / 2;
        }else if(self.phoneDirection == kVinPhoneDirectionUp){
            top.y -= self.squareView.squareFrame.size.height / 2;
        }else if(self.phoneDirection == kVinPhoneDirectionUpsideDown){
            top.y += self.squareView.squareFrame.size.height / 2;
        }
        [self.scanLine setCenter:top];
        _linePoint = self.scanLine.center;


    }
    return _scanLine;
}

//- (UIButton *)changeBtn {
//    if (!_changeBtn) {
//        _changeBtn = [[UIButton alloc] init];
//        _changeBtn.hidden = NO;
//        [_changeBtn setImage:[UIImage imageNamed:@"ImageResource.bundle/change_btn"] forState:UIControlStateNormal];
//        [_changeBtn addTarget:self action:@selector(changeBtnClick) forControlEvents:UIControlEventTouchUpInside];
//    }
//    return _changeBtn;
//}

- (CAShapeLayer *)detectLayer {
    if (!_detectLayer) {
        //设置检测视图层
        _detectLayer = [self getLayerWithHole];

    }
    return _detectLayer;
}

- (void)dealloc {
    NSLog(@"dealloc");
}

@end
