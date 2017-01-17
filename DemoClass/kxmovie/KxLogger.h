//
//  KxLogger.h
//  kxmovie
//
//  Created by Mathieu Godart on 01/05/2014.
//
//

#ifndef kxmovie_KxLogger_h
#define kxmovie_KxLogger_h

//#define DUMP_AUDIO_DATA

#ifdef DEBUG
#ifdef USE_NSLOGGER

//#    import "NSLogger.h"
#    define LoggerStream(level, ...)   LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Stream", level, __VA_ARGS__)
#    define LoggerVideo(level, ...)    LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Video",  level, __VA_ARGS__)
#    define LoggerAudio(level, ...)    LogMessageF(__FILE__, __LINE__, __FUNCTION__, @"Audio",  level, __VA_ARGS__)

#else
#define NSLog(FORMAT, ...) fprintf(stderr,"[%s:%d]\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

#    define LoggerStream(level, ...)   NSLog(__VA_ARGS__)
#    define LoggerVideo(level, ...)    NSLog(__VA_ARGS__)
#    define LoggerAudio(level, ...)    NSLog(__VA_ARGS__)

#endif
#else

#    define LoggerStream(...)          while(0) {}
#    define LoggerVideo(...)           while(0) {}
#    define LoggerAudio(...)           while(0) {}

#endif

#endif
