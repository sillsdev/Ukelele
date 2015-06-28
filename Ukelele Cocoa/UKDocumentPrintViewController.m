//
//  UKDocumentPrintViewController.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 16/02/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import "UKDocumentPrintViewController.h"

@interface UKDocumentPrintViewController ()

@end

@implementation UKDocumentPrintViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

+ (UKDocumentPrintViewController *)documentPrintViewController {
	return [[UKDocumentPrintViewController alloc] initWithNibName:@"UKDocumentPrintView" bundle:nil];
}

@end
