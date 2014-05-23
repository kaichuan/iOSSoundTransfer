//
//  TunaGenerator.m
//  SoundTool
//
//  Created by kaichuan on 5/4/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import "TunaGenerator.h"
#import <AudioToolbox/AudioToolbox.h>


// default buffer count, 3 is recommend
static const int kNumberBuffers = 3;
// save operation err code
int err;

// define Audio Format parameters
typedef struct AQPlayerState {
    AudioStreamBasicDescription   mDataFormat;                  // basic data format
    AudioQueueRef                 mQueue;                       // queue ref
    AudioQueueBufferRef           mBuffers[kNumberBuffers];     // buffer ref
    bool                          mIsRunning;
}AQPlayerState;

AQPlayerState *aqState;

int freqs[4] = {17700,17900,18100,18300};
int sampleCount = 441;
short samples[4][441];
int indexLength = 24;
int sIndex = 0;
int sIndexes[24];

bool isFirst = false;

//void generateTone(AudioQueueBufferRef buffer){
//    int sampleCount = buffer->mAudioDataBytesCapacity / sizeof (SInt16);
//    double incs = 2*M_PI*17000/44100;
//    double ang = 0;
//    SInt16 *p = buffer->mAudioData;
//    for (int i = 0; i < sampleCount; i++) {
//        p[i] = sin(ang) * SHRT_MAX;
//        ang += incs;
//    }
//    buffer->mAudioDataByteSize = sampleCount * sizeof (SInt16);
//}
void generateTone(AudioQueueBufferRef buffer){
    SInt16 *p = buffer->mAudioData;
    for (int i = 0; i < 441; i++) {
        if (isFirst){
            p[i] = samples[0][i];
        }else{
           p[i] = samples[3][i];
//            p[i] = 0;
        }
        
//        p[i] = samples[sIndexes[sIndex]][i];
    }
    
    buffer->mAudioDataByteSize = 882;
//    sIndex ++;
//    sIndex = sIndex % indexLength;
    if (isFirst){
        isFirst = false;
    }else{
        isFirst = true;
    }
}

static void HandleOutputBuffer (
                                void                 *aqState,               
                                AudioQueueRef        inAQ,                   
                                AudioQueueBufferRef  inBuffer
){
    AQPlayerState *mAqState = (AQPlayerState *) aqState;
    if (!mAqState->mIsRunning) {
        err = AudioQueueStop (inAQ, YES);
        if (err != noErr) NSLog(@"AudioQueueStop() errors: %d", err);
        AudioQueueDispose (inAQ,true);
        return;
    }
    generateTone(inBuffer);
    err = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil);
    if (err != noErr) NSLog(@"AudioQueueEnqueueBuffer() error: %d", err);

    
  
    
    
}

NSData* nsData;

@interface TunaGenerator()


@end

@implementation TunaGenerator



-(id)init:(NSString *) data{
    long long phoneNumber = [data longLongValue];
    NSData *phoneData = [NSData dataWithBytes:&phoneNumber length:sizeof(phoneNumber)];
    NSData *sendData = [phoneData subdataWithRange:NSMakeRange(3, 5)];
    //增加标记字段
    Byte marker = 10;
    Byte escaper = 88;
    NSUInteger length = [sendData length];
    NSMutableData *source = [[NSMutableData alloc] initWithBytes:&marker length:sizeof(marker)];
    for (NSUInteger i = 0; i < length; i++) {
        Byte byte;
        [sendData getBytes:&byte range:NSMakeRange(i, 1)];
        if (byte == marker) {
            [source appendBytes:&marker length:sizeof(marker)];
        }
        if (byte == escaper) {
            [source appendBytes:&escaper length:sizeof(escaper)];
        }
        [source appendBytes:&byte length:sizeof(byte)];
    }
//    const void* ds = source.bytes;
    double baseAng = 0;
    double baseInc = (2 * M_PI) * 50 / 44100;
    double ang = 0;
    double incs[4];
    for (int i = 0; i < 4; i++) {
        incs[i] = (2 * M_PI) * freqs[i] / 44100;
        ang = 0;
        baseAng = 0;
        for (int j = 0; j < sampleCount; j++){
            samples[i][j] = (short)((sin(ang)*SHRT_MAX*fabs(sin(baseAng)))/8);
            ang += incs[i];
            baseAng += baseInc;
        }
    }
    Byte byte;
    indexLength = 24;
    int k = 0;
    for (int i=0; i<source.length; i++){
        [source getBytes: &byte range:NSMakeRange(i, 1)];
        for (int j=0; j<4; j++,k++){
            sIndexes[k] = byte>>j*2&3;
        }
    }
    aqState = (AQPlayerState*)malloc(sizeof(AQPlayerState));
    // dataFormat init
    aqState->mDataFormat.mSampleRate = 44100;
    aqState->mDataFormat.mFormatID = kAudioFormatLinearPCM;
    aqState->mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    aqState->mDataFormat.mBytesPerPacket = 2;
    aqState->mDataFormat.mChannelsPerFrame = 1;
    
    aqState->mDataFormat.mBytesPerFrame = 2;
    aqState->mDataFormat.mFramesPerPacket = 1;
    aqState->mDataFormat.mBitsPerChannel = 8 * 2;
    aqState->mDataFormat.mReserved = 0;

    err = AudioQueueNewOutput(
                              &aqState->mDataFormat,
                              HandleOutputBuffer,
                              aqState,
                              NULL,
                              NULL,
                              0,
                              &aqState->mQueue
                              );
    if (err != noErr) NSLog(@"AudioQueueNewOutput() error: %d", err);
    
    for (int i=0; i<3; i++) {
        err = AudioQueueAllocateBuffer(aqState->mQueue,1000,&aqState->mBuffers[i]);
        if (err == noErr) {
            generateTone(aqState->mBuffers[i]);
            err = AudioQueueEnqueueBuffer(aqState->mQueue, aqState->mBuffers[i], 0, nil);
            if (err != noErr) NSLog(@"AudioQueueEnqueueBuffer() error: %d", err);
        } else {
            NSLog(@"AudioQueueAllocateBuffer() error: %d", err);
        }
    }
    
    
    Float32 gain = 1.0;                                      
    // Optionally, allow user to override gain setting here
    AudioQueueSetParameter (                                 
                            aqState->mQueue,                 
                            kAudioQueueParam_Volume,         
                            gain
                            );
    return [super init];
}




-(void)execute {
    aqState->mIsRunning = true;
    err = AudioQueueStart(aqState->mQueue, nil);
    if (err != noErr) {
        NSLog(@"AudioQueueStart() error: %d", err);
        aqState->mIsRunning = false;
    }
}
-(void)stop{
    printf("DDDD");
    NSLog(@"%d", [NSThread isMainThread]);

    aqState->mIsRunning = false;
    
    
}
@end
