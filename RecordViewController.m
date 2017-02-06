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
#import "rtmp.h"


#import "libavcodec/avcodec.h"
#import "libavformat/avformat.h"
#import "libswscale/swscale.h"
#import "libavutil/channel_layout.h"
#import "libavutil/common.h"
#import "libavutil/opt.h"
#import "libavutil/mathematics.h"
#import "libavutil/samplefmt.h"
#import "libavutil/imgutils.h"


#include <libavutil/mathematics.h>
#include <libavutil/time.h>
#include <libavformat/avformat.h>


#import "LFLivePreview.h"


#define SCREEN_HEIGHT                   [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH                    [[UIScreen mainScreen] bounds].size.width

@interface RecordViewController ()<FLCameraHelpDelegate>
{
    CGSize                           videoSize;
    UIView *view;
//    RTMP *rtmp;
}
@property (nonatomic, strong) FLCameraHelp *flCameraHelp;
@property (nonatomic, strong) X264Manager *manager264;

@end

@implementation RecordViewController
@synthesize manager264;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:[[LFLivePreview alloc] initWithFrame:self.view.bounds]];

    
    /*

//    NSString *path = [self savedFilePath];
//    bool ret = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];

    
//    view = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 120 -20, SCREEN_HEIGHT - 160 - 50 , 120, 160)];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2.0 - 120, 70 , 120*2, 160*2)];

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

    UIButton *Btn3 = [[UIButton alloc] initWithFrame:CGRectMake(230, SCREEN_WIDTH+150, 100, 50)];
    Btn3.backgroundColor = [UIColor blackColor];
    [Btn3 setTitle:@"upload" forState:UIControlStateNormal];
    [Btn3 addTarget:self action:@selector(testPullStram) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Btn3];
     
     */
  


}


- (int)initRTMP
{
//    /*分配与初始化*/
//    rtmp = RTMP_Alloc();
//    RTMP_Init(rtmp);
//    
//    /*设置URL*/
//    if (RTMP_SetupURL(rtmp,"rtmp://172.25.44.3:1935/fanlv/home") == FALSE) {
//        NSLog(@"RTMP_SetupURL() failed!");
//        RTMP_Free(rtmp);
//        return -1;
//    }
//    
//    /*设置可写,即发布流,这个函数必须在连接前使用,否则无效*/
//    RTMP_EnableWrite(rtmp);
//    
//    /*连接服务器*/
//    if (RTMP_Connect(rtmp, NULL) == FALSE) {
//        NSLog(@"RTMP_Connect() failed!");
//        RTMP_Free(rtmp);
//        return -1;
//    }
//    
//    /*连接流*/
//    if (RTMP_ConnectStream(rtmp,0) == FALSE) {
//        NSLog(@"RTMP_ConnectStream() failed!");
//        RTMP_Close(rtmp);
//        RTMP_Free(rtmp);
//        return -1;
//    }

    
    return 0;
}

- (void)freeRTMP
{
//    /*关闭与释放*/
//    RTMP_Close(rtmp);
//    RTMP_Free(rtmp);

}

#define RTMP_HEAD_SIZE   (sizeof(RTMPPacket)+RTMP_MAX_HEADER_SIZE)


- (void)goback
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)recordVideo:(UIButton *)button
{
    button.selected = !button.selected;
    
    if (button.selected) {
        
        NSLog(@"recordVideo....");
        
        
//        [self initRTMP];

        
        _flCameraHelp = [[FLCameraHelp alloc] initWithPreset:AVCaptureSessionPreset640x480];
        
        
        
        [_flCameraHelp embedPreviewInView:view];
        [_flCameraHelp changePreviewOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        _flCameraHelp.delegate = self;
        
        videoSize = [self getVideoSize:_flCameraHelp.session.sessionPreset];

        manager264 = [[X264Manager alloc]init];
//        [manager264 setFileSavedPath:[self savedFilePath]];
        [manager264 setFileSavedPath:@"rtmp://10.0.202.192:1935/fanlv/home"];//[self savedFilePath]];

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


static int frameCount = 0;


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    NSLog(@"sampleBuffer :%@",sampleBuffer);
    
    
    // 这里的sampleBuffer就是采集到的数据了，但它是Video还是Audio的数据，得根据connection来判断
    if (connection == _flCameraHelp.vedioConnection)
    {
        // Video
//        NSLog(@"在这里获得video sampleBuffer，做进一步处理（编码H.264）");
#if encodeModel
        // encode
        [manager264 encoderToH264:sampleBuffer];
        @synchronized (self) {
            frameCount ++ ;
        }
        
        
        
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
     else if (connection == _flCameraHelp.audioConnection) {
         // Audio
//         NSLog(@"这里获得audio sampleBuffer，做进一步处理（编码AAC）");
     }
    

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



- (void)testPullStram
{
    
    const char *in_filename;
    char *out_filename;
    
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"cuc_ieschool" withExtension:@"flv"];
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"fanlv1" withExtension:@"h264"];
    
    
    

    
    in_filename = [[self savedFilePath] UTF8String];

//    in_filename = [[url absoluteString] UTF8String];
    out_filename = "rtmp://10.0.202.192:1935/fanlv/home";
    
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
        
        out_stream->codec->codec_tag = 0;
        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
            out_stream->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
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
    
        @synchronized (self) {
            if (frameCount <= 0) {
                sleep(.01);
                
                continue;
            }
            
            
            frameCount --;
        }
    
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



