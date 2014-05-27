//
//  TunaSoundToolViewController.m
//  SoundTool
//
//  Created by kaichuan on 5/4/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import "ViewController.h"

#import <AudioToolbox/AudioToolbox.h>

#import "SonicWaveRequest.h"
#import "SonicWaveResponder.h"

@interface ViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UISwitch *sendSwitch;
@property (weak, nonatomic) IBOutlet UITextField *receviceTextField;
@property (weak, nonatomic) IBOutlet UISwitch *receviceSwitch;

@property (strong) SonicWaveRequest *waveRequest;
@property (strong) SonicWaveResponder *waveResponder;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.waveRequest = [[SonicWaveRequest alloc] init];
//    self.waveResponder = [[SonicWaveResponder alloc] init];
    
    
    [self.sendTextField setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTextField:)
                                                 name:@"TunaReceivedData"
                                               object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)updateTextField:(NSNotification *)n
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    self.receviceTextField.text = [[n object] stringValue];
}

- (IBAction)gSwitched:(id)sender {
    [self.sendTextField resignFirstResponder];
    if (((UISwitch*)sender).on) {
        [self.waveRequest startSendData:@([self.sendTextField.text longLongValue]) completeHander:nil];
    }else{
        [self.waveRequest stopSendData];
    }
    
}
- (IBAction)rSwitched:(id)sender {
    if (((UISwitch*)sender).on) {
        [self.waveResponder execute];
    }else{
        [self.waveResponder stop];
        
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
