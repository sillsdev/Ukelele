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
    AskTextSheet *askTextSheet;
	NSPopover *editPopover;
	EditKeyPopoverController *popoverController;
	DoubleClickDeadKeyType deadKeyProcessingType;
}

#pragma mark Entry

- (instancetype)initWithData:(NSMutableDictionary *)dataDict
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
	[keyDataDict[kKeyDocument] setMessageBarText:promptString];
	[keyDataDict[kKeyDocument] showEditingPaneForKeyCode:[keyDataDict[kKeyKeyCode] intValue]
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
	 standardOutput:(NSString *)standardOutput
		   callBack:(void (^)(NSString *))theCallBack
{
	if (editPopover == nil) {
		editPopover = [[NSPopover alloc] init];
	}
	if (popoverController == nil) {
		popoverController = [EditKeyPopoverController popoverController];
	}
	[editPopover setDelegate:self];
	[editPopover setContentViewController:popoverController];
	[editPopover setBehavior:NSPopoverBehaviorTransient];
	[popoverController setMyPopover:editPopover];
	NSRect keyRect = [keyDataDict[kKeyDocument] keyRect:[keyDataDict[kKeyKeyCode] intValue]];
	NSView *keyView = [[keyDataDict[kKeyDocument] keyboardView] documentView];
	[editPopover showRelativeToRect:keyRect ofView:keyView preferredEdge:NSMinXEdge];
	[[popoverController promptField] setStringValue:promptString];
	[[popoverController standardOutputField] setStringValue:standardPrompt];
	[popoverController setCallBack:theCallBack];
	[[popoverController standardButton] setEnabled:standardEnabled];
	[[popoverController outputField] setStringValue:valueString];
	[popoverController setStandardOutput:standardOutput];
}

- (void)askNewOutput {
	BOOL usingPopover = [[NSUserDefaults standardUserDefaults] boolForKey:UKUsesPopover];
	BOOL usingPane = !usingPopover;
	BOOL specialKey = [LayoutInfo getKeyType:[keyDataDict[kKeyKeyCode] intValue]] == kSpecialKeyType;
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
		NSString *standardOutput = @"";
		if (specialKey) {
			standardOutput = [LayoutInfo getSpecialKeyOutput:[keyDataDict[kKeyKeyCode] intValue]];
			NSString *specialFormat = NSLocalizedStringFromTable(@"Standard output is %@", @"dialogs", @"Inform user what the standard output is");
			standardPrompt = [NSString stringWithFormat:specialFormat, standardOutput];
		}
		[self openPopover:promptString
			 initialValue:currentOutput
		   standardPrompt:standardPrompt
		  standardEnabled:specialKey
		   standardOutput:standardOutput
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
				[keyDataDict[kKeyDocument] makeDeadKeyOutput:keyDataDict output:theText];
			}
			else {
					// User provided text
				[keyDataDict[kKeyDocument] changeOutputForKey:keyDataDict
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
	NSString *outputString = [keyboardObject getCharOutput:keyDataDict
													isDead:&deadKey
												 nextState:&nextDeadKeyState];
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
					[keyDataDict[kKeyDocument] changeDeadKeyNextState:keyDataDict
															 newState:dataDict[kHandleDeadKeyString]];
					break;
					
				case kHandleDeadKeyChangeTerminator:
						// Change the terminator
					[keyDataDict[kKeyDocument] changeTerminatorForState:nextState
																	 to:dataDict[kHandleDeadKeyString]];
					break;
					
				case kHandleDeadKeyChangeToOutput:
						// Change the dead key to output
					[keyDataDict[kKeyDocument] makeDeadKeyOutput:keyDataDict
														  output:dataDict[kHandleDeadKeyString]];
					break;
					
				case kHandleDeadKeyEnterState:
						// Enter the dead key state
					[keyDataDict[kKeyDocument] enterDeadKeyStateWithName:nextState];
					break;
			}
			[self interactionCompleted];
			deadKeyHandler = nil;
		}];
	}
	else {
        [self askNewOutput];
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

#pragma mark Popover delegate

- (void)popoverWillClose:(NSNotification *)notification
{
#pragma unused(notification)
	if (processingState != kProcessingCompleted) {
		processingState = kProcessingCompleted;
		[self interactionCompleted];
	}
}

#pragma mark Simple replacement of output

- (void)acceptAskText:(NSString *)theText
{
	NSString *replacementText = [XMLCocoaUtilities convertEncodedString:theText];
	if (theText == nil) {
			// User pressed cancel
	}
	else if (deadKeyProcessingType == kDoubleClickDeadKeyChangeToOutput) {
			// User provided text, but it was a dead key
		[keyDataDict[kKeyDocument] makeDeadKeyOutput:keyDataDict output:replacementText];
	}
	else {
			// User provided text
		[keyDataDict[kKeyDocument] changeOutputForKey:keyDataDict
												   to:replacementText
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
					[keyDataDict[kKeyDocument] changeTerminatorForState:nextState to:theText];
				}
				break;
				
			case kProcessingChangeToOutput:
				[keyDataDict[kKeyDocument] makeDeadKeyOutput:keyDataDict output:theText];
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
#pragma unused(textView)
	if (commandSelector == @selector(complete:) || commandSelector == @selector(cancelOperation:)) {
        UKKeyboardController *theDocumentWindow = keyDataDict[kKeyDocument];
		[control removeFromSuperview];
		[theDocumentWindow messageEditPaneClosed];
		[theDocumentWindow setMessageBarText:@""];
		[self interactionCompleted];
		return YES;
	}
	return NO;
}

#pragma mark Interaction completion

- (void)interactionCompleted
{
    [completionTarget interactionDidComplete:self];
}

- (void)handleMessage:(NSDictionary *)messageData
{
#pragma unused(messageData)
		// We don't handle any messages at this point
}

- (void)cancelInteraction {
		// User cancelled
	[self interactionCompleted];
}

@end
