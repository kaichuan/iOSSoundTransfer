//
//  TunaConstant.h
//  SoundTool
//
//  Created by kaichuan on 5/25/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define NUMBER_BUFFERS 3
#define SAMPLE_RATE 44100
#define FFT_SIZE 441

@interface TunaConstant : NSObject

typedef struct _AQState {
    AudioStreamBasicDescription   mDataFormat;
    AudioQueueRef                 mQueue;
    AudioQueueBufferRef           mBuffers[NUMBER_BUFFERS];
    bool                          mIsRunning;
    UInt16                         bufferByteSize;
}AQState;
extern const int FREQUENCIES[];
AQState *getInitState();







@end
