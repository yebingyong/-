#import "PlateCameraController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreMedia/CoreMedia.h>
#import "PlateSquareView.h"
#import "SPlate.h"
#include "AppDelegate.h"

#define AUTHCODE @"66A26DF01048DD276FA6"

//顶部安全区
#define SafeAreaTopHeight (SCREENH == 812.0 ? 34 : 10)
//底部
#define SafeAreaBottomHeight (SCREENH == 812.0 ? 34 : 0)

#define SCREENH [UIScreen mainScreen].bounds.size.height
#define SCREENW [UIScreen mainScreen].bounds.size.width
#define SCREENRECT [UIScreen mainScreen].bounds

@interface PlateCameraController ()<UIAlertViewDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIButton * flashButton;

@property (nonatomic, strong) UIButton * backButton;

@property (strong ,nonatomic) UILabel * slideValuelabel;
@property (strong ,nonatomic) UISlider * resizeSlider;
@property (strong ,nonatomic) UILabel * sliderTipLabel;

@property (nonatomic, strong) UILabel * centerTipLabel;

@property (nonatomic, strong) UILabel * resultLabel;

@property (nonatomic, strong) UILabel * topLabel;

@property (nonatomic, strong) UIImageView * resultImageView;

@property (nonatomic, strong) PlateSquareView * squareView;    //方框View

@property (nonatomic, strong) UITapGestureRecognizer * singleTap;

//相机相关
@property (nonatomic, strong) AVCaptureSession * captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput * captureInput;
@property (nonatomic, strong) AVCaptureStillImageOutput * captureOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * captureDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * capturePreviewLayer;
@property (nonatomic, strong) AVCaptureDevice * captureDevice;

@property (nonatomic, retain) PlateCode*       plugin;
@property (nonatomic, retain) NSString*        callback;
@property (nonatomic, retain) NSTimer*         nsTimer;
@property (nonatomic, retain) NSString*        nsResult;
@property (nonatomic, retain) NSString*        nsColor;
@end

@interface PlateCode ()

@property (nonatomic, strong) CDVInvokedUrlCommand * command;
@property (nonatomic, retain) NSString*              callback;

@end

@implementation PlateCode

//视频流获取车牌
- (void)scan : (CDVInvokedUrlCommand *)command
{
    NSString*       callback;
    callback = command.callbackId;
    //ios 9以下会出现问题所以先放在主线程中
    //[self.commandDelegate runInBackground:^{
    PlateCameraController * myCameraVC = [[PlateCameraController alloc] initWithAuthorizationCode:AUTHCODE plugin:self callback:callback];
    [self.viewController presentViewController:myCameraVC animated:YES completion:nil];
    //}];
}

- (void)returnSuccess:(NSString*)scannedText color:(NSString*)color callback:(NSString*)callback{
    
    NSMutableDictionary* resultDict = [[[NSMutableDictionary alloc] init] init];
    [resultDict setObject:scannedText     forKey:@"plate"];
    [resultDict setObject:color           forKey:@"color"];
    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_OK
                               messageAsDictionary: resultDict
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

@implementation PlateCameraController {
    
    NSString * _authorizationCode;   //授权码 / 授权文件名
    
    SPlate *_sPlate; //识别核心
    
    BOOL _isCameraAuthor; //是否有打开摄像头权限
    BOOL _isRecognize; //是否识别
    BOOL _flash; //控制闪光灯
    NSTimer *_timer; //定时器
    BOOL _isTransform;
    BOOL _isFocusing;//是否正在对焦
    BOOL _isFocusPixels;//是否相位对焦
    GLfloat _FocusPixelsPosition;//相位对焦下镜头位置
    GLfloat _curPosition;//当前镜头位置
    
}

@synthesize plugin               = _plugin;
@synthesize callback             = _callback;
@synthesize nsTimer              = _nsTimer;
@synthesize nsResult             = _nsResult;
@synthesize nsColor              = _nsColor;

SystemSoundID _soundPlateFileObject;

- (id)initWithAuthorizationCode:(NSString *)authorizationCode plugin:(PlateCode*)plugin callback:(NSString*)callback{
    if (self = [super init]) {
        _authorizationCode = authorizationCode;
    }
    self.plugin               = plugin;
    self.callback             = callback;
    
    CFURLRef soundFileURLRef  = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("PlateImageResource.bundle/plate"), CFSTR ("caf"), NULL);
    AudioServicesCreateSystemSoundID(soundFileURLRef, &_soundPlateFileObject);
    
    
    return self;
}

