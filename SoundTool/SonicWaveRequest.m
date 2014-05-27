//
//  TunaGenerator.m
//  SoundTool
//
//  Created by kaichuan on 5/4/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import "SonicWaveRequest.h"
#import <AudioToolbox/AudioToolbox.h>

static int const kNumberBuffers = 3;
static int const kSampleRate = 44100;
static int const freqs[4] = { 17700, 17900, 18100, 18300 };

static void AudioQueueOutputBufferCallback(void *data, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);

@interface SonicWaveRequest()
{
    int byteIndex;
    int codeIndex;
    short samples[4][441];
    unsigned char byteArr[6];
    
    AudioStreamBasicDescription streamDescription;
    
    @public
        AudioQueueRef audioQueue;
        AudioQueueBufferRef audioQueueBuffer[kNumberBuffers];
        BOOL isRunning;
}
@property (nonatomic, copy) void (^completeHander)(NSError *error);
@end

@implementation SonicWaveRequest

- (void)dealloc
{
    if (isRunning) {
        [self stopSendData];
    }
    AudioQueueDispose(audioQueue, true);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        byteIndex = codeIndex = 0;
        
        streamDescription.mSampleRate = kSampleRate;
        streamDescription.mFormatID = kAudioFormatLinearPCM;
        streamDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        streamDescription.mBytesPerPacket = 2;
        streamDescription.mChannelsPerFrame = 1;
        streamDescription.mBytesPerFrame = 2;
        streamDescription.mFramesPerPacket = 1;
        streamDescription.mBitsPerChannel = 8 * 2;
        streamDescription.mReserved = 0;
    }
    return self;
}

- (void)startSendData:(NSNumber *)data completeHander:(void (^)(NSError *))completeHander
{
    self.completeHander = completeHander;
    [self generateSamplesWithNumber:[data longLongValue]];
    byteIndex = codeIndex = 0;

    AudioQueueNewOutput(
                        &streamDescription,
                        AudioQueueOutputBufferCallback,
                        (__bridge void *)(self),
                        NULL,
                        NULL,
                        0,
                        &audioQueue
                        );
    
    for (int i = 0; i< kNumberBuffers; i++) {
        AudioQueueAllocateBuffer(audioQueue, 1000, &audioQueueBuffer[i]);
        [self generateTone:audioQueueBuffer[i]];
        AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer[i], 0, nil);
    }
    
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    AudioQueueStart(audioQueue, nil);
    isRunning = YES;
}

- (void)stopSendData
{
    isRunning = NO;
    for (int i = 0; i < kNumberBuffers; i++) {
        AudioQueueFreeBuffer(audioQueue, audioQueueBuffer[i]);
    }
}

#pragma mark - Private
- (void)generateSamplesWithNumber:(unsigned long long)number
{
    byteArr[0] = 10;
    for (int i=1; i<6; i++){
        byteArr[i] = (int)((number>>(8*(5-i)))&0xFF);
    }
    double baseAng = 0;
    double baseInc = (2 * M_PI) * 50 / 44100;
    double ang = 0;
    double incs;
    for (int i = 0; i < 4; i++) {
        incs = (2 * M_PI) * freqs[i] / 44100;
        ang = 0;
        baseAng = 0;
        int smapleRate = kSampleRate / 100;
        for (int j = 0; j < smapleRate; j++){
            samples[i][j] = (short)((sin(ang)*SHRT_MAX*fabs(sin(baseAng)))/8);
            ang += incs;
            baseAng += baseInc;
        }
    }
}


- (void)generateTone:(AudioQueueBufferRef)buffer
{
    SInt16 *p = buffer->mAudioData;
    for (int i = 0; i < 441; i++) {
        p[i] = samples[(int)((byteArr[byteIndex]>>(2*codeIndex)&3))][i];
    }
    codeIndex ++;
    if (codeIndex == 4){
        codeIndex = 0;
        byteIndex ++;
    }
    if (byteIndex == 6){
        byteIndex = 0;
        codeIndex = 0;
    }
    buffer->mAudioDataByteSize = 882;
}

@end


#pragma mark - 
void AudioQueueOutputBufferCallback(void *data, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    SonicWaveRequest *request = (__bridge SonicWaveRequest *)data;
    if (!request->isRunning) {
        AudioQueueStop(inAQ, YES);
        AudioQueueReset(inAQ);
        return;
    }
    [request generateTone:inBuffer];
    OSStatus err = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil);
    if (err != noErr) {
        NSLog(@"AudioQueueEnqueueBuffer() error: %d", err);
    }
}

