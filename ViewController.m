//
//  ViewController.m
//  FFMpegOniOS
//
//  Created by Fan Lv on 2017/1/9.
//  Copyright © 2017年 Fanlv. All rights reserved.
//



#define LERP(A,B,C) ((A)*(1.0-C)+(B)*C)


#import "Constants.h"
#import "ViewController.h"
#import "FLDecoder.h"
#import "OpenGLView20.h"
#import "KxMovieViewController.h"
#import "RecordViewController.h"
//#import <IJKMediaFramework/IJKFFMoviePlayerController.h>


#include <libavutil/mathematics.h>
#include <libavutil/time.h>
#include <libavformat/avformat.h>



@interface ViewController ()
{
    FLDecoder *_flDecoder;
    OpenGLView20 *_showView;
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
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    
    _showView = [[OpenGLView20 alloc] initWithFrame:self.view.bounds];
    _showView.backgroundColor = RGB(222, 222, 222);
    [self.view addSubview:_showView];
    
    _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, SCREEN_WIDTH, 100, 47)];
    _timeLabel.textColor = [UIColor blackColor];
    _timeLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:_timeLabel];
    
    _fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, SCREEN_WIDTH+100, 70, 47)];
    _fpsLabel.textColor = [UIColor blackColor];
    _fpsLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:_fpsLabel];

    
    UIButton *Btn = [[UIButton alloc] initWithFrame:CGRectMake(10, SCREEN_WIDTH+150, 100, 50)];
    Btn.backgroundColor = [UIColor blackColor];
    [Btn setTitle:@"kxmovie" forState:UIControlStateNormal];
    [Btn addTarget:self action:@selector(gotoKxmoviePaly) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Btn];
    
    UIButton *Btn1 = [[UIButton alloc] initWithFrame:CGRectMake(120, SCREEN_WIDTH+150, 100, 50)];
    Btn1.backgroundColor = [UIColor blackColor];
    [Btn1 setTitle:@"暂停" forState:UIControlStateNormal];
    [Btn1 addTarget:self action:@selector(gotoPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Btn1];
    
//    UIButton *Btn2 = [[UIButton alloc] initWithFrame:CGRectMake(120, SCREEN_WIDTH+150, 100, 50)];
//    Btn2.backgroundColor = [UIColor blackColor];
//    [Btn2 setTitle:@"停止" forState:UIControlStateNormal];
//    [Btn2 addTarget:self action:@selector(gotoStop:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:Btn2];
    
    UIButton *Btn3 = [[UIButton alloc] initWithFrame:CGRectMake(230, SCREEN_WIDTH+150, 100, 50)];
    Btn3.backgroundColor = [UIColor blackColor];
    [Btn3 setTitle:@"全屏" forState:UIControlStateNormal];
    [Btn3 addTarget:self action:@selector(showFullScreen:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Btn3];
    
    UIButton *Btn4 = [[UIButton alloc] initWithFrame:CGRectMake(10, SCREEN_WIDTH+210, 100, 50)];
    Btn4.backgroundColor = [UIColor blackColor];
    [Btn4 setTitle:@"推流" forState:UIControlStateNormal];
    [Btn4 addTarget:self action:@selector(recordCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Btn4];
    
    UIButton *Btn5 = [[UIButton alloc] initWithFrame:CGRectMake(120, SCREEN_WIDTH+210, 100, 50)];
    Btn5.backgroundColor = [UIColor blackColor];
    [Btn5 setTitle:@"播放" forState:UIControlStateNormal];
    [Btn5 addTarget:self action:@selector(gotopaly1) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Btn5];

    
}

- (void)recordCamera
{
    
    
//    [self testPullStram];
    RecordViewController *vc = [[RecordViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showFullScreen:(UIButton *)sender
{
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"cuc_ieschool" withExtension:@"flv"];
//
//    id  mePlayer=[[IJKFFMoviePlayerController alloc] initWithContentURL:url withOptions:nil];
//    UIView *playView=[mePlayer view];//播放器的view
//    playView.frame=CGRectMake(0,0,self.view.frame.size.width,200);
//    playView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [self.view insertSubview:playView atIndex:1];
//    
//    double delayInSeconds = 3;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        [mePlayer play];
//        
//    });
////    [self testPullStram];
//
//    return;
    sender.selected = !sender.selected;
    
    
    if (sender.selected)
    {
//        _showView.frame = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
        _showView.transform=CGAffineTransformMakeRotation(M_PI/2);

        _showView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

    }
    else
    {
        _showView.transform=CGAffineTransformMakeRotation(0);
        
        _showView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH*_flDecoder.sourceHeight/_flDecoder.sourceWidth);


    }

}

- (void)gotoStop:(UIButton *)sender
{
    [_nextFrameTimer invalidate];
    [_flDecoder stopAudio];
    [sender setTitle:@"暂停" forState:UIControlStateNormal];



}
- (void)gotoPause:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
//    int random = arc4random() % 4;
//    
//    _showView.frame = CGRectMake(0, 0, SCREEN_WIDTH/random, SCREEN_WIDTH*_flDecoder.sourceHeight/_flDecoder.sourceWidth/random);


    if (sender.selected)
    {
        [_nextFrameTimer invalidate];
        self.nextFrameTimer = nil;
        [sender setTitle:@"继续" forState:UIControlStateNormal];
        [_flDecoder pauseAudio];

    }
    else
    {
        [_nextFrameTimer invalidate];
        self.nextFrameTimer = nil;
        
        [_flDecoder playAudio];
        self.nextFrameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/_flDecoder.fps//在模拟器上会有问题。
                                                               target:self
                                                             selector:@selector(displayNextFrame:)
                                                             userInfo:nil
                                                              repeats:YES];
        [sender setTitle:@"暂停" forState:UIControlStateNormal];


    }
    
}

- (void)gotoKxmoviePaly
{
    _lastFrameTime = -1;
    

//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"你好" withExtension:@"ts"];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"cuc_ieschool" withExtension:@"flv"];
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"fanlv" withExtension:@"h264"];
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"flv"];
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"aa" withExtension:@"mp4"];

    NSString *fileUrl = [url absoluteString];