#pragma mark - Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBarHidden = YES;
    
    //初始化识别核心
    [self performSelectorInBackground:@selector(initRecogKernal) withObject:nil];
    //初始化相机和视图层
    [self initCameraAndLayer];
    
    [self prepareUI];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _isRecognize = YES;
    _isFocusPixels = NO;
    
    //判断是否相位对焦
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        AVCaptureDeviceFormat * deviceFormat = self.captureDevice.activeFormat;
        if (deviceFormat.autoFocusSystem == AVCaptureAutoFocusSystemPhaseDetection){
            _isFocusPixels = YES;
        }
    }
    //    AVCaptureDevice*camDevice =[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //注册通知
    [self.captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
    if (_isFocusPixels) {
        [self.captureDevice addObserver:self forKeyPath:@"lensPosition" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    //初始化识别核心
    int nRet = [_sPlate initSPlate:_authorizationCode nsReserve:@""];
    if ([self.delegate respondsToSelector:@selector(initPlateWithResult:)]) {
        [self.delegate initPlateWithResult:nRet];
    }
    if (nRet != 0) {
        if (_isCameraAuthor == NO) {
            [self.captureSession stopRunning];
            NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
            NSArray * appleLanguages = [defaults objectForKey:@"AppleLanguages"];
            NSString * systemLanguage = [appleLanguages objectAtIndex:0];
            if (![systemLanguage isEqualToString:@"zh-Hans"]) {
                NSString *initStr = [NSString stringWithFormat:@"Init Error!Error code:%d",nRet];
                UIAlertView *alertV = [[UIAlertView alloc] initWithTitle:@"Tips" message:initStr delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertV show];
            }else{
                NSString *initStr = [NSString stringWithFormat:@"初始化失败!错误代码:%d",nRet];
                UIAlertView *alertV = [[UIAlertView alloc] initWithTitle:@"提示" message:initStr delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertV show];
            }
        }
    }
    if(![self.captureSession isRunning]){
        [self.captureSession startRunning];
        //        self.resultLabel.text = @"";
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _isRecognize = NO;
    [self.captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    if (_isFocusPixels) {
        [self.captureDevice removeObserver:self forKeyPath:@"lensPosition"];
    }
    [self.captureSession stopRunning];
    //释放核心
    [_sPlate freeSPlate];
    AudioServicesRemoveSystemSoundCompletion(_soundPlateFileObject);
    AudioServicesDisposeSystemSoundID(_soundPlateFileObject);
    self.callback = nil;
    self.plugin = nil;
    self.nsTimer = nil;
    self.nsColor = nil;
    self.nsResult = nil;
}

#pragma mark - 初始化

//隐藏状态栏
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}


//初始化识别核心
- (void)initRecogKernal {
    _sPlate = [[SPlate alloc] init];
}

//初始化相机和检测视图层
- (void)initCameraAndLayer {
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
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice * device in devices) {
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
    
    //设置检测视图层
    CAShapeLayer *layerWithHole = [CAShapeLayer layer];
    
    CGFloat offset = 1.0f;
    if ([UIScreen mainScreen].scale >= 2) {
        offset = 0.5;
    }
    
    
    
    CGRect centerFrame = self.squareView.squareFrame;
    CGRect centerRect = CGRectInset(centerFrame, -offset, -offset) ;
    
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
    [layerWithHole setPath:[bezierPath CGPath]];
    [layerWithHole setFillRule:kCAFillRuleEvenOdd];
    [layerWithHole setFillColor:[UIColor colorWithWhite:0 alpha:0.35].CGColor];
    [self.view.layer addSublayer:layerWithHole];
    [self.view.layer setMasksToBounds:YES];
    
    
    //判断是否相位对焦
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        AVCaptureDeviceFormat *deviceFormat = _captureDevice.activeFormat;
        if (deviceFormat.autoFocusSystem == AVCaptureAutoFocusSystemPhaseDetection){
            _isFocusPixels = YES;
        }
    }
    //设置检测范围(是横屏的值)
    //因为传参需要横屏的数值,所以计算横屏的x,y,height,width
    CGFloat x,y,h,w;
    x = self.squareView.squareFrame.origin.y;
    y = self.squareView.squareFrame.origin.x;
    h = self.squareView.squareFrame.size.width;
    w = self.squareView.squareFrame.size.height;
    
    //计算参数
    int left,top,right,bottom;
    left = x / SCREENH * 1920;
    top = y / SCREENW * 1080;
    right = (x + w) / SCREENH * 1920;
    bottom = (y + h) / SCREENW * 1080;
    
    NSLog(@"left:%d,top:%d,right:%d,bottom:%d",left,top,right,bottom);
//    [_sPlate setRegionWithLeft:622 Top:0 Right:1298 Bottom:1080];
    [_sPlate setRegionWithLeft:left Top:top Right:right Bottom:bottom];
    
    _beginGestureScale = 1.0;
    _effectiveScale = 1.0;
}


- (void)prepareUI {
    
    [self.view addGestureRecognizer:self.singleTap];
    
    
    [self.view addSubview:self.squareView];
    
    
    [self.view addSubview:self.flashButton];
    
    [self.view addSubview:self.backButton];
    
    
    [self.view addSubview:self.centerTipLabel];
    
    [self.view addSubview:self.topLabel];
    
    [self.view addSubview:self.resultLabel];
    
    
    [self.view addSubview:self.resizeSlider];
    
    [self.view addSubview:self.slideValuelabel];
    
    [self.view addSubview:self.sliderTipLabel];
    
    
    [self.view addSubview:self.resultImageView];
    
    
    
    [self frameSetup];
    
    
}


- (void)frameSetup {
    CGFloat ratio = 1;
    
    if (SCREENW < 400) {
        ratio = SCREENW / 414.;
    }
    
    CGFloat width;
    width = 60 * ratio;
    self.backButton.frame = CGRectMake(10, SafeAreaTopHeight, width, width);
    
    self.flashButton.frame = CGRectMake(SCREENW - width - 10, SafeAreaTopHeight, width, width);
    
    
    CGPoint center = CGPointMake(SCREENW * 0.5, SCREENH * 0.5);
    
    self.resizeSlider.frame = CGRectMake(0, 0, SCREENW - 40, 20);
    CGPoint sliderCenter = center;
    sliderCenter.y = SCREENH - 60 - SafeAreaBottomHeight;
    [self.resizeSlider setCenter:sliderCenter];
    
    
    self.slideValuelabel.frame = CGRectMake(0, 0, 320, 20);
    CGPoint valueCenter = center;
    valueCenter.y = SCREENH - 80 - SafeAreaBottomHeight;
    [self.slideValuelabel setCenter:valueCenter];
    
    
    self.sliderTipLabel.frame = CGRectMake(0, 0, 320, 60);
    CGPoint sliderTipCenter = center;
    sliderTipCenter.y = SCREENH - 30 - SafeAreaBottomHeight;
    [self.sliderTipLabel setCenter:sliderTipCenter];
    
    
    self.centerTipLabel.frame = CGRectMake(0, 0, 210, 40);
    self.centerTipLabel.center = center;
    self.centerTipLabel.layer.cornerRadius = self.centerTipLabel.frame.size.height * 0.5;
    self.centerTipLabel.layer.masksToBounds = YES;
    
    
    self.resultLabel.frame = CGRectMake(0, 0, 320, 120);
    CGPoint resultLabelCenter = center;
    resultLabelCenter.y = self.squareView.squareFrame.origin.y + self.resultLabel.frame.size.height / 2;
    [self.resultLabel setCenter:resultLabelCenter];
    
    self.resultImageView.frame = CGRectMake(0, 0, 200, 40);
    CGPoint resultImageVCenter = center;
    resultImageVCenter.y = center.y + self.resultLabel.frame.size.height / 2;
    [self.resultImageView setCenter:resultImageVCenter];
    
    self.topLabel.frame = CGRectMake(0, 0, 320, 60);
    CGPoint topLabelCenter = center;
    topLabelCenter.y = self.squareView.squareFrame.origin.y/2;
    [self.topLabel setCenter:topLabelCenter];
    
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"adjustingFocus"]){
        _isFocusing =[[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
    }
    if([keyPath isEqualToString:@"lensPosition"]){
        _FocusPixelsPosition =[[change objectForKey:NSKeyValueChangeNewKey] floatValue];
    }
}

//从缓冲区获取图像数据进行识别
#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    UIImage *srcimage = [self imageFromSampleBuffer:sampleBuffer];
    self.resultImg = nil;
    if(srcimage.size.width != 1920){
        [self.captureSession beginConfiguration];
        [self.captureSession setSessionPreset:AVCaptureSessionPreset1920x1080];
        [self.captureSession commitConfiguration];
    }else{
        if (_isRecognize == YES) {
            if(self.effectiveScale != 1.0){
                srcimage = [self cutImage:srcimage];
            }
            //开始识别
            int bSuccess = [_sPlate recognizeSPlateImage:srcimage Type:1];
            if(bSuccess == 0) {
                //震动
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                AudioServicesPlaySystemSound(_soundPlateFileObject);
                //显示区域图像
                [self performSelectorOnMainThread:@selector(showResultAndImage:) withObject:_sPlate.plateImg waitUntilDone:NO];
                _isRecognize = NO;
            }
        }
    }
    
}



//显示结果跟图像
-(void)showResultAndImage:(UIImage *)image {
    [self.resultImageView setImage:image];
    //NSString *nsResult = [NSString stringWithFormat:@"%@\n%@",_sPlate.nsPlateNo,_sPlate.nsPlateColor];
    //颜色识别太差故不显示颜色结果
    NSString *nsResult = [NSString stringWithFormat:@"%@",_sPlate.nsPlateNo];
    self.resultLabel.text = nsResult;
    self.centerTipLabel.hidden = YES;
    
    self.nsResult = [NSString stringWithFormat:@"%@",_sPlate.nsPlateNo];
    self.nsColor = [NSString stringWithFormat:@"%@",_sPlate.nsPlateColor];
    
    self.topLabel.text = @"3秒后关闭，如果识别错误？点击屏幕重新识别";
    if (self.resultImg) {
        self.resultImg = nil;
    }
    
    self.nsTimer =  [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(delayMethod) userInfo:nil repeats:NO];
}

- (void)delayMethod {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.plugin returnSuccess:self.nsResult color:self.nsColor callback:self.callback];
}

