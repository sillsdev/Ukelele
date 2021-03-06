//
//  PrintAccessoryPanel.m
//  Ukelele 3
//
//  Created by John Brownie on 3/12/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "PrintAccessoryPanel.h"

@implementation PrintAccessoryPanel

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (PrintAccessoryPanel *)printAccessoryPanel {
	PrintAccessoryPanel *panel = [[PrintAccessoryPanel alloc] initWithNibName:@"PrintAccessoryPanel" bundle:nil];
	return panel;
}

- (IBAction)toggleAllStates:(id)sender {
#pragma unused(sender)
	[self.printView setAllStates:(BOOL)[allStates intValue]];
}

- (IBAction)toggleAllModifiers:(id)sender {
#pragma unused(sender)
	[self.printView setAllModifiers:(BOOL)[allModifiers intValue]];
}

- (NSArray *)localizedSummaryItems {
	return @[@{NSPrintPanelAccessorySummaryItemNameKey: @"All modifiers",
									  NSPrintPanelAccessorySummaryItemDescriptionKey: [allModifiers integerValue] != 0 ? @"Yes" : @"No"},
			@{NSPrintPanelAccessorySummaryItemNameKey: @"All states",
			 NSPrintPanelAccessorySummaryItemDescriptionKey: [allStates integerValue] != 0 ? @"Yes" : @"No"}];
}

- (NSSet *)keyPathsForValuesAffectingPreview {
	return [NSSet setWithObjects:@"printView.allStates", @"printView.allModifiers", nil];
}

@end
