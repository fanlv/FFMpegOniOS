//
//  ViewController.m
//  FFMpegOniOS
//
//  Created by Fan Lv on 2017/1/9.
//  Copyright © 2017年 Fanlv. All rights reserved.
//

#import "ViewController.h"
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

@interface ViewController ()
{
    AVFormatContext *p_format_context;
    AVCodecParameters *p_codec_parameters;
    AVCodec *p_codec;
    AVFrame *p_frame, *p_frame_YUV;
    uint8_t *out_buffer;
    AVPacket *packet;
    struct  SwsContext *img_convert_ctx;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    printf("%s\n", avcodec_configuration());

    int ret = [self doSomethingDecode];
    
    

}


- (int)doSomethingDecode {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Titanic" withExtension:@"ts"];
    char *filepath = (char *)[[url absoluteString] UTF8String];
    
    
    int  videoindex, ret, frame_cnt;
    
    
    //1.register init net work
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
    //5.find decoder
    p_codec_parameters = p_format_context->streams[videoindex]->codecpar;
    p_codec = avcodec_find_decoder(p_codec_parameters->codec_id);
    AVCodecContext *p_codec_context = avcodec_alloc_context3(p_codec);
    if (p_codec == NULL) {
        printf("Codec not found.\n");
        return -1;
    }
    if (avcodec_open2(p_codec_context, p_codec, NULL)<0) {
        printf("Could not open codec.\n");
        return -1;
    }
    //6.init frame and buffer
    p_frame = av_frame_alloc();
    p_frame_YUV = av_frame_alloc();
    out_buffer = (uint8_t *)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_YUV420P, p_codec_parameters->width, p_codec_parameters->height, 1));
    av_image_fill_arrays(p_frame_YUV->data, p_frame_YUV->linesize, out_buffer, AV_PIX_FMT_YUV420P, p_codec_parameters->width, p_codec_parameters->height, 1);
    
    
    packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    
    printf("--------------- File Information ----------------\n");
    av_dump_format(p_format_context, 0, filepath, 0);
    printf("-------------------------------------------------\n");
    
    //    img_convert_ctx = sws_getContext(p_codec_parameters->width, p_codec_parameters->height, (AVPixelFormat)p_codec_parameters->format,
    //                                     p_codec_parameters->width, p_codec_parameters->height, AV_PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    //
    
    
    
    
    
    
    //7.read frame
    frame_cnt = 0;
    while (av_read_frame(p_format_context, packet) >= 0)
    {
        if (packet->stream_index == videoindex)
        {
            ret = avcodec_send_packet(p_codec_context, packet);
            ret = avcodec_receive_frame(p_codec_context, p_frame);
            
            if (ret >= 0)
            {
                //9.scale frame
                //                sws_scale(img_convert_ctx, (const uint8_t* const*)p_frame->data, p_frame->linesize, 0, p_codec_context->height,
                //                          p_frame_YUV->data, p_frame_YUV->linesize);
                printf("Decoded frame index: %d\n", frame_cnt++);
            }
            
            
        }
        av_packet_unref(packet);
        
    }
    
    
    sws_freeContext(img_convert_ctx);
    
    av_frame_free(&p_frame_YUV);
    av_frame_free(&p_frame);
    avcodec_close(p_codec_context);
    avformat_close_input(&p_format_context);
    
    return 0;

}


@end