#pragma mark - 点击事件

//闪光灯按钮点击事件
- (void)flashClick {
    
    if (![self.captureDevice hasTorch]) {
        //NSLog(@"no torch");
    }else{
        [self.captureDevice lockForConfiguration:nil];
        if(!_flash){
            [self.captureDevice setTorchMode: AVCaptureTorchModeOn];
            [self.flashButton setImage:[UIImage imageNamed:@"PlateImageResource.bundle/flash_off"] forState:UIControlStateNormal];
            _flash = YES;
        }else{
            [self.captureDevice setTorchMode: AVCaptureTorchModeOff];
            [self.flashButton setImage:[UIImage imageNamed:@"PlateImageResource.bundle/flash_on"] forState:UIControlStateNormal];
            _flash = NO;
        }
        [self.captureDevice unlockForConfiguration];
    }
    
}

//返回按钮点击事件
- (void)backClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}


//单击手势
- (void)handleSingleFingerEvent:(UITapGestureRecognizer *)sender {
    if (sender.numberOfTapsRequired == 1) {
        [self.nsTimer invalidate];
        //单指单击
        _isRecognize = YES;
        self.resultLabel.text = @"";
        self.topLabel.text = @"";
        self.centerTipLabel.hidden = NO;
        [self.resultImageView setImage:nil];
    }
}


