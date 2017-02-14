//
//  FLDecoder.m
//  FFMpegOniOS
//
//  Created by Fan Lv on 2017/1/10.
//  Copyright © 2017年 Fanlv. All rights reserved.
//

#import "FLDecoder.h"


#import <AudioToolbox/AudioToolbox.h>
//#import <AVFoundation/AVFoundation.h>



#import <AudioToolbox/AudioToolbox.h>
#import "libavcodec/avcodec.h"
#import "libavformat/avformat.h"
#import "libswscale/swscale.h"
#import "libavutil/channel_layout.h"
#import "libavutil/common.h"
#import "libavutil/opt.h"
#import "libavutil/mathematics.h"
#import "libavutil/samplefmt.h"
#import "libavutil/imgutils.h"


#import "AudioPacketQueue.h"
#import "AudioUtilities.h"


typedef enum _AUDIO_STATE {
    AUDIO_STATE_READY           = 0,
    AUDIO_STATE_STOP            = 1,
    AUDIO_STATE_PLAYING         = 2,
    AUDIO_STATE_PAUSE           = 3,
    AUDIO_STATE_SEEKING         = 4
} AUDIO_STATE;



/**
 *  缓存区的个数，一般3个
 */
#define kNumberAudioQueueBuffers 3
#define kDefaultOutputBufferSize 8000


#define kNumAQBufs 3
#define kAudioBufferSeconds 3


@interface FLDecoder()
{
    AVFormatContext *p_format_context;
    AVCodecParameters *p_vedio_codec_parameters;
    AVCodecParameters *p_audio_codec_parameters;
    AVCodec *p_vedio_codec;
    AVCodec *p_audio_codec;
    AVCodecContext *p_video_codec_context;
    AVCodecContext *p_audio_codec_context;
    AVPacket *_currentVedioPacket;

    AVFrame *p_frame;
    
    
    int  videoStream,audioStream,frame_cnt;
    double              _fps;
    BOOL                isReleaseResources;


    
    
    
    
    
    
    
    



}

@property (nonatomic, strong) UIImage *currentImage;
@property (assign, nonatomic) AudioQueueRef   outputQueue;
@property (nonatomic, assign) double currentTime;
@property (nonatomic, strong)AudioPlayer *audioPlayer;

@property (nonatomic, strong) NSMutableArray *receiveData;//接收数据的数组

@end


@implementation FLDecoder

@synthesize audioPlayer;

#pragma mark - 重写属性访问方法
-(void)setOutputWidth:(int)newValue
{
    _outputWidth = newValue;
}
-(void)setOutputHeight:(int)newValue
{
    _outputHeight = newValue;
}
-(UIImage *)currentImage
{
    return _currentImage;
}
-(double)duration
{
    if (p_format_context) {
        return (double)p_format_context->duration / AV_TIME_BASE;
    }
    return 0;
}
- (double)currentTime
{
    return _currentTime;

}
- (int)sourceWidth
{
    if (p_vedio_codec_parameters && p_vedio_codec_parameters->width != 0) {
        return p_vedio_codec_parameters->width;
    }
    return 640;
}
- (int)sourceHeight
{
    if (p_vedio_codec_parameters && p_vedio_codec_parameters->height != 0) {
        return p_vedio_codec_parameters->height;
    }
    return 320;
}
- (double)fps
{
    if (videoStream<0) {
        return 30;
    }
    AVStream *st = p_format_context->streams[videoStream];

    
    
    
    CGFloat fps, timebase;
    
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if(p_video_codec_context->time_base.den && p_video_codec_context->time_base.num)
        timebase = av_q2d(p_video_codec_context->time_base);
    else
        timebase = 0.03;
    
 
    
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.den && st->r_frame_rate.num)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;
    
    
    _fps = fps;
    
    
    
    
    
    
    
    
    return _fps;
}



#pragma mark - Init

/* 视频路径。 */
- (instancetype)initWithVideo:(NSString *)moviePath
{
    self = [super init];
    if (self) {
        if ([self initDecoderWithVideo:moviePath] == 0)
        {
            _currentVedioPath = moviePath;
            return self;
        } else {
            return nil;
        }
    }
    return self;

}


