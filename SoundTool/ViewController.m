//
//  TunaSoundToolViewController.m
//  SoundTool
//
//  Created by kaichuan on 5/4/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import "ViewController.h"

#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

#import "SonicWaveRequest.h"
#import "SonicWaveResponder.h"

@interface ViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UISwitch *sendSwitch;
@property (weak, nonatomic) IBOutlet UITextField *receviceTextField;
@property (weak, nonatomic) IBOutlet UISwitch *receviceSwitch;

@property (strong, nonatomic) SonicWaveRequest *waveRequest;
@property (strong, nonatomic) SonicWaveResponder *waveResponder;
@property (nonatomic, strong) MPMoviePlayerController *player;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    self.player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SendingData" ofType:@"wav"]]];
    
    self.waveRequest = [[SonicWaveRequest alloc] init];
    self.waveResponder = [[SonicWaveResponder alloc] init];
    
    [self.sendTextField setDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playBackgroundMusic
{
    [self.player play];
}

- (IBAction)gSwitched:(id)sender {
    [self.sendTextField resignFirstResponder];
    if (((UISwitch*)sender).on) {
        [self.waveRequest startSendData:@([self.sendTextField.text longLongValue]) completeHander:nil];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:7
                                         target:self
                                             selector:@selector(playBackgroundMusic)
                                       userInfo:nil
                                        repeats:YES];
        [self.timer fire];
    }else{
        [self.waveRequest stopSendData];
        [self.timer invalidate];
        [self.player pause];
    }

}
- (IBAction)rSwitched:(id)sender {
    if (((UISwitch*)sender).on) {
        [self.waveResponder startRecevieDataWithCompleteHander:^(NSNumber *number) {
            self.receviceTextField.text = [number stringValue];
            self.receviceSwitch.on = NO;
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }];
    }else{
        [self.waveResponder stopReceviceData];
        
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    
    if(newLength > 11){
        return NO;
    }
    if (newLength == 11){
        self.sendSwitch.enabled = YES;
    }else{
        self.sendSwitch.enabled = NO;
    }
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    NSString *filteredstring  = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    return ([string isEqualToString:filteredstring]);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
