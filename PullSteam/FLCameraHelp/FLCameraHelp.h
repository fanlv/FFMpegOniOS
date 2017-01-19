//
//  FLCameraHelp.h
//  Droponto
//
//  Created by Fan Lv on 14-5-22.
//  Copyright (c) 2014年 Haoqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


// 1 : 编码模式
// 0 : 渲染模式，当前只能渲染 32BGRA，后续增加 NV12 的渲染支持
// 将 encodeModel 设置为1，就是编码采集到视频数据；将 encodeModel 设置为0，就是渲染采集到的视频数据
#define encodeModel 1


@protocol FLCameraHelpDelegate <NSObject>

@optional
- (void)didFinishedCapture:(UIImage *)img;
- (void)foucusStatus:(BOOL)isadjusting;
-(void)onOutputDataSteam:(NSData *)data;
-(void)onOutputImageSteam:(UIImage *)image;
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

@end


@interface FLCameraHelp : NSObject

@property (nonatomic) AVCaptureConnection *vedioConnection;
@property (nonatomic) AVCaptureConnection *audioConnection;


@property (strong,nonatomic) AVCaptureSession *session;
@property (strong,nonatomic) AVCaptureStillImageOutput *captureOutput;

@property (assign,nonatomic) id<FLCameraHelpDelegate>delegate;

- (id)initWithPreset:(NSString *)preset;

///开始使用摄像头取景
- (void) startRunning;

///停止使用摄像头取景
- (void) stopRunning;

///拍照
-(void)captureStillImage;

///把摄像头取景的图像添到aView上显示
- (void)embedPreviewInView: (UIView *) aView;

///改变摄像头方向
- (void)changePreviewOrientation:(UIInterfaceOrientation)interfaceOrientation;

///切换前后摄像头
- (BOOL)switchCamera;

///设置闪光点灯模式
- (void)setFlashLightMode:(int)mode;

@end