-(int)initDecoderWithVideo:(NSString *)moviePath
{
    if (!isReleaseResources) {
        [self releaseResources];
    }
    moviePath = [moviePath stringByRemovingPercentEncoding];

    char *filepath = (char *)[moviePath UTF8String];
    isReleaseResources = NO;
//    printf("%s\n", avcodec_configuration());
    
    
    
    //1.register and init net work
    av_register_all();
    avformat_network_init();
    p_format_context = avformat_alloc_context();
    
    //2.open input stream
    if (avformat_open_input(&p_format_context, filepath, NULL, NULL) != 0)
    {
        fprintf(stderr, "Couldn't open input stream.\n");
        return -1;
    }
    
    //3.get stream infomation
    if (avformat_find_stream_info(p_format_context, NULL)<0)
    {
        fprintf(stderr, "Couldn't find stream information.\n");
        return -1;
    }
    
    //4.find video、audio stream
    videoStream = -1;
    audioStream = -1;
    for (int i = 0; i<p_format_context->nb_streams; i++)
    {
        if (p_format_context->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStream = i;
        }else if (p_format_context->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStream = i;
        }
    }
    if (videoStream == -1) {
        fprintf(stderr, "Didn't find a video stream.\n");
    }
    if (audioStream == -1) {
        fprintf(stderr, "Didn't find a audio stream.\n");
    }
    
    
    //5.find decoder
    if (videoStream != -1) {
        
        frame_cnt = 0;
        p_vedio_codec_parameters = p_format_context->streams[videoStream]->codecpar;
        p_vedio_codec = avcodec_find_decoder(p_vedio_codec_parameters->codec_id);
        p_video_codec_context = avcodec_alloc_context3(NULL);
        avcodec_parameters_to_context(p_video_codec_context, p_format_context->streams[videoStream]->codecpar);
        
        if (p_vedio_codec == NULL) {
            printf("Codec not found.\n");
            return -1;
        }
        
        if (avcodec_open2(p_video_codec_context, p_vedio_codec, NULL)<0) {
            printf("Could not open vedio codec.\n");
            return -1;
        }
        
        _outputWidth = p_vedio_codec_parameters->width;
        _outputHeight = p_vedio_codec_parameters->height;
    }

    if (audioStream != -1) {
        
        [audioPlayer stop:YES];
        p_audio_codec_parameters = p_format_context->streams[audioStream]->codecpar;
        p_audio_codec = avcodec_find_decoder(p_audio_codec_parameters->codec_id);
        p_audio_codec_context = avcodec_alloc_context3(NULL);
        avcodec_parameters_to_context(p_audio_codec_context, p_format_context->streams[audioStream]->codecpar);
        
        if (p_audio_codec == NULL) {
            printf("Codec not found.\n");
            return -1;
        }
        
        if (avcodec_open2(p_audio_codec_context, p_audio_codec, NULL)<0) {
            printf("Could not open audio codec.\n");
            return -1;
        }
        
        audioPlayer = [[AudioPlayer alloc] initAuido:nil withCodecCtx:(AVCodecContext *)p_audio_codec_context];

//        if ([audioPlayer getStatus] != eAudioRunning) {
//            NSLog(@"播放");
//            [audioPlayer play];
//        }

      
        
       
    
     
        // Debug -- Begin
        printf("比特率 %3lld\n", p_format_context->bit_rate);
        printf("解码器名称 %s\n", p_audio_codec_context->codec->long_name);
        printf("time_base  %d \n", p_audio_codec_context->time_base.num);
        printf("声道数  %d \n", p_audio_codec_context->channels);
        printf("sample per second  %d \n", p_audio_codec_context->sample_rate);
        // Debug -- End


    }
    
    

//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *docDir = [paths objectAtIndex:0];
//    
//    NSString *filePAth  = [NSString stringWithFormat:@"%@/output.pcm",docDir];
//    
//    fp_pcm=fopen([filePAth UTF8String], "wb");

 

    //6.init frame and buffer
    _currentVedioPacket = (AVPacket *)av_malloc(sizeof(AVPacket));

    p_frame = av_frame_alloc();

    printf("--------------- File Information ----------------\n");
    av_dump_format(p_format_context, 0, filepath, 0);
    printf("-------------------------------------------------\n");



    
    return 0;
}

- (void)playAudio
{
//    audioPlayer = nil;
//    audioPlayer = [[AudioPlayer alloc] initAuido:nil withCodecCtx:p_audio_codec_context];
    if ([audioPlayer getStatus] != eAudioRunning) {
        NSLog(@"播放");
        [audioPlayer play];
    }

}
- (void)pauseAudio
{
    if ([audioPlayer getStatus] == eAudioRunning) {
        [audioPlayer pause];
    }
}
- (void)stopAudio
{
    if ([audioPlayer getStatus] == eAudioRunning) {
        [audioPlayer stop:YES];
    }

    
}




