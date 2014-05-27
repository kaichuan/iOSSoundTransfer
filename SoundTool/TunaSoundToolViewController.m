//
//  TunaSoundToolViewController.m
//  SoundTool
//
//  Created by kaichuan on 5/4/14.
//  Copyright (c) 2014 kaichuan. All rights reserved.
//

#import "TunaSoundToolViewController.h"
#import "TunaGenerator.h"
#import "TunaReceiver.h"
@interface TunaSoundToolViewController ()
@property (weak, nonatomic) IBOutlet UITextField *gNumber;
@property (weak, nonatomic) IBOutlet UISwitch *gSwitch;
@property (weak, nonatomic) IBOutlet UITextField *rNumber;

@property (weak, nonatomic) IBOutlet UISwitch *rSwitch;
@property (strong) TunaGenerator *generator;
@property (strong) TunaReceiver *receiver;

@end

@implementation TunaSoundToolViewController
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




- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.gNumber setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTextField:) name:@"TunaReceivedData" object:nil];
  
}

- (void)updateTextField:(NSNotification *)n
{
    self.rNumber.text = [[n object] stringValue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
