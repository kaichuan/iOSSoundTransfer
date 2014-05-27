//
//  TunaSoundToolViewController.m
//  SoundTool
//
//  Created by kaichuan on 5/4/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import "ViewController.h"

#import <AudioToolbox/AudioToolbox.h>

#import "TunaGenerator.h"
#import "TunaReceiver.h"

@interface ViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *gNumber;
@property (weak, nonatomic) IBOutlet UISwitch *gSwitch;
@property (weak, nonatomic) IBOutlet UITextField *rNumber;
@property (weak, nonatomic) IBOutlet UISwitch *rSwitch;

@property (strong) TunaGenerator *generator;
@property (strong) TunaReceiver *receiver;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.gNumber setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTextField:) name:@"TunaReceivedData" object:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)updateTextField:(NSNotification *)n
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    self.rNumber.text = [[n object] stringValue];
}

- (IBAction)gSwitched:(id)sender {
    if (((UISwitch*)sender).on) {
        self.generator = [[TunaGenerator alloc] init:self.gNumber.text];
        [self.generator execute];
    }else{
        [self.generator stop];
        
    }
    
}
- (IBAction)rSwitched:(id)sender {
    if (((UISwitch*)sender).on) {
        self.receiver = [[TunaReceiver alloc] init];
        [self.receiver execute];
    }else{
        [self.receiver stop];
        
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    
    if(newLength > 11){
        return NO;
    }
    if (newLength == 11){
        self.gSwitch.enabled = YES;
    }else{
        self.gSwitch.enabled = NO;
    }
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    NSString *filteredstring  = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    return ([string isEqualToString:filteredstring]);
}

@end
