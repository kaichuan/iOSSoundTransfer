//
//  TunaReceiver.m
//  SoundTool
//
//  Created by kaichuan on 5/25/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import "SonicWaveResponder.h"
#import "TunaConstant.h"
#import "kiss_fft.h"


@implementation SonicWaveResponder


//AQState *aqState;
kiss_fft_cfg cfg;
kiss_fft_cpx *cx_in;
kiss_fft_cpx *cx_out;
float energy = 0;
float maxEnergy = 0;
int targetIndex = 0;
int targetBins[4] = { 177, 179, 181, 183 };
bool isDecording = false;

char marker[4] = { 2, 2, 0, 0 };
char markerIndex = 0;
char bIndex = 0;

long long result = 0, preGet = 0;


bool mIsRunning = false;

AudioQueueRef mQueue;
AudioQueueBufferRef mBuffers[NUMBER_BUFFERS];
UInt16 bufferByteSize = FFT_SIZE * 2;

static void HandleInputBuffer (
                               void                                *aqData,
                               AudioQueueRef                       inAQ,
                               AudioQueueBufferRef                 inBuffer,
                               const AudioTimeStamp                *inStartTime,
                               UInt32                              inNumPackets,
                               const AudioStreamPacketDescription  *inPacketDesc
                               ){
    
    if (!mIsRunning){
        
        AudioQueueStop(inAQ, true);
        AudioQueueDispose(inAQ,true);
        return;
    }
    SInt16 *p = inBuffer->mAudioData;
    for (int i = 0; i < FFT_SIZE; i++) {
        cx_in[i].r = p[i];
        cx_in[i].i = 0;
    }
    
    kiss_fft(cfg, cx_in, cx_out);
    maxEnergy = 0;
    for (int i = 0; i < 4; i++) {
        energy = sqrt(powf(cx_out[targetBins[i]].r, 2)+ powf(cx_out[targetBins[i]].i, 2));
        if (maxEnergy < energy) {
            targetIndex = i;
            maxEnergy = energy;
        }
    }
    
    if (!isDecording) {
        
        if (maxEnergy < 10000){
            AudioQueueEnqueueBuffer(inAQ,inBuffer,0,NULL);
            return;
        }
        
        if (targetIndex == marker[markerIndex]) {
            markerIndex++;
            
        } else {
            markerIndex = 0;
        }
        
        if (markerIndex == 4) {
            isDecording = true;
            markerIndex = 0;
            
            return;
        }
    }
    else{
//        NSLog(@"%d", targetIndex);
        result = ((targetIndex << (2 * markerIndex)) | result);
        markerIndex++;
        if (markerIndex == 4) {
            bIndex++;
            markerIndex = 0;
            NSLog(@"%lld", result);
            if (bIndex == 5) {
                isDecording = false;
                bIndex = 0;
//                NSLog(@"%lld", result);

                [[NSNotificationCenter defaultCenter] postNotificationName:@"TunaReceivedData" object:[NSNumber numberWithLongLong:result]];
                
                mIsRunning = false;
                AudioQueueStop(inAQ, true);
                AudioQueueDispose(inAQ,true);
            }else
            result = result  << 8;
//            NSLog(@"%d:%d:%f", (unsigned int)inNumPackets,targetIndex,maxEnergy);
            
        }
        
    }
    
    
    AudioQueueEnqueueBuffer(inAQ,inBuffer,0,NULL);
    
};

int err;

-(id) init {
    cfg = kiss_fft_alloc(FFT_SIZE, NO, 0, 0);
    cx_in = (kiss_fft_cpx*)malloc(sizeof(kiss_fft_cpx)*FFT_SIZE);
    cx_out = (kiss_fft_cpx*)malloc(sizeof(kiss_fft_cpx)*FFT_SIZE);
    
    
    
    
    return [super init];
}



-(void)execute {
    
    
    
    err = AudioQueueNewInput(&mDataFormat,
                             HandleInputBuffer,
                             NULL,
                             NULL,
                             NULL,
                             0,
                             &mQueue);
    if (err != noErr) NSLog(@"AudioQueueNewInput() error: %d", err);
    
    
    
    for (int i = 0; i < NUMBER_BUFFERS; i++) {
        err = AudioQueueAllocateBuffer (
                                        mQueue,
                                        bufferByteSize,
                                        &mBuffers[i]
                                        );
        if (err != noErr) NSLog(@"AudioQueueAllocateBuffer() error: %d", err);
        
        err = AudioQueueEnqueueBuffer (
                                       mQueue,
                                       mBuffers[i],
                                       0,
                                       NULL
                                       );
        if (err != noErr) NSLog(@"AudioQueueEnqueueBuffer() error: %d", err);
        
    }
    
    
    mIsRunning = YES;
    err = AudioQueueStart(mQueue, NULL);
    if (err != noErr) NSLog(@"AudioQueueStart() error: %d", err);
    
};
-(void)stop{
    mIsRunning = NO;
};

@end