//    fileUrl = @"rtmp://202.69.69.180:443/webcast/bshdlive-pc";//[url absoluteString]
//    fileUrl = @"http://live.hkstv.hk.lxdns.com/live/hks/playlist.m3u8";
//    fileUrl =@"http://123.108.164.75/etv2sb/pld10501/playlist.m3u8";
//    fileUrl = @"http://le.iptv.ac.cn:8888/letv.m3u8?id=cctv1HD_1800";

//    fileUrl = @"rtmp://10.0.202.192:1935/fanlv/home";

//    fileUrl = @"rtmp://172.25.44.3:1935/fanlv/home";


    fileUrl = RTMP_URL;
    
    
    
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    
    // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        parameters[KxMovieParameterDisableDeinterlacing] = @(YES);
    
    KxMovieViewController *vc = [KxMovieViewController movieViewControllerWithContentPath:fileUrl
                                                                               parameters:parameters];
//    [self presentViewController:vc animated:YES completion:nil];
    
    
    [self.navigationController pushViewController:vc animated:YES];
    
    
    
    
    
    
    
    

}


- (void)gotopaly1
{

    NSURL *url = [[NSBundle mainBundle] URLForResource:@"cuc_ieschool" withExtension:@"flv"];
    
    NSString *fileUrl = [url absoluteString];

    fileUrl = @"http://live.hkstv.hk.lxdns.com/live/hks/playlist.m3u8";
    
    

    fileUrl = RTMP_URL;

    _flDecoder = [[FLDecoder alloc] initWithVideo:fileUrl];
    
    //设置视频原始尺寸
    //    [_showView setVideoSize:_flDecoder.sourceWidth height:_flDecoder.sourceWidth];
    
    
    
    
    [_nextFrameTimer invalidate];
    if (_flDecoder) {
        _showView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH*_flDecoder.sourceHeight/_flDecoder.sourceWidth);
        [_flDecoder playAudio];
        self.nextFrameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/(_flDecoder.fps)
                                                               target:self
                                                             selector:@selector(displayNextFrame:)
                                                             userInfo:nil
                                                              repeats:YES];
    }

}



- (void)viewDidDisappear:(BOOL)animated {
    [_nextFrameTimer invalidate];
    self.nextFrameTimer = nil;
}



-(void)displayNextFrame:(NSTimer *)timer
{
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];

    _timeLabel.text  = [self dealTime:_flDecoder.currentTime];
//    if (![_flDecoder stepFrame]) {
//    }
//    _showView.image = _flDecoder.currentImage;
    
    
    AVFrame *frame = [_flDecoder stepFrame];
    if (frame) {
        [_showView displayYUV420pData:frame ];
    }
    else
    {
        [timer invalidate];
//        _showView.image = nil;
        return;

    }

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


























