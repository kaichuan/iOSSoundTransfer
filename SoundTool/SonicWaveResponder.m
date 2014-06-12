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

static char const kNumberOfBuffers = 3;
static char const kDelimiter = 10;

static int const kSampleRate = 44100;
static int const kFftSize = 441;


static bool isDecording = false;
static bool isRunning = false;
static bool isDisposed = false;

static float fEnergy = 0;
static float fMaxEnergy = 0;
static float fSecEnergy = 0;


static char cDecoded = 0;
static char cRunDelimiter = 0;
static short sOffset = 0;

static char cCodeIndex = 0;
static char cByteIndex = 0;

static long long lResult = 0;

static int const targetBins[4] = { 177, 179, 181, 183 };
static short aOffsetBuffer[kFftSize];
static short aBuffer[kFftSize];
static SInt16 *buffer;


static kiss_fft_cfg cfg;
static kiss_fft_cpx *cx_in;
static kiss_fft_cpx *cx_out;
static AudioStreamBasicDescription dataDescription;
static AudioQueueRef audioQueue;
static AudioQueueBufferRef mBuffers[kNumberOfBuffers];




static void AudioQueueInputBufferCallback (void *userData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription  *inPacketDesc);


#pragma mark -
@interface SonicWaveResponder () {
@public
    
}
@property (nonatomic, copy) void (^completeHander)(NSNumber *number);
@end

@implementation SonicWaveResponder

- (void)dispose
{
    if (!isDisposed){
        isDisposed = true;
        kiss_fft_cleanup();
        for (int i = 0; i < kNumberOfBuffers; i++) {
            AudioQueueFreeBuffer(audioQueue, mBuffers[i]);
        }
        AudioQueueStop(audioQueue, true);
        AudioQueueReset(audioQueue);
        AudioQueueDispose(audioQueue, true);
    }
}

- (void)stopReceviceData
{
    isRunning = NO;
}

- (void)resetData
{
    
    fMaxEnergy = fSecEnergy = cCodeIndex = cByteIndex = lResult = 0;
    isDecording = false;
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
    isRunning = YES;
    AudioQueueStart(audioQueue, NULL);
    
};
@end


#pragma mark -
void AudioQueueInputBufferCallback (void *userData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc) {
    
    SonicWaveResponder *responder = (__bridge SonicWaveResponder *)userData;
    if (!isRunning){
        [responder dispose];
        return;
    }
    if ( inNumPackets == kFftSize ) {
        
        buffer = inBuffer->mAudioData;
        
        for (int i = 0; i < kFftSize - sOffset; i++) {
            cx_in[i].r = aOffsetBuffer[i];
            cx_in[i].i = 0;
        }
        
        for (int i = 0; i < sOffset; i++) {
            cx_in[ i + kFftSize - sOffset ].r = buffer[i];
            cx_in[ i + kFftSize - sOffset ].i = 0;
        }
        
        for (int i = 0; i < kFftSize - sOffset; i++) {
            aOffsetBuffer[i] = buffer[ i + sOffset ];
        }
        
        
        kiss_fft(cfg, cx_in, cx_out);
        
        fMaxEnergy = 0;
        fSecEnergy = 0;
        
        for (int i = 0; i < 4; i++) {
            fEnergy = sqrt(powf(cx_out[targetBins[i]].r, 2)+ powf(cx_out[targetBins[i]].i, 2));
            if (fMaxEnergy < fEnergy) {
                fSecEnergy = fMaxEnergy;
                fMaxEnergy = fEnergy;
                cDecoded = i;
            } else if (fEnergy > fSecEnergy) {
                fSecEnergy = fEnergy;
            }
        }
        //    NSLog(@"%f", fMaxEnergy);
        
        if (fMaxEnergy < 5000) {
            [responder resetData];
            AudioQueueEnqueueBuffer(inAQ,inBuffer,0,NULL);
            return;
        }
        
        if (fMaxEnergy / fSecEnergy < 2) {
            sOffset += 44;
            sOffset = sOffset % kFftSize;
            [responder resetData];
            AudioQueueEnqueueBuffer(inAQ,inBuffer,0,NULL);
            return;
        }
        
        if (!isDecording) {
            cRunDelimiter = ( cRunDelimiter << 2 ) | cDecoded;
            if ( cRunDelimiter == kDelimiter ) {
                [responder resetData];
                isDecording = true;
                AudioQueueEnqueueBuffer(inAQ,inBuffer,0,NULL);
                return;
            }
        }
        else{
            NSLog(@"%d : %lld", cDecoded, lResult);
            lResult = lResult | cDecoded;
            if (cCodeIndex == 19) {
                NSLog(@"%lld", lResult);
                if (responder.completeHander) {
                    responder.completeHander(@(lResult));
                }
                isRunning = false;
                [responder resetData];
                return;
            }else {
                lResult = lResult << 2;
                cCodeIndex ++ ;
            }

            
        }
        AudioQueueEnqueueBuffer(inAQ,inBuffer,0,NULL);
        
    } else {
        [responder resetData];
        AudioQueueEnqueueBuffer(inAQ,inBuffer,0,NULL);
    }
    
};
