//
//  TunaGenerator.h
//  SoundTool
//
//  Created by kaichuan on 5/4/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SonicWaveRequest : NSObject

- (void)startSendData:(NSNumber *)data completeHander:(void (^)(NSError *))completeHander;
- (void)stopSendData;

@end
