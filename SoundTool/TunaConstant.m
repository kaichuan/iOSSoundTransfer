//
//  TunaConstant.m
//  SoundTool
//
//  Created by kaichuan on 5/25/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//
#import "TunaConstant.h"

const int FREQUENCIES[] = {17700,17900,18100,18300};

const AudioStreamBasicDescription mDataFormat = {
    SAMPLE_RATE,
    kAudioFormatLinearPCM,
    kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
    2,1,2,1,16,0
};
