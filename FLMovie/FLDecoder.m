//
//  FLDecoder.m
//  FFMpegOniOS
//
//  Created by Fan Lv on 2017/1/10.
//  Copyright © 2017年 Fanlv. All rights reserved.
//

#import "FLDecoder.h"

#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavutil/channel_layout.h"
#include "libavutil/common.h"
#include "libavutil/imgutils.h"
#include "libavutil/opt.h"
#include "libavutil/mathematics.h"
#include "libavutil/samplefmt.h"
#include "libswresample/swresample.h"

@interface FLDecoder()
{
    AVFormatContext *p_format_context;
    AVCodecParameters *p_codec_parameters;
    AVCodec *p_codec;
    AVFrame *p_frame;
    uint8_t *out_buffer;
    AVPacket *packet;
//    struct  SwsContext *img_convert_ctx;
    AVCodecContext *p_codec_context;
    AVPicture picture;
    int  videoindex, frame_cnt;
    double              fps;
    BOOL                isReleaseResources;
}


@end


@implementation FLDecoder


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
    if (!p_frame->data[0]) return nil;
    return [self imageFromAVPicture];
}
-(double)duration
{
    return (double)p_format_context->duration / AV_TIME_BASE;
}
- (double)currentTime
{
    AVRational timeBase = p_format_context->streams[videoindex]->time_base;
    return packet->pts * (double)timeBase.num / timeBase.den;
}
- (int)sourceWidth
{
    return p_codec_parameters->width;
}
- (int)sourceHeight
{
    return p_codec_parameters->height;
}
- (double)fps
{
    return fps;
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

    //1.register init net work
    av_register_all();
    avformat_network_init();
    
    //    AVDictionary *opts = 0;
    //    av_dict_set(&opts, "rtsp_transport", "tcp", 0);
    
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
    
    //4.find video stream
    videoindex = -1;
    for (int i = 0; i<p_format_context->nb_streams; i++)
        if (p_format_context->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoindex = i;
            break;
        }
    if (videoindex == -1) {
        fprintf(stderr, "Didn't find a video stream.\n");
        return -1;
    }
    AVStream *stream = p_format_context->streams[videoindex];
    if(stream->avg_frame_rate.den && stream->avg_frame_rate.num)
    {
        fps = av_q2d(stream->avg_frame_rate);
    }
    else
    {
        fps = 30;
    }
    
    
    //5.find decoder
    p_codec_parameters = p_format_context->streams[videoindex]->codecpar;
    p_codec = avcodec_find_decoder(p_codec_parameters->codec_id);
    p_codec_context = avcodec_alloc_context3(p_codec);
    if (p_codec == NULL) {
        printf("Codec not found.\n");
        return -1;
    }
    if (avcodec_open2(p_codec_context, p_codec, NULL)<0) {
        printf("Could not open codec.\n");
        return -1;
    }
    
    _outputWidth = p_codec_parameters->width;
    _outputHeight = p_codec_parameters->height;

    
    //6.init frame and buffer
    p_frame = av_frame_alloc();
    out_buffer = (uint8_t *)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_YUV420P, p_codec_parameters->width, p_codec_parameters->height, 1));
//    av_image_fill_arrays(p_frame_YUV->data, p_frame_YUV->linesize, out_buffer, AV_PIX_FMT_YUV420P, p_codec_parameters->width, p_codec_parameters->height, 1);
    
    
    
    packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    
    printf("--------------- File Information ----------------\n");
    av_dump_format(p_format_context, 0, filepath, 0);
    printf("-------------------------------------------------\n");
    
//    img_convert_ctx = sws_getContext(p_codec_parameters->width, p_codec_parameters->height,p_codec_parameters->format,p_codec_parameters->width, p_codec_parameters->height, AV_PIX_FMT_RGB24, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    
    
    return 0;
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


/* 从视频流中读取下一帧。返回假，如果没有帧读取（视频）。 */
- (BOOL)stepFrame {
    int ret = -1;
    while (av_read_frame(p_format_context, packet) >= 0)
    {
        if (packet->stream_index == videoindex)
        {
            ret = avcodec_send_packet(p_codec_context, packet);
            avcodec_receive_frame(p_codec_context, p_frame);
            break;
        }
    }
    if (ret < 0 && isReleaseResources == NO)
    {
        [self releaseResources];
    }
    return ret >= 0;
}


- (void)seekTime:(double)seconds
{
    AVRational timeBase = p_format_context->streams[videoindex]->time_base;
    int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * seconds);
    avformat_seek_file(p_format_context,
                       videoindex,
                       0,
                       targetFrame,
                       targetFrame,
                       AVSEEK_FLAG_FRAME);
    avcodec_flush_buffers(p_codec_context);
}

- (void)releaseResources
{
    NSLog(@"释放资源");
    //    SJLogFunc
    isReleaseResources = YES;
    // 释放RGB
    avpicture_free(&picture);
    // 释放frame
    if (packet) {
        av_packet_unref(packet);
    }
    // 释放YUV frame
    av_frame_free(&p_frame);
    
    // 关闭解码器
    if (p_codec_context)
        avcodec_close(p_codec_context);
    // 关闭文件
    if (p_format_context)
        avformat_close_input(&p_format_context);
    
    
    
//    sws_freeContext(img_convert_ctx);
    
    
    avformat_network_deinit();
}



#pragma mark - 内部方法
- (UIImage *)imageFromAVPicture
{
    avpicture_free(&picture);
    avpicture_alloc(&picture, AV_PIX_FMT_RGB24, _outputWidth, _outputHeight);
    struct SwsContext * imgConvertCtx = sws_getContext(p_frame->width,
                                                       p_frame->height,
                                                       AV_PIX_FMT_YUV420P,
                                                       _outputWidth,
                                                       _outputHeight,
                                                       AV_PIX_FMT_RGB24,
                                                       SWS_FAST_BILINEAR,
                                                       NULL,
                                                       NULL,
                                                       NULL);
    if(imgConvertCtx == nil) return nil;
    sws_scale(imgConvertCtx,
              p_frame->data,
              p_frame->linesize,
              0,
              p_frame->height,
              picture.data,
              picture.linesize);
    sws_freeContext(imgConvertCtx);
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreate(kCFAllocatorDefault,
                                  picture.data[0],
                                  picture.linesize[0] * _outputHeight);
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(_outputWidth,
                                       _outputHeight,
                                       8,
                                       24,
                                       picture.linesize[0],
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
}


@end
