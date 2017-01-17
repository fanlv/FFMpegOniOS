//
//  RecordViewController.m
//  FFMpegOniOS
//
//  Created by Fan Lv on 2017/1/17.
//  Copyright © 2017年 Fanlv. All rights reserved.
//

#import "RecordViewController.h"
#import "FLCameraHelp.h"
#import "X264Manager.h"

#define SCREEN_HEIGHT                   [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH                    [[UIScreen mainScreen] bounds].size.width

@interface RecordViewController ()<FLCameraHelpDelegate>
{
    CGSize                           videoSize;
    UIView *view;
}
@property (nonatomic, strong) FLCameraHelp *flCameraHelp;
@property (nonatomic, strong) X264Manager *manager264;

@end

@implementation RecordViewController
@synthesize manager264;

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *path = [self savedFilePath];
    bool ret = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];

    self.view.backgroundColor = [UIColor whiteColor];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 120 -20, SCREEN_HEIGHT - 160 - 50 , 120, 160)];
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];
    
    
    
    UIButton *Btn = [[UIButton alloc] initWithFrame:CGRectMake(10, SCREEN_WIDTH+150, 100, 50)];
    Btn.backgroundColor = [UIColor blackColor];
    [Btn setTitle:@"录制" forState:UIControlStateNormal];
    [Btn addTarget:self action:@selector(recordVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Btn];
    
    UIButton *Btn1 = [[UIButton alloc] initWithFrame:CGRectMake(120, SCREEN_WIDTH+150, 100, 50)];
    Btn1.backgroundColor = [UIColor blackColor];
    [Btn1 setTitle:@"返回" forState:UIControlStateNormal];
    [Btn1 addTarget:self action:@selector(goback) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Btn1];

    
  


}
- (void)goback
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)recordVideo:(UIButton *)button
{
    button.selected = !button.selected;
    
    if (button.selected) {
        
        NSLog(@"recordVideo....");
        
        _flCameraHelp = [[FLCameraHelp alloc] initWithPreset:AVCaptureSessionPreset1280x720];
        
        [_flCameraHelp embedPreviewInView:view];
        [_flCameraHelp changePreviewOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        _flCameraHelp.delegate = self;
        
        videoSize = [self getVideoSize:_flCameraHelp.session.sessionPreset];

        manager264 = [[X264Manager alloc]init];
        [manager264 setFileSavedPath:[self savedFilePath]];
        [manager264 setX264ResourceWithVideoWidth:videoSize.width height:videoSize.height bitrate:1500000];
        
        [_flCameraHelp startRunning];
    } else {
        
        NSLog(@"stopRecord!!!");
        
        [_flCameraHelp stopRunning];
        _flCameraHelp.delegate = nil;
        _flCameraHelp = nil;
        
        [manager264 freeX264Resource];
        manager264 = nil;
        
    }
}

- (void)playVedio
{
    
}




- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    

   

    
}


#pragma mark - CaptureManagerDelegate



- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    NSLog(@"sampleBuffer :%@",sampleBuffer);
    
    
    // 这里的sampleBuffer就是采集到的数据了，但它是Video还是Audio的数据，得根据connection来判断
//    if (connection == _flCameraHelp.captureOutput)
    {
        // Video
        NSLog(@"在这里获得video sampleBuffer，做进一步处理（编码H.264）");
#if encodeModel
        // encode
        [manager264 encoderToH264:sampleBuffer];
#else
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
         int pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
         switch (pixelFormat) {
             case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
                 NSLog(@"Capture pixel format=NV12");
                 break;
             case kCVPixelFormatType_422YpCbCr8:
                 NSLog(@"Capture pixel format=UYUY422");
                 break;
             default:
                 NSLog(@"Capture pixel format=RGB32");
                 break;
         }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
//        // render
//        [openglView render:pixelBuffer];
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
#endif
    }
    //    else if (connection == _audioConnection) {
    //        
    //        // Audio
    //        NSLog(@"这里获得audio sampleBuffer，做进一步处理（编码AAC）");
    //    }
    

}





#pragma mark - 生成文件名称和位置


- (CGSize)getVideoSize:(NSString *)sessionPreset {
    CGSize size = CGSizeZero;
    if ([sessionPreset isEqualToString:AVCaptureSessionPresetMedium]) {
        size = CGSizeMake(480, 360);
    } else if ([sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        size = CGSizeMake(1920, 1080);
    } else if ([sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        size = CGSizeMake(1280, 720);
    } else if ([sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
        size = CGSizeMake(640, 480);
    }
    
    return size;
}



// 当前系统时间
- (NSString* )nowTime2String
{
    NSString *date = nil;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYY-MM-dd hh:mm:ss";
    date = [formatter stringFromDate:[NSDate date]];
    
    return date;
}

- (NSString *)savedFileName
{
    return [@"fanlv" stringByAppendingString:@".h264"];
}


- (NSString *)savedFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *fileName = [self savedFileName];
    
    NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    return writablePath;
}



@end
