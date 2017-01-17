//
//  RecordViewController.m
//  FFMpegOniOS
//
//  Created by Fan Lv on 2017/1/17.
//  Copyright © 2017年 Fanlv. All rights reserved.
//

#import "RecordViewController.h"
#import "FLCameraHelp.h"


#define SCREEN_HEIGHT                   [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH                    [[UIScreen mainScreen] bounds].size.width

@interface RecordViewController ()<FLCameraHelpDelegate>
@property (nonatomic, strong) FLCameraHelp *flCameraHelp;

@end

@implementation RecordViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

//    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 120 -20, SCREEN_HEIGHT - 160 - 50 , 120, 160)];
//    view.backgroundColor = [UIColor whiteColor];
//    [self.view addSubview:view];

    
    _flCameraHelp = [[FLCameraHelp alloc] init];
    [_flCameraHelp embedPreviewInView:self.view];
    [_flCameraHelp changePreviewOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    _flCameraHelp.delegate = self;
    [_flCameraHelp startRunning];

}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    

    [_flCameraHelp stopRunning];
    _flCameraHelp.delegate = nil;
    _flCameraHelp = nil;
    
}


#pragma mark - CaptureManagerDelegate



- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"sampleBuffer :%@",sampleBuffer);
}







@end
