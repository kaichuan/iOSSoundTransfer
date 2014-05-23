//
//  TunaGenerator.h
//  SoundTool
//
//  Created by kaichuan on 5/4/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TunaGenerator : NSObject
-(id)init:(NSString *) data;
-(void)execute;
-(void)stop;

@end
