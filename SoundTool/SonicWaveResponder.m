//
//  TunaReceiver.m
//  SoundTool
//
//  Created by kaichuan on 5/25/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import "SonicWaveResponder.h"
#import <AudioToolbox/AudioToolbox.h>

#import "kiss_fft.h"

static int const kNumberOfBuffers = 3;
static int const kSampleRate = 44100;
static int const kFftSize = 441;

static bool isDecording = false;
static float energy = 0;
static float maxEnergy = 0;
static int targetIndex = 0;
static char markerIndex = 0;
static char bIndex = 0;
static long long result = 0;

static void AudioQueueInputBufferCallback (void *userData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription  *inPacketDesc);


#pragma mark -

@interface SonicWaveResponder () {
@public
    BOOL mIsRunning;
    kiss_fft_cfg cfg;
    kiss_fft_cpx *cx_in;
    kiss_fft_cpx *cx_out;
    AudioStreamBasicDescription dataDescription;
    AudioQueueRef audioQueue;
    AudioQueueBufferRef mBuffers[kNumberOfBuffers];
}
@property (nonatomic, copy) void (^completeHander)(NSNumber *number);
@end

@implementation SonicWaveResponder

- (void)dealloc
{
    if (mIsRunning) {
        [self stopReceviceData];
    }
    kiss_fft_cleanup();
    AudioQueueDispose(audioQueue, true);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        dataDescription.mSampleRate = kSampleRate;
        dataDescription.mFormatID = kAudioFormatLinearPCM;
        dataDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        dataDescription.mBytesPerPacket = 2;
        dataDescription.mFramesPerPacket = 1;
        dataDescription.mBytesPerFrame = 2,
        dataDescription.mChannelsPerFrame = 1;
        dataDescription.mBitsPerChannel = 16;
        dataDescription.mReserved = 0;
        
        cfg = kiss_fft_alloc(kFftSize, NO, 0, 0);
        cx_in = (kiss_fft_cpx*)malloc(sizeof(kiss_fft_cpx)*kFftSize);
        cx_out = (kiss_fft_cpx*)malloc(sizeof(kiss_fft_cpx)*kFftSize);
    }
    return self;
}

- (void)startRecevieDataWithCompleteHander:(void (^)(NSNumber *))completeHander
{
    self.completeHander = completeHander;
    AudioQueueNewInput(&dataDescription,
                       AudioQueueInputBufferCallback,
                       (__bridge void *)(self),
                       NULL,
                       NULL,
                       0,
                       &audioQueue);
    for (int i = 0; i < kNumberOfBuffers; i++) {
        AudioQueueAllocateBuffer (audioQueue, kFftSize * 2, &mBuffers[i]);
        AudioQueueEnqueueBuffer (audioQueue, mBuffers[i], 0, NULL);
    }
    
    AudioQueueStart(audioQueue, NULL);
    mIsRunning = YES;
};

- (void)stopReceviceData
{
    mIsRunning = NO;
}

- (void)resetData
{
    for (int i = 0; i < kNumberOfBuffers; i++) {
        AudioQueueFreeBuffer(audioQueue, mBuffers[i]);
    }
    energy = maxEnergy = targetIndex = markerIndex = bIndex = result = 0;
    isDecording = false;
    AudioQueueStop(audioQueue, true);
    AudioQueueReset(audioQueue);
}

@end


#pragma mark -
void AudioQueueInputBufferCallback (void *userData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc) {
    
    SonicWaveResponder *responder = (__bridge SonicWaveResponder *)userData;
    if (!responder->mIsRunning){
        [responder resetData];
        return;
    }
    
    static int const targetBins[4] = { 177, 179, 181, 183 };
    static char const marker[4] = { 2, 2, 0, 0 };

    SInt16 *p = inBuffer->mAudioData;
    for (int i = 0; i < kFftSize; i++) {
        responder->cx_in[i].r = p[i];
        responder->cx_in[i].i = 0;
    }
    
    kiss_fft(responder->cfg,responder->cx_in, responder->cx_out);
    maxEnergy = 0;
    for (int i = 0; i < 4; i++) {
        energy = sqrt(powf(responder->cx_out[targetBins[i]].r, 2)+ powf(responder->cx_out[targetBins[i]].i, 2));
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
        result = ((targetIndex << (2 * markerIndex)) | result);
        markerIndex++;
        if (markerIndex == 4) {
            bIndex++;
            markerIndex = 0;
            if (bIndex == 5) {
                if (responder.completeHander) {
                    responder.completeHander(@(result));
                }
                responder->mIsRunning = false;
                [responder resetData];
            } else
            result = result  << 8;
        }
    }
    
    AudioQueueEnqueueBuffer(inAQ,inBuffer,0,NULL);
};
