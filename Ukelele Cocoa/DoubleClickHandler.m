//
//  DoubleClickHandler.m
//  Ukelele 3
//
//  Created by John Brownie on 30/04/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "DoubleClickHandler.h"
#import "UKKeyboardController.h"
#import "ChooseDeadKeyHandling.h"
#import "LayoutInfo.h"
#import "UkeleleConstantStrings.h"
#import "XMLCocoaUtilities.h"
#import "ToolboxData.h"
#import "HandleDeadKeyController.h"
#import "ChooseStateController.h"

enum ProcessingStates {
	kProcessingNone = 0,
	kProcessingReplaceOutput = 1,
	kProcessingReplaceTerminator = 2,
	kProcessingChangeToOutput = 3,
	kProcessingCompleted = 4
};

@implementation DoubleClickHandler {
	NSMutableDictionary *keyDataDict;
	NSString *currentOutput;
	NSString *nextState;
	NSUInteger processingState;
	UkeleleKeyboardObject *keyboardObject;
	NSWindow *parentWindow;
    id<UKInteractionCompletion> completionTarget;
    id<UKInteractionHandler> subsidiaryHandler;
    AskTextSheet *askTextSheet;
	NSPopover *editPopover;
	EditKeyPopoverController *popoverController;
	DoubleClickDeadKeyType deadKeyProcessingType;
}

#pragma mark Entry

- (id)initWithData:(NSMutableDictionary *)dataDict
	keyboardLayout:(UkeleleKeyboardObject *)keyboardLayout
			window:(NSWindow *)window
{
	self = [super init];
	if (self) {
		keyDataDict = dataDict;
		keyboardObject = keyboardLayout;
		parentWindow = window;
		currentOutput = nil;
        completionTarget = nil;
        askTextSheet = nil;
		processingState = kProcessingNone;
		editPopover = nil;
		popoverController = nil;
		deadKeyProcessingType = kDoubleClickDeadKeyAsk;
	}
	return self;
}


- (void)setCompletionTarget:(id<UKInteractionCompletion>)target
{
    completionTarget = target;
}

- (void)setDeadKeyProcessingType:(DoubleClickDeadKeyType)theType {
	deadKeyProcessingType = theType;
}

- (void)openPane:(NSString *)promptString initialValue:(NSString *)valueString action:(SEL)actionSelector
{
	[[keyDataDict valueForKey:kKeyDocument] setMessageBarText:promptString];
	[[keyDataDict valueForKey:kKeyDocument] showEditingPaneForKeyCode:[[keyDataDict valueForKey:kKeyKeyCode] intValue]
																 text:valueString
															   target:self
															   action:actionSelector];
}

- (void)openSheet:(NSString *)promptString initialValue:(NSString *)valueString action:(UKSheetCompletionBlock)callBack
{
	if (!askTextSheet) {
		askTextSheet = [AskTextSheet askTextSheet];
	}
	[askTextSheet beginAskText:promptString	
					 minorText:@""
				   initialText:valueString
					 forWindow:parentWindow
					  callBack:callBack];
}

- (void)openPopover:(NSString *)promptString
	   initialValue:(NSString *)valueString
	 standardPrompt:(NSString *)standardPrompt
	standardEnabled:(BOOL)standardEnabled
		   callBack:(void (^)(NSString *))theCallBack
{
	if (editPopover == nil) {
		editPopover = [[NSPopover alloc] init];
	}
	if (popoverController == nil) {
		popoverController = [[EditKeyPopoverController alloc] initWithNibName:@"EditKeyPopover" bundle:nil];
	}
	[editPopover setDelegate:self];
	[editPopover setContentViewController:popoverController];
	[editPopover setBehavior:NSPopoverBehaviorTransient];
	NSRect keyRect = [[keyDataDict valueForKey:kKeyDocument] keyRect:[[keyDataDict valueForKey:kKeyKeyCode] intValue]];
	NSView *keyView = [[keyDataDict valueForKey:kKeyDocument] keyboardView];
	[editPopover showRelativeToRect:keyRect ofView:keyView preferredEdge:NSMinXEdge];
	[[popoverController promptField] setStringValue:promptString];
	[[popoverController standardOutputField] setStringValue:standardPrompt];
	[popoverController setCallBack:theCallBack];
	[[popoverController standardButton] setEnabled:standardEnabled];
	[[popoverController outputField] setStringValue:valueString];
}