- (AVCaptureDevice *)captureDevicePosition:(AVCaptureDevicePosition)position {
    NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice * device in devices) {
        if (device.position == position){
            return device;
        }
    }
    return nil;
}


- (void)sliderValueChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
    _effectiveScale = slider.value;
    self.slideValuelabel.text = [NSString stringWithFormat:@"%.1f x", slider.value];
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    [self.capturePreviewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
    [CATransaction commit];
}

#pragma mark - 图像处理

-(UIImage*)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // Get a CMSampleBuffer‘s Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationUp];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    //    image = [PlateCameraViewController image:image rotation:UIImageOrientationRight];
    return (image);
}

#pragma mark 旋转图像
+ (UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation {
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width / rect.size.height;
            scaleX = rect.size.height / rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width / rect.size.height;
            scaleX = rect.size.height / rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
    UIImage * newPic = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newPic;
}

-(UIImage*)image:(UIImage *)image scaleToSize:(CGSize)size {
    
    // 得到图片上下文，指定绘制范围
    UIGraphicsBeginImageContext(size);
    
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(),kCGInterpolationHigh);
    // 将图片按照指定大小绘制
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    // 从当前图片上下文中导出图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 当前图片上下文出栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}

-(UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect {
    //按照给定的矩形区域进行剪裁
    CGImageRef newImageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    //将CGImageRef转换成UIImage
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    //返回剪裁后的图片
    return newImage;
}

-(UIImage *)cutImage:(UIImage *)image {
    int nW = image.size.width;
    int nH = image.size.height;
    CGRect cutRect = CGRectMake(nW / (self.effectiveScale * 2), nH / (self.effectiveScale * 2), nW / self.effectiveScale, nH / self.effectiveScale);
    image = [self imageFromImage:image inRect:cutRect];
    image = [self image:image scaleToSize:CGSizeMake(nW, nH)];
    return image;
}



#pragma mark - 懒加载

#pragma mark 相机相关

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        //创建会话层
        _captureSession = [[AVCaptureSession alloc] init];
        [_captureSession setSessionPreset:AVCaptureSessionPreset1920x1080];
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


#pragma mark UI

- (UITapGestureRecognizer *)singleTap {
    if (!_singleTap) {
        _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleFingerEvent:)];
        _singleTap.numberOfTouchesRequired = 1; //手指数
        _singleTap.numberOfTapsRequired = 1; //tap次数
    }
    return _singleTap;
}


- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[UIImage imageNamed:@"PlateImageResource.bundle/back_btn"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)flashButton {
    if (!_flashButton) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flashButton setImage:[UIImage imageNamed:@"PlateImageResource.bundle/flash_on"] forState:UIControlStateNormal];
        [_flashButton addTarget:self action:@selector(flashClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashButton;
}

- (UILabel *)slideValuelabel {
    if (!_slideValuelabel) {
        _slideValuelabel = [[UILabel alloc] init];
        _slideValuelabel.text = @"1.0 x";
        _slideValuelabel.numberOfLines = 0;
        _slideValuelabel.font = [UIFont fontWithName:@"Helvetica" size:20];
        _slideValuelabel.textColor = [UIColor greenColor];
        _slideValuelabel.textAlignment = NSTextAlignmentCenter;
    }
    return _slideValuelabel;
}

- (UISlider *)resizeSlider {
    if (!_resizeSlider) {
        _resizeSlider = [[UISlider alloc] init];
        _resizeSlider.minimumValue = 1.0;// 设置最小值
        _resizeSlider.maximumValue = 3.0;// 设置最大值
        _resizeSlider.value = 1.0;// 设置初始值
        _resizeSlider.continuous = YES;// 设置可连续变化
        [_resizeSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _resizeSlider;
}

- (UILabel *)sliderTipLabel {
    if (!_sliderTipLabel) {
        _sliderTipLabel = [[UILabel alloc] init];
        _sliderTipLabel.text = @"拖动滑动条可调整拍摄距离";
        _sliderTipLabel.numberOfLines = 0;
        _sliderTipLabel.font = [UIFont fontWithName:@"Helvetica" size:15];
        _sliderTipLabel.textColor = [UIColor whiteColor];
        _sliderTipLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _sliderTipLabel;
}

- (UILabel *)centerTipLabel {
    if (!_centerTipLabel) {
        _centerTipLabel = [[UILabel alloc] init];
        _centerTipLabel.text = @"请将车牌置于框内";
        _centerTipLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        _centerTipLabel.font = [UIFont fontWithName:@"Helvetica" size:15];
        _centerTipLabel.textColor = [UIColor whiteColor];
        _centerTipLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _centerTipLabel;
}


- (UILabel *)resultLabel {
    if (!_resultLabel) {
        _resultLabel = [[UILabel alloc] init];
        _resultLabel.text = @"";
        _resultLabel.numberOfLines = 0;
        _resultLabel.font = [UIFont fontWithName:@"Helvetica" size:45];
        _resultLabel.textColor = [UIColor greenColor];
        _resultLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _resultLabel;
}

- (UILabel *)topLabel {
    if (!_topLabel) {
        _topLabel = [[UILabel alloc] init];
        _topLabel.text = @"";
        _topLabel.font = [UIFont fontWithName:@"Helvetica" size:15];
        _topLabel.textColor = [UIColor whiteColor];
        _topLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _topLabel;
}

- (UIImageView *)resultImageView {
    if (!_resultImageView) {
        _resultImageView = [[UIImageView alloc] init];
    }
    return _resultImageView;
}

- (PlateSquareView *)squareView {
    if (!_squareView) {
        _squareView = [[PlateSquareView alloc] initWithFrame:SCREENRECT];
        _squareView.backgroundColor = [UIColor clearColor];
    }
    return _squareView;
}

@end
