//
//  ViewController.m
//  RemoteLogClient
//
//  Created by Dmytro Yaropovetsky on 2/16/16.
//  Copyright © 2016 Dmytro Yaropovetsky. All rights reserved.
//

#import "ViewController.h"
#import "sockets.h"

@interface ViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.statusLabel.text = [[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle] stringByAppendingString:@"\n"];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.messageTextField becomeFirstResponder];
}

- (IBAction)sendAction:(id)sender {
	RLLog(self.messageTextField.text.UTF8String);
	self.statusLabel.text = [self.statusLabel.text stringByAppendingFormat:@"%@\n", self.messageTextField.text];
	self.messageTextField.text = @"";
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self sendAction:textField];
	return NO;
}

@end
