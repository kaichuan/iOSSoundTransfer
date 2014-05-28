//
//  TunaReceiver.h
//  SoundTool
//
//  Created by kaichuan on 5/25/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SonicWaveResponder : NSObject

- (void)startRecevieDataWithCompleteHander:(void (^)(NSNumber *))completeHander;
- (void)stopReceviceData;

@end