- (void)askNewOutput {
	BOOL usingPopover = [[NSUserDefaults standardUserDefaults] boolForKey:UKUsesPopover];
	BOOL usingPane = !usingPopover;
	BOOL specialKey = [LayoutInfo getKeyType:[[keyDataDict valueForKey:kKeyKeyCode] intValue]] == kSpecialKeyType;
    NSString *promptString;
    if (usingPane) {
		if (specialKey) {
				// Get the standard output for the key
			NSString *standardOutput = [LayoutInfo getSpecialKeyOutput:[[keyDataDict valueForKey:kKeyKeyCode] intValue]];
			NSString *baseString = NSLocalizedStringFromTable(@"Enter new output. The standard output is %@",
															  @"dialogs", @"Ask new output for special key");
			promptString = [NSString stringWithFormat:baseString, standardOutput];
		}
		else {
			promptString = NSLocalizedStringFromTable(@"Enter the new output string", @"dialogs",
													  @"Ask user to enter new output");
		}
		processingState = deadKeyProcessingType == kDoubleClickDeadKeyChangeToOutput ? kProcessingChangeToOutput : kProcessingReplaceOutput;
		[self openPane:promptString initialValue:currentOutput action:@selector(acceptTextField:)];
	}
	else if (usingPopover) {
			// Use the popover
		promptString = NSLocalizedStringFromTable(@"Enter the new output string", @"dialogs",
												  @"Ask user to enter new output");
		NSString *standardPrompt = @"";
		if (specialKey) {
			NSString *specialFormat = NSLocalizedStringFromTable(@"Standard output is %@", @"dialogs", @"Inform user what the standard output is");
			standardPrompt = [NSString stringWithFormat:specialFormat,
							  [LayoutInfo getSpecialKeyOutput:[[keyDataDict valueForKey:kKeyKeyCode] intValue]]];
		}
		[self openPopover:promptString
			 initialValue:currentOutput
		   standardPrompt:standardPrompt
		  standardEnabled:specialKey
				 callBack:^(NSString *newOutput) {
					 [self acceptAskText:newOutput];
				 }];
	}
	else {
			// Open a sheet for editing the output
		if (specialKey) {
			NSString *standardOutput = [LayoutInfo getSpecialKeyOutput:[[keyDataDict valueForKey:kKeyKeyCode] intValue]];
			NSString *askText = NSLocalizedStringFromTable(@"Enter the new output string.\nThe standard output is %@",
														   @"dialogs", @"Ask user to enter new output");
			promptString = [NSString stringWithFormat:askText, standardOutput];
		}
		else {
			promptString = NSLocalizedStringFromTable(@"Enter the new output string", @"dialogs",
													  @"Ask user to enter new output");
		}
		[self openSheet:promptString initialValue:currentOutput action:^(NSString *theText) {
			if (theText == nil) {
					// User pressed cancel
			}
			else if (deadKeyProcessingType == kDoubleClickDeadKeyChangeToOutput) {
					// User provided text, but it was a dead key
				[[keyDataDict valueForKey:kKeyDocument] makeDeadKeyOutput:keyDataDict output:theText];
			}
			else {
					// User provided text
				[[keyDataDict valueForKey:kKeyDocument] changeOutputForKey:keyDataDict
																		to:theText
															  usingBaseMap:![[ToolboxData sharedToolboxData] JISOnly]];
			}
			processingState = kProcessingCompleted;
			[self interactionCompleted];
		}];
	}
}