- (void)testPullStram {
    
    const char *in_filename;
    char *out_filename;
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"cuc_ieschool" withExtension:@"flv"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fileName = @"fanlv.h264";
    fileName = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    in_filename = [[url absoluteString] UTF8String];
    out_filename = "rtmp://10.0.202.192:1935/fanlv/home";
//    in_filename = [fileName UTF8String];
    
    printf("Input Path:%s\n",in_filename);
    printf("Output Path:%s\n",out_filename);
    
    AVOutputFormat *ofmt = NULL;
    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
    AVPacket pkt;

    int ret, i;
    int videoindex=-1;
    int frame_index=0;
    int64_t start_time=0;


    av_register_all();
    avformat_network_init();
    if ((ret = avformat_open_input(&ifmt_ctx, in_filename, 0, 0)) < 0) {
        printf( "Could not open input file.");
        goto end;
    }
    if ((ret = avformat_find_stream_info(ifmt_ctx, 0)) < 0) {
        printf( "Failed to retrieve input stream information");
        goto end;
    }
    
    for(i=0; i<ifmt_ctx->nb_streams; i++)
        if(ifmt_ctx->streams[i]->codecpar->codec_type==AVMEDIA_TYPE_VIDEO){
            videoindex=i;
            break;
        }
    
    av_dump_format(ifmt_ctx, 0, in_filename, 0);
    
    //Output
    
    avformat_alloc_output_context2(&ofmt_ctx, NULL, "flv", out_filename); //RTMP
    //avformat_alloc_output_context2(&ofmt_ctx, NULL, "mpegts", out_filename);//UDP
    
    if (!ofmt_ctx) {
        printf( "Could not create output context\n");
        ret = AVERROR_UNKNOWN;
        goto end;
    }
    ofmt = ofmt_ctx->oformat;
    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
        
        AVStream *in_stream = ifmt_ctx->streams[i];
        
        AVCodecParameters *in_p_codec_parameters = in_stream->codecpar;
        AVCodecContext *in_pCodecCtx = avcodec_alloc_context3(NULL);
        avcodec_parameters_to_context(in_pCodecCtx, in_p_codec_parameters);
        
        
        AVStream *out_stream = avformat_new_stream(ofmt_ctx, in_pCodecCtx->codec);
        if (!out_stream) {
            printf( "Failed allocating output stream\n");
            ret = AVERROR_UNKNOWN;
            goto end;
        }
        
        
//        AVCodecContext *out_pCodecCtx = avcodec_alloc_context3(NULL);
//        AVCodecParameters *out_p_codec_parameters;
//        ret = avcodec_parameters_from_context(out_p_codec_parameters,in_pCodecCtx);;
//        ret =avcodec_parameters_to_context(out_pCodecCtx,out_p_codec_parameters);
        
        
        ret = avcodec_copy_context(out_stream->codec, in_pCodecCtx);
        if (ret < 0) {
            printf( "Failed to copy context from input to output stream codec context\n");
            goto end;
        }
        
//        out_stream->codec->codec_tag = 0;
//        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
//            out_stream->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
    }
    //Dump Format------------------
    av_dump_format(ofmt_ctx, 0, out_filename, 1);
    //Open output URL
    if (!(ofmt->flags & AVFMT_NOFILE)) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            printf( "Could not open output URL '%s'", out_filename);
            goto end;
        }
    }
    
    ret = avformat_write_header(ofmt_ctx, NULL);
    if (ret < 0) {
        printf( "Error occurred when opening output URL\n");
        goto end;
    }
    
    start_time=av_gettime();
    while (1) {
        AVStream *in_stream, *out_stream;
        //Get an AVPacket
        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0)
            break;
        //FIX：No PTS (Example: Raw H.264)
        //Simple Write PTS
        if(pkt.pts==AV_NOPTS_VALUE){
            //Write PTS
            AVRational time_base1=ifmt_ctx->streams[videoindex]->time_base;
            //Duration between 2 frames (us)
            int64_t calc_duration=(double)AV_TIME_BASE/av_q2d(ifmt_ctx->streams[videoindex]->r_frame_rate);
            //Parameters
            pkt.pts=(double)(frame_index*calc_duration)/(double)(av_q2d(time_base1)*AV_TIME_BASE);
            pkt.dts=pkt.pts;
            pkt.duration=(double)calc_duration/(double)(av_q2d(time_base1)*AV_TIME_BASE);
        }
        //Important:Delay
        if(pkt.stream_index==videoindex){
            AVRational time_base=ifmt_ctx->streams[videoindex]->time_base;
            AVRational time_base_q={1,AV_TIME_BASE};
            int64_t pts_time = av_rescale_q(pkt.dts, time_base, time_base_q);
            int64_t now_time = av_gettime() - start_time;
            if (pts_time > now_time)
                av_usleep((unsigned int)(pts_time - now_time));
            
        }
        
        in_stream  = ifmt_ctx->streams[pkt.stream_index];
        out_stream = ofmt_ctx->streams[pkt.stream_index];
        /* copy packet */
        //Convert PTS/DTS
        pkt.pts = av_rescale_q_rnd(pkt.pts, in_stream->time_base, out_stream->time_base, (AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.dts = av_rescale_q_rnd(pkt.dts, in_stream->time_base, out_stream->time_base, (AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.duration = av_rescale_q(pkt.duration, in_stream->time_base, out_stream->time_base);
        pkt.pos = -1;
        //Print to Screen
        if(pkt.stream_index==videoindex){
            printf("Send %8d video frames to output URL\n",frame_index);
            frame_index++;
        }
        //ret = av_write_frame(ofmt_ctx, &pkt);
        ret = av_interleaved_write_frame(ofmt_ctx, &pkt);
        
        if (ret < 0) {
            printf( "Error muxing packet\n");
            break;
        }
        
        av_packet_unref(&pkt);
        
    }
    //写文件尾（Write file trailer）
    av_write_trailer(ofmt_ctx);
end:
    avformat_close_input(&ifmt_ctx);
    /* close output */
    if (ofmt_ctx && !(ofmt->flags & AVFMT_NOFILE))
        avio_close(ofmt_ctx->pb);
    avformat_free_context(ofmt_ctx);
    if (ret < 0 && ret != AVERROR_EOF) {
        printf( "Error occurred.\n");
        return;
    }
    return;
    
}






@end
