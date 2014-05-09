//
//  ChooseStateController.h
//  Ukelele 3
//
//  Created by John Brownie on 18/09/13.
//
//

#import <Cocoa/Cocoa.h>

@interface ChooseStateController : NSWindowController

@property (strong) IBOutlet NSComboBox *stateList;
@property (strong) NSArray *stateNames;

+ (ChooseStateController *)chooseStateController;

- (void)askStateForWindow:(NSWindow *)parentWindow completionBlock:(void (^)(NSString *))callBack;

- (IBAction)acceptState:(id)sender;
- (IBAction)cancelState:(id)sender;

@end
