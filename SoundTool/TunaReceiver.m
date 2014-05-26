//
//  TunaReceiver.m
//  SoundTool
//
//  Created by kaichuan on 5/25/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import "TunaReceiver.h"
#import "TunaConstant.h"
#import "kiss_fft.h"


@implementation TunaReceiver


AQState *aqState;
kiss_fft_cfg cfg;
kiss_fft_cpx *cx_in;
kiss_fft_cpx *cx_out;
float energy = 0;
float maxEnergy = 0;

static void HandleInputBuffer (
                               void                                *aqData,            
                               AudioQueueRef                       inAQ,               
                               AudioQueueBufferRef                 inBuffer,           
                               const AudioTimeStamp                *inStartTime,       
                               UInt32                              inNumPackets,       
                               const AudioStreamPacketDescription  *inPacketDesc       
){
  
    if (!aqState->mIsRunning){
        AudioQueueFlush(inAQ);
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
    
    energy  =  sqrt(powf(cx_out[179].r, 2)+ powf(cx_out[179].i, 2));
    if (energy > maxEnergy){
        maxEnergy =energy;
        printf("%f\n", energy);
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
    aqState = getInitState();
    
    
    err = AudioQueueNewInput(&aqState->mDataFormat,
                             HandleInputBuffer,
                             aqState,
                             NULL,
                             NULL,
                             0,
                             &aqState->mQueue);
    if (err != noErr) NSLog(@"AudioQueueNewInput() error: %d", err);
    
    
    
    for (int i = 0; i < NUMBER_BUFFERS; i++) {
        err = AudioQueueAllocateBuffer (
                                        aqState->mQueue,
                                        aqState->bufferByteSize,
                                        &aqState->mBuffers[i]
                                        );
        if (err != noErr) NSLog(@"AudioQueueAllocateBuffer() error: %d", err);
        
        err = AudioQueueEnqueueBuffer (
                                       aqState->mQueue,
                                       aqState->mBuffers[i],
                                       0,
                                       NULL
                                       );
        if (err != noErr) NSLog(@"AudioQueueEnqueueBuffer() error: %d", err);
        
    }
    

    aqState->mIsRunning = YES;
    err = AudioQueueStart(aqState->mQueue, NULL);
    if (err != noErr) NSLog(@"AudioQueueStart() error: %d", err);
  
};
-(void)stop{
    aqState->mIsRunning = NO;
};

@end