- (void)startDoubleClick
{
	BOOL deadKey;
	NSString *nextDeadKeyState = nil;
	NSString *outputString = [keyboardObject getCharOutput:keyDataDict isDead:&deadKey nextState:&nextDeadKeyState];
	currentOutput = [XMLCocoaUtilities makeXMLString:outputString codingNonAscii:NO];
	if (deadKey && deadKeyProcessingType != kDoubleClickDeadKeyChangeToOutput) {
			// Handle a dead key click
		nextState = nextDeadKeyState;
		__block HandleDeadKeyController *deadKeyHandler = [HandleDeadKeyController handleDeadKeyController];
		[deadKeyHandler beginInteractionWithWindow:parentWindow document:keyboardObject forState:keyDataDict[kKeyState] nextState:nextState completionBlock:^(NSDictionary *dataDict) {
			if (dataDict == nil) {
					// Cancel
				[self interactionCompleted];
				deadKeyHandler = nil;
				return;
			}
			HandleDeadKeyType theType = [dataDict[kHandleDeadKeyType] integerValue];
			switch (theType) {
				case kHandleDeadKeyChangeState:
						// Change the state the dead key triggers
					break;
					
				case kHandleDeadKeyChangeTerminator:
						// Change the terminator
					break;
					
				case kHandleDeadKeyChangeToOutput:
						// Change the dead key to output
					[self askNewOutput];
					break;
					
				case kHandleDeadKeyEnterState:
						// Enter the dead key state
					[[keyDataDict valueForKey:kKeyDocument] enterDeadKeyStateWithName:nextState];
					[self interactionCompleted];
					break;
			}
			deadKeyHandler = nil;
		}];
//		ChooseDeadKeyHandling *chooseHandler = [[ChooseDeadKeyHandling alloc] init];
//        [chooseHandler setCompletionTarget:self];
//		[chooseHandler startWithWindow:parentWindow callBack:^(NSInteger choice) {
//			[self acceptChoiceFrom3:choice];
//		}
//							   choices:3];
//        subsidiaryHandler = chooseHandler;
	}
	else {
        [self askNewOutput];
	}
}

#pragma mark Popover delegate

- (void)popoverWillClose:(NSNotification *)notification
{
	if (processingState != kProcessingCompleted) {
		processingState = kProcessingCompleted;
		[self interactionCompleted];
	}
}

#pragma mark Simple replacement of output

- (void)acceptAskText:(NSString *)theText
{
	if (theText == nil) {
			// User pressed cancel
	}
	else if (deadKeyProcessingType == kDoubleClickDeadKeyChangeToOutput) {
			// User provided text, but it was a dead key
		[[keyDataDict valueForKey:kKeyDocument] makeDeadKeyOutput:keyDataDict output:theText];
	}
	else {
			// User provided text
		[[keyDataDict valueForKey:kKeyDocument] changeOutputForKey:keyDataDict
																to:theText
													  usingBaseMap:![[ToolboxData sharedToolboxData] JISOnly]];
	}
	processingState = kProcessingCompleted;
	[self interactionCompleted];
}

- (void)acceptTextField:(id)sender
{
    UKKeyboardController *theDocumentWindow = [keyDataDict valueForKey:kKeyDocument];
	[theDocumentWindow setMessageBarText:@""];
	if (sender) {
		NSString *theText = [sender stringValue];
		switch (processingState) {
			case kProcessingReplaceOutput:
				if (![theText isEqualToString:currentOutput]) {
					[theDocumentWindow changeOutputForKey:keyDataDict
												 to:theText
									   usingBaseMap:![[ToolboxData sharedToolboxData] JISOnly]];
				}
				break;
				
			case kProcessingReplaceTerminator:
				if (![theText isEqualToString:[keyboardObject getTerminatorForState:nextState]]) {
					[[keyDataDict valueForKey:kKeyDocument] changeTerminatorForState:nextState to:theText];
				}
				break;
				
			case kProcessingChangeToOutput:
				[[keyDataDict valueForKey:kKeyDocument] makeDeadKeyOutput:keyDataDict output:theText];
				break;
		}
	}
	[sender removeFromSuperview];
	[theDocumentWindow messageEditPaneClosed];
	processingState = kProcessingCompleted;
	[self interactionCompleted];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
	if (commandSelector == @selector(complete:) || commandSelector == @selector(cancelOperation:)) {
        UKKeyboardController *theDocumentWindow = [keyDataDict valueForKey:kKeyDocument];
		[control removeFromSuperview];
		[theDocumentWindow messageEditPaneClosed];
		[theDocumentWindow setMessageBarText:@""];
		[self interactionCompleted];
		return YES;
	}
	return NO;
}

#pragma mark Handle dead keys

