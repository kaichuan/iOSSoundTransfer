//
//  TunaConstant.m
//  SoundTool
//
//  Created by kaichuan on 5/25/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//
#import "TunaConstant.h"

@implementation TunaConstant
const int FREQUENCIES[] = {17700,17900,18100,18300};

const AudioStreamBasicDescription mDataFormat = {
    SAMPLE_RATE,
    kAudioFormatLinearPCM,
    kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
    2,1,2,1,16,0
};

//AQState saqState = {
//    &mDataFormat,
//    
//};
//
//
//
//
//
//AQState *getInitState(){
//      AQState *aqState = (AQState*)malloc(sizeof(AQState));
//    //    aqState->mDataFormat.mSampleRate = SAMPLE_RATE;
////    aqState->mDataFormat.mFormatID = kAudioFormatLinearPCM;
////    aqState->mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
////    aqState->mDataFormat.mBytesPerPacket = 2;
////    aqState->mDataFormat.mChannelsPerFrame = 1;
////    aqState->mDataFormat.mBytesPerFrame = 2;
////    aqState->mDataFormat.mFramesPerPacket = 1;
////    aqState->mDataFormat.mBitsPerChannel = 8 * 2;
////    aqState->mDataFormat.mReserved = 0;
//    aqState->bufferByteSize  = FFT_SIZE * 2;
//    return aqState;
//};





@end