#pragma mark - Action

/* 切换资源 */
- (void)replaceTheResources:(NSString *)moviePath
{
    
}

/* 重拨 */
- (void)redialPaly
{
    
}
short *sample_buffer;

/* 从视频流中读取下一帧。返回假，如果没有帧读取（视频）。 */
- (AVFrame *)stepFrame {

    if(!p_format_context)
        return nil;
    

    int ret = -1;
    while (av_read_frame(p_format_context, _currentVedioPacket) >= 0)
    {

        if (_currentVedioPacket->stream_index == videoStream)
        {
            ret = avcodec_send_packet(p_video_codec_context, _currentVedioPacket);
            avcodec_receive_frame(p_video_codec_context, p_frame);
            
            
            AVRational timeBase = p_format_context->streams[videoStream]->time_base;
            _currentTime = _currentVedioPacket->pts * (double)timeBase.num / timeBase.den;

            av_packet_unref(_currentVedioPacket);
//            _currentImage = [self imageFromAVPicture];//这个是用将YUV转RGB24的方法去贴图。
            
            NSLog(@"video frame count : %d",frame_cnt++);

            break;
        }
        else{
            
            if ([audioPlayer putAVPacket:_currentVedioPacket] <=0 ) {
                NSLog(@"Put Audio packet error");
            }
            

        }
        
//        av_packet_unref(_currentVedioPacket);
    }
    if (ret < 0 && isReleaseResources == NO)
    {
        [self releaseResources];
        return nil;
    }
    return p_frame;
}


- (void)seekTime:(double)seconds
{
    AVRational timeBase = p_format_context->streams[videoStream]->time_base;
    int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * seconds);
    avformat_seek_file(p_format_context,
                       videoStream,
                       0,
                       targetFrame,
                       targetFrame,
                       AVSEEK_FLAG_FRAME);
    avcodec_flush_buffers(p_video_codec_context);
    avcodec_flush_buffers(p_audio_codec_context);

}


- (void)releaseResources
{
    NSLog(@"释放资源");
    //    SJLogFunc
    isReleaseResources = YES;
    
//    [aPlayer stop:YES];

    // 释放frame
    if (_currentVedioPacket) {
        av_packet_unref(_currentVedioPacket);
    }
    // 释放YUV frame
    av_frame_free(&p_frame);
    
    // 关闭解码器
    if (p_audio_codec_context)
        avcodec_close(p_audio_codec_context);
    if (p_video_codec_context)
        avcodec_close(p_video_codec_context);
    // 关闭文件
    if (p_format_context)
        avformat_close_input(&p_format_context);
    
    
    
//    sws_freeContext(img_convert_ctx);
    
    
    avformat_network_deinit();
}






//#pragma mark - 内部方法
//- (UIImage *)imageFromAVPicture
//{
//    if (!p_frame->data[0]) return nil;
//
//    avpicture_free(&picture);
//    avpicture_alloc(&picture, AV_PIX_FMT_RGB24, _outputWidth, _outputHeight);
//    struct SwsContext * imgConvertCtx = sws_getContext(p_frame->width,
//                                                       p_frame->height,
//                                                       AV_PIX_FMT_YUV420P,
//                                                       _outputWidth,
//                                                       _outputHeight,
//                                                       AV_PIX_FMT_RGB24,
//                                                       SWS_FAST_BILINEAR,
//                                                       NULL,
//                                                       NULL,
//                                                       NULL);
//    if(imgConvertCtx == nil) return nil;
//    sws_scale(imgConvertCtx,
//              (const uint8_t *const *)p_frame->data,
//              p_frame->linesize,
//              0,
//              p_frame->height,
//              picture.data,
//              picture.linesize);
//    sws_freeContext(imgConvertCtx);
//    
//    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
//    CFDataRef data = CFDataCreate(kCFAllocatorDefault,
//                                  picture.data[0],
//                                  picture.linesize[0] * _outputHeight);
//    
//    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    CGImageRef cgImage = CGImageCreate(_outputWidth,
//                                       _outputHeight,
//                                       8,
//                                       24,
//                                       picture.linesize[0],
//                                       colorSpace,
//                                       bitmapInfo,
//                                       provider,
//                                       NULL,
//                                       NO,
//                                       kCGRenderingIntentDefault);
//    UIImage *image = [UIImage imageWithCGImage:cgImage];
//    CGImageRelease(cgImage);
//    CGColorSpaceRelease(colorSpace);
//    CGDataProviderRelease(provider);
//    CFRelease(data);
//    
//    return image;
//}


@end