- (void)acceptChoiceFrom3:(NSInteger)choice
{
	NSString *majorText = nil;
	NSString *terminatorString = nil;
	UKSheetCompletionBlock theCallBack = nil;
	switch (choice) {
		case -1:
				// User pressed cancel, so nothing to do
			[self interactionCompleted];
			return;

		case 0: {
				// Change terminator
			majorText = @"Enter the new terminator";
			terminatorString = [keyboardObject getTerminatorForState:nextState];
			theCallBack = ^(NSString *newTerminator) {
				if (newTerminator == nil) {
						// User cancelled
				}
				else {
					[[keyDataDict valueForKey:kKeyDocument] changeTerminatorForState:nextState to:newTerminator];
				}
				processingState = kProcessingCompleted;
				[self interactionCompleted];
			};
			processingState = kProcessingReplaceTerminator;
			break;
		}
		case 1: {
				// Convert to output
			majorText = @"Enter the new output";
			terminatorString = @"";
			theCallBack = ^(NSString *newOutput) {
				if (newOutput == nil) {
						// User cancelled
				}
				else {
					[[keyDataDict valueForKey:kKeyDocument] makeDeadKeyOutput:keyDataDict output:newOutput];
				}
				processingState = kProcessingCompleted;
				[self interactionCompleted];
			};
			processingState = kProcessingChangeToOutput;
			break;
		}
			
		case 2:
				// Enter dead key state
			[[keyDataDict valueForKey:kKeyDocument] enterDeadKeyStateWithName:nextState];
			[self interactionCompleted];
			return;
	}
	BOOL usingPopover = [[NSUserDefaults standardUserDefaults] boolForKey:UKUsesPopover];
	BOOL usingPane = !usingPopover;
	if (usingPane) {
		[self openPane:majorText initialValue:terminatorString action:@selector(acceptTextField:)];
	}
	else if (usingPopover) {
		[self openPopover:majorText initialValue:terminatorString standardPrompt:@"" standardEnabled:NO callBack:theCallBack];
	}
	else {
		[self openSheet:majorText initialValue:terminatorString action:theCallBack];
	}
}

- (void)askNewTerminator {
	BOOL usingPopover = [[NSUserDefaults standardUserDefaults] boolForKey:UKUsesPopover];
	BOOL usingPane = !usingPopover;
	UKSheetCompletionBlock theCallback = ^(NSString *newTerminator) {
		if (newTerminator != nil) {
			[keyDataDict[kKeyDocument] changeTerminatorForState:nextState to:newTerminator];
		}
		processingState = kProcessingCompleted;
		[self interactionCompleted];
	};
	NSString *promptString = @"Enter the new terminator";
	NSString *terminatorString = [keyboardObject getTerminatorForState:nextState];
	if (usingPane) {
		[self openPane:promptString initialValue:terminatorString action:@selector(acceptTextField:)];
	}
	else if (usingPopover) {
		[self openPopover:promptString initialValue:terminatorString standardPrompt:@"" standardEnabled:NO callBack:theCallback];
		processingState = kProcessingReplaceTerminator;
	}
	else {
		[self openSheet:promptString initialValue:terminatorString action:theCallback];
	}
}

- (void)askNewState {
	__block ChooseStateController *theController = [ChooseStateController chooseStateController];
	NSArray *stateNames = [keyboardObject stateNamesExcept:kStateNameNone];
	[theController setStateNames:stateNames];
	[theController askStateForWindow:parentWindow completionBlock:^(NSString *newState) {
		if (newState != nil) {
			[keyDataDict[kKeyDocument] changeDeadKeyNextState:keyDataDict newState:newState];
		}
		processingState = kProcessingCompleted;
		[self interactionCompleted];
		theController = nil;
	}];
}

- (void)acceptNewTerminator:(NSString *)newTerminator
{
	if (newTerminator == nil) {
			// User cancelled
	}
	else {
		[[keyDataDict valueForKey:kKeyDocument] changeTerminatorForState:nextState to:newTerminator];
	}
	processingState = kProcessingCompleted;
	[self interactionCompleted];
}

- (void)acceptNewOutput:(NSString *)newOutput
{
	if (newOutput == nil) {
			// User cancelled
	}
	else {
		[[keyDataDict valueForKey:kKeyDocument] makeDeadKeyOutput:keyDataDict output:newOutput];
	}
	processingState = kProcessingCompleted;
	[self interactionCompleted];
}

- (void)interactionCompleted
{
    [completionTarget interactionDidComplete:self];
}

- (void)interactionDidComplete:(id<UKInteractionHandler>)handler
{
    NSAssert(handler == subsidiaryHandler, @"Wrong handler passed");
    subsidiaryHandler = nil;
}

- (void)handleMessage:(NSDictionary *)messageData
{
		// We don't handle any messages at this point
}

@end
