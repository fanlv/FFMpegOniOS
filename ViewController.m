//
//  ViewController.m
//  FFMpegOniOS
//
//  Created by Fan Lv on 2017/1/9.
//  Copyright © 2017年 Fanlv. All rights reserved.
//

#define SCREENBOUNDS                    [[UIScreen mainScreen] bounds];
#define SCREEN_HEIGHT                   [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH                    [[UIScreen mainScreen] bounds].size.width
#define DEVICE_IS_IPHONE4               ([[UIScreen mainScreen] bounds].size.height == 480)
#define DEVICE_IS_IPHONE5               ([[UIScreen mainScreen] bounds].size.height == 568)
#define DEVICE_IS_IPHONE6               ([[UIScreen mainScreen] bounds].size.height == 667)
#define DEVICE_IS_IPHONE6P              ([[UIScreen mainScreen] bounds].size.height == 736)
#define APP_Bundle_Identifier           [[NSBundle mainBundle] bundleIdentifier]
#define RGB(r,g,b)                      [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define RGBA(r,g,b,a)                   [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:a]


#define LERP(A,B,C) ((A)*(1.0-C)+(B)*C)

#import "ViewController.h"
#import "FLDecoder.h"


@interface ViewController ()
{
    FLDecoder *_flDecoder;
    UIImageView *_showView;
    UILabel *_timeLabel;
    UILabel *_fpsLabel;

}

@property (nonatomic, strong) NSTimer *nextFrameTimer;
@property (nonatomic, assign) float lastFrameTime;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _showView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
    _showView.backgroundColor = RGB(222, 222, 222);
    [self.view addSubview:_showView];
    
    _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, SCREEN_WIDTH, 70, 47)];
    _timeLabel.textColor = [UIColor blackColor];
    _timeLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:_timeLabel];
    
    _fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, SCREEN_WIDTH+100, 70, 47)];
    _fpsLabel.textColor = [UIColor blackColor];
    _fpsLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:_fpsLabel];

    
    UIButton *Btn = [[UIButton alloc] initWithFrame:CGRectMake(0, SCREEN_WIDTH+150, 100, 50)];
    Btn.backgroundColor = [UIColor blackColor];
    [Btn setTitle:@"播放" forState:UIControlStateNormal];
    [Btn addTarget:self action:@selector(gotopaly) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Btn];
    
    UIButton *Btn1 = [[UIButton alloc] initWithFrame:CGRectMake(110, SCREEN_WIDTH+150, 100, 50)];
    Btn1.backgroundColor = [UIColor blackColor];
    [Btn1 setTitle:@"暂停" forState:UIControlStateNormal];
    [Btn1 addTarget:self action:@selector(gotoPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Btn1];
    
    UIButton *Btn2 = [[UIButton alloc] initWithFrame:CGRectMake(110, SCREEN_WIDTH+150, 100, 50)];
    Btn2.backgroundColor = [UIColor blackColor];
    [Btn2 setTitle:@"停止" forState:UIControlStateNormal];
    [Btn2 addTarget:self action:@selector(gotoStop:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Btn1];
    
}
- (void)gotoStop:(UIButton *)sender
{
    [_nextFrameTimer invalidate];
    [sender setTitle:@"暂停" forState:UIControlStateNormal];


}
- (void)gotoPause:(UIButton *)sender
{
    sender.selected = !sender.selected;

    if (sender.selected)
    {
        [_nextFrameTimer invalidate];
        [sender setTitle:@"继续" forState:UIControlStateNormal];

    }
    else
    {
        self.nextFrameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/_flDecoder.fps//时间这样算还有问题
                                                               target:self
                                                             selector:@selector(displayNextFrame:)
                                                             userInfo:nil
                                                              repeats:YES];
        [sender setTitle:@"暂停" forState:UIControlStateNormal];


    }
    
}

- (void)gotopaly
{
    _lastFrameTime = -1;
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"你好" withExtension:@"ts"];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"cuc_ieschool" withExtension:@"flv"];

    NSString *fileUrl = [url absoluteString];
    //    NSString *fileUrl = @"rtmp://202.69.69.180:443/webcast/bshdlive-pc";//[url absoluteString]
    //    NSString *fileUrl = @"http://live.hkstv.hk.lxdns.com/live/hks/playlist.m3u8";
    
    
    _flDecoder = [[FLDecoder alloc] initWithVideo:fileUrl];
    
    [_nextFrameTimer invalidate];
    if (_flDecoder) {
        
        _showView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH*_flDecoder.sourceHeight/_flDecoder.sourceWidth);
        self.nextFrameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/_flDecoder.fps
                                                               target:self
                                                             selector:@selector(displayNextFrame:)
                                                             userInfo:nil
                                                              repeats:YES];
    }

}

- (void)viewWillAppear:(BOOL)animated
{
 
}

- (void)viewDidDisappear:(BOOL)animated {
    [_nextFrameTimer invalidate];
    self.nextFrameTimer = nil;
}



-(void)displayNextFrame:(NSTimer *)timer
{
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];

    _timeLabel.text  = [self dealTime:_flDecoder.currentTime];
    if (![_flDecoder stepFrame]) {
        [timer invalidate];
        _showView.image = nil;
        return;
    }
    _showView.image = _flDecoder.currentImage;
    

    float frameTime = 1.0 / ([NSDate timeIntervalSinceReferenceDate] - startTime);
    if (_lastFrameTime < 0) {
        _lastFrameTime = frameTime;
    } else {
        _lastFrameTime = LERP(frameTime, _lastFrameTime, 0.8);
    }
    [_fpsLabel setText:[NSString stringWithFormat:@"fps %.0f",_lastFrameTime]];
}

- (NSString *)dealTime:(double)time {
    
    int tns, thh, tmm, tss;
    tns = time;
    thh = tns / 3600;
    tmm = (tns % 3600) / 60;
    tss = tns % 60;
    
    
    //        [ImageView setTransform:CGAffineTransformMakeRotation(M_PI)];
    return [NSString stringWithFormat:@"%02d:%02d:%02d",thh,tmm,tss];
}





@end
