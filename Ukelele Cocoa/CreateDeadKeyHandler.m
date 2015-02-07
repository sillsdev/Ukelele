//
//  CreateDeadKeyHandler.m
//  Ukelele 3
//
//  Created by John Brownie on 14/11/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import "CreateDeadKeyHandler.h"
#import "UkeleleConstantStrings.h"
#import "UKKeyboardController.h"
#import "CreateDeadKeySheet.h"
#import "AskReplaceDeadKeySheet.h"
#import "WrongStateChosenSheet.h"
#import "ConfirmStateNameSheet.h"
#import "AskTextSheet.h"
#import "CreateSelectedDeadKeyController.h"
#import "UKKeyboardController+Housekeeping.h"
#import "UKKeyboardDocument.h"

	// Dictionary keys
NSString *kDeadKeyDataReplaceDeadKeyOK = @"ReplaceDeadKeyOK";
NSString *kDeadKeyDataReplaceTerminatorOK = @"ReplaceTerminatorOK";
NSString *kDeadKeyDataUseExistingStateOK = @"UseExistingStateOK";

@implementation CreateDeadKeyHandler {
	NSMutableDictionary *deadKeyData;
	NSString *currentState;
	NSUInteger currentModifiers;
	NSInteger currentKeyboardID;
	NSInteger selectedKeyCode;
	NSString *targetState;
	NSString *suppliedTerminator;
	CreateDeadKeyHandlerType typeCode;
	UKKeyboardController *parentDocumentWindow;
	UkeleleKeyboardObject *keyboardObject;
	NSWindow *parentWindow;
    id<UKInteractionCompletion> completionTarget;
	CreateDeadKeySheet *createSheet;
	CreateSelectedDeadKeyController *createWithSelectedSheet;
	AskReplaceDeadKeySheet *askReplaceSheet;
	WrongStateChosenSheet *wrongStateSheet;
	ConfirmStateNameSheet *confirmStateNameSheet;
	AskTextSheet *askTextSheet;
}

- (id)initWithCurrentState:(NSString *)stateName
				 modifiers:(NSUInteger)theModifiers
				keyboardID:(NSInteger)keyboardID
			keyboardWindow:(UKKeyboardController *)theDocumentWindow
				   keyCode:(NSInteger)keyCode
				 nextState:(NSString *)nextStateName
				terminator:(NSString *)theTerminator {
	if (self = [super init]) {
		
		currentState = stateName;
		parentDocumentWindow = theDocumentWindow;
		keyboardObject = [theDocumentWindow keyboardLayout];
		parentWindow = [theDocumentWindow window];
		currentModifiers = theModifiers;
		currentKeyboardID = keyboardID;
		selectedKeyCode = keyCode;
		targetState = nextStateName;
		suppliedTerminator = theTerminator;
		createSheet = nil;
		createWithSelectedSheet = nil;
		askReplaceSheet = nil;
		wrongStateSheet = nil;
		confirmStateNameSheet = nil;
		askTextSheet = nil;
			// Set the type code according to what was supplied
		if (selectedKeyCode == kNoKeyCode) {
				// No key code supplied, so start from scratch
			NSAssert(targetState == nil, @"No key code, but state %@ supplied", targetState);
			NSAssert(suppliedTerminator == nil, @"No key code, but terminator %@ supplied", suppliedTerminator);
			typeCode = kCreateDeadKeyHandlerNoParams;
		}
		else {
			if (targetState != nil) {
					// Have key code and state
				typeCode = kCreateDeadKeyHandlerKeyCodeState;
			}
			else {
					// Have key code but no state
				NSAssert(suppliedTerminator == nil, @"Key code, no state, but terminator %@ supplied", suppliedTerminator);
				typeCode = kCreateDeadKeyHandlerKeyCode;
			}
		}
	}
	return self;
}

- (void)startHandling
{
	if (typeCode == kCreateDeadKeyHandlerNoParams) {
			// Starting from no parameters
		createSheet = [CreateDeadKeySheet createDeadKeySheet];
		[createSheet beginCreateDeadKeySheet:keyboardObject
							   withModifiers:currentModifiers
									forState:currentState
								   forWindow:parentWindow
									callback:^(NSDictionary *createDeadKeyData) {
										if (!createDeadKeyData) {
												// User cancelled
											[self interactionCompleted];
											return;
										}
										deadKeyData = [createDeadKeyData mutableCopy];
										[self checkDeadKeyParameters];
									}];
	}
	else if (typeCode == kCreateDeadKeyHandlerKeyCode) {
			// Starting from key code only
		createWithSelectedSheet = [CreateSelectedDeadKeyController createSelectedDeadKeyController];
		[createWithSelectedSheet runSheetForWindow:parentWindow
										  keyboard:keyboardObject
										   keyCode:selectedKeyCode
								   completionBlock:^(NSDictionary *keyData) {
									   if (!keyData) {
											   // User cancelled
										   [self interactionCompleted];
										   return;
									   }
									   deadKeyData = [NSMutableDictionary dictionaryWithObject:keyData[kCreateSelectedDeadKeyState] forKey:kDeadKeyDataStateName];
									   deadKeyData[kCreateDeadKeySelectedKeyCode] = @(selectedKeyCode);
									   deadKeyData[kDeadKeyDataKeyCode] = @(selectedKeyCode);
									   deadKeyData[kDeadKeyDataModifiers] = @(currentModifiers);
									   [self checkDeadKeyParameters];
								   }];
	}
	else if (typeCode == kCreateDeadKeyHandlerKeyCodeState) {
			// Starting with complete parameters
		deadKeyData = [NSMutableDictionary dictionary];
		deadKeyData[kCreateDeadKeySelectedKeyCode] = @(selectedKeyCode);
		deadKeyData[kDeadKeyDataKeyCode] = @(selectedKeyCode);
		deadKeyData[kDeadKeyDataModifiers] = @(currentModifiers);
		deadKeyData[kDeadKeyDataStateName] = targetState;
		if (suppliedTerminator) {
			deadKeyData[kDeadKeyDataTerminator] = suppliedTerminator;
		}
		[self checkDeadKeyParameters];
	}
	else {
		NSLog(@"Unrecognised typeCode %d", (int)typeCode);
	}
}

- (void)setCompletionTarget:(id<UKInteractionCompletion>)theTarget
{
	completionTarget = theTarget;
}

#pragma mark Verification

- (void)checkDeadKeyParameters
{
		// Check that we have a valid state
	NSString *nextState = deadKeyData[kDeadKeyDataStateName];
	if ([nextState length] == 0) {
			// Can't have a state name that is the empty string
		if (askTextSheet == nil) {
			askTextSheet = [AskTextSheet askTextSheet];
		}
		NSString *majorText = NSLocalizedStringFromTable(@"Please give a valid name for the state name", @"dialogs", @"Ask for a valid string");
		NSString *minorText = NSLocalizedStringFromTable(@"A dead key state name cannot be the empty string", @"dialogs", @"Explain that name cannot be emtpy");
		[askTextSheet beginAskText:majorText
						 minorText:minorText
					   initialText:@""
						 forWindow:parentWindow
						  callBack:^(NSString *stateName) {
							  if (stateName == nil) {
									  // User cancelled
								  [self interactionCompleted];
								  return;
							  }
							  deadKeyData[kDeadKeyDataStateName] = stateName;
							  [self checkDeadKeyParameters];
						  }];
		return;
	}
	if (![UKKeyboardController isValidStateName:nextState]) {
		NSString *mainText = NSLocalizedStringFromTable(@"Please give a valid name for the state name", @"dialogs", @"Ask for a valid string");
		NSString *messageText = NSLocalizedStringFromTable(@"Names like none and 0 are not permitted", @"dialogs", @"Not a valid name");
		[askTextSheet beginAskText:mainText
						 minorText:messageText
					   initialText:@""
						 forWindow:parentWindow
						  callBack:^(NSString *stateName) {
							  if (stateName == nil) {
									  // User cancelled
								  [self interactionCompleted];
								  return;
							  }
							  deadKeyData[kDeadKeyDataStateName] = stateName;
							  [self checkDeadKeyParameters];
						  }];
		return;
	}
	if ([nextState isEqualToString:currentState]) {
			// Can't make the dead key go to the same state
		if (wrongStateSheet == nil) {
			wrongStateSheet = [WrongStateChosenSheet wrongStateChosenSheet];
		}
		NSSet *stateSet = [NSSet setWithObjects:currentState, kStateNameNone, nil];
		NSArray *stateArray = [keyboardObject stateNamesNotInSet:stateSet];
		[wrongStateSheet beginInteractionForWindow:parentWindow withStates:stateArray callBack:^(NSDictionary *replaceData) {
			[self acceptReplacementState:replaceData];
		}];
		return;
	}
	if ([nextState isEqualToString:kStateNameNone]) {
			// Next state should not be state "none"
		if (wrongStateSheet == nil) {
			wrongStateSheet = [WrongStateChosenSheet wrongStateChosenSheet];
		}
		NSSet *stateSet = [NSSet setWithObjects:currentState, kStateNameNone, nil];
		NSArray *stateArray = [keyboardObject stateNamesNotInSet:stateSet];
		NSString *wrongStateMessage = NSLocalizedStringFromTable(@"The dead key state cannot be the \"none\" state, as that state means no dead keys are active", @"dialogs", @"Explain that none is not a valid next state");
		[wrongStateSheet setMessage:wrongStateMessage];
		[wrongStateSheet beginInteractionForWindow:parentWindow withStates:stateArray callBack:^(NSDictionary *replaceData) {
			[self acceptReplacementState:replaceData];
		}];
		return;
	}
	
		// Now check that we have the key specified
	NSInteger keyCode = [deadKeyData[kDeadKeyDataKeyCode] integerValue];
	if (keyCode < 0) {
			// We have to wait to get the actual key, so we put a message up
		NSString *messageText = NSLocalizedStringFromTable(@"Please click or type the dead key", @"dialogs", @"Instruction to identify the dead key");
		[parentDocumentWindow setMessageBarText:messageText];
		return;
	}
	
		// Test key to see if it is already a dead key
	NSMutableDictionary *keyDataDictionary = [NSMutableDictionary dictionary];
	keyDataDictionary[kKeyKeyboardID] = @(currentKeyboardID);
	keyDataDictionary[kKeyState] = currentState;
	keyDataDictionary[kKeyKeyCode] = @(keyCode);
	keyDataDictionary[kKeyModifiers] = deadKeyData[kDeadKeyDataModifiers];
	if (deadKeyData[kDeadKeyDataTerminator]) {
		keyDataDictionary[kDeadKeyDataTerminator] = deadKeyData[kDeadKeyDataTerminator];
	}
	BOOL isDeadKey = [keyboardObject isDeadKey:keyDataDictionary];
	if (isDeadKey) {
			// It was already a dead key, so check that we really want this
			// It's OK if we have already checked
		if (deadKeyData[kDeadKeyDataReplaceDeadKeyOK] == nil ) {
			if (askReplaceSheet == nil) {
				askReplaceSheet = [AskReplaceDeadKeySheet askReplaceDeadKeySheet];
			}
			NSString *previousNextState = [keyboardObject getNextState:keyDataDictionary];
			NSString *previousTerminator = [keyboardObject getTerminatorForState:previousNextState];
			NSString *nextTerminator = @"";
			if ([deadKeyData[kDeadKeyDataTerminatorSpecified] boolValue]) {
				nextTerminator = deadKeyData[kDeadKeyDataTerminator];
			}
			if ([previousNextState isEqualToString:nextState] && [previousTerminator isEqualToString:nextTerminator]) {
					// We are not changing anything now, since the key was already set up this way
				[self interactionCompleted];
				return;
			}
				// Ask whether we want to replace a dead key
			NSString *messageString = NSLocalizedStringFromTable(@"The key you selected was already a dead key with next state \"%@\" and terminator \"%@\". Are you sure you want to replace it with the new next state \"%@\" and terminator \"%@\"?", @"dialogs", @"Prompt for dialog");
			[askReplaceSheet setMessage:[NSString stringWithFormat:messageString,
										 previousNextState, previousTerminator, nextState, nextTerminator]];
			[askReplaceSheet beginSheetWithCallBack:^(NSString *replaceData) {
				if (replaceData == nil) {
						// User cancelled
					[self interactionCompleted];
					return;
				}
				if ([kAskReplaceDeadKeyAccept isEqualToString:replaceData]) {
						// We accept the replacement of the dead key
					deadKeyData[kDeadKeyDataReplaceDeadKeyOK] = @YES;
					[self checkDeadKeyParameters];
				}
				else if (typeCode != kCreateDeadKeyHandlerNoParams) {
						// Rejected replacement, and we had a selected key, so cancel
					[self interactionCompleted];
					return;
				}
				else if ([kAskReplaceDeadKeyReject isEqualToString:replaceData]) {
						// We reject the replacement, so we need to ask for a new state
					deadKeyData[kDeadKeyDataKeyCode] = @(kNoKeyCode);
				}
			}
										  forWindow:parentWindow];
			return;
		}
		else {
				// What we need to do is to change the next state for the dead key
			[parentDocumentWindow changeDeadKeyNextState:keyDataDictionary newState:nextState];
				// Need to update keyboard view...
			[self interactionCompleted];
			return;
		}
	}
	
		// If all is OK, then we go to create
	BOOL existingState = [keyboardObject hasStateWithName:targetState];
	[parentDocumentWindow createNewDeadKey:keyDataDictionary nextState:nextState usingExistingState:existingState];
	[self interactionCompleted];
}

#pragma mark Callbacks

- (void)acceptCreateDeadKey:(NSDictionary *)createDeadKeyData
{
	if (!createDeadKeyData) {
			// User cancelled
		[self interactionCompleted];
		return;
	}
	deadKeyData = [createDeadKeyData mutableCopy];
	[self checkDeadKeyParameters];
}

- (void)acceptAskReplaceDeadKey:(NSString *)replaceData
{
	if (replaceData == nil) {
			// User cancelled
		[self interactionCompleted];
		return;
	}
	if ([kAskReplaceDeadKeyAccept isEqualToString:replaceData]) {
			// We accept the replacement of the dead key
		deadKeyData[kDeadKeyDataReplaceDeadKeyOK] = @YES;
		[self checkDeadKeyParameters];
	}
	else if ([kAskReplaceDeadKeyReject isEqualToString:replaceData]) {
			// We reject the replacement, so we need to ask for a new state
		deadKeyData[kDeadKeyDataKeyCode] = @(kNoKeyCode);
	}
}

- (void)acceptReplacementState:(NSDictionary *)replaceData
{
	if (replaceData == nil) {
			// User cancelled
		[self interactionCompleted];
		return;
	}
	deadKeyData[kDeadKeyDataStateName] = replaceData[kWrongStateName];
	deadKeyData[kDeadKeyDataStateType] = replaceData[kWrongStateType];
	NSDictionary *keyDataDictionary = @{kKeyKeyboardID: @(currentKeyboardID),
									   kKeyState: currentState,
									   kKeyKeyCode: deadKeyData[kDeadKeyDataKeyCode],
									   kKeyModifiers: deadKeyData[kDeadKeyDataModifiers]};
	if ([replaceData[kWrongStateType] integerValue] == kDeadKeyTypeNew) {
		deadKeyData[kDeadKeyDataTerminator] = [keyboardObject getNextState:keyDataDictionary];
	}
	[self checkDeadKeyParameters];
}

- (void)acceptConfirmStateName:(NSDictionary *)confirmData
{
	if (confirmData == nil) {
			// User cancelled
		[self interactionCompleted];
		return;
	}
	NSString *confirmType = confirmData[kConfirmStateType];
	if ([confirmType isEqualToString:kConfirmStateExisting]) {
			// User confirms we are to use the state name given
		deadKeyData[kDeadKeyDataStateType] = @(kDeadKeyTypeExisting);
	}
	else {
			// User has given a new state name
		deadKeyData[kDeadKeyDataStateName] = confirmData[kConfirmStateName];
	}
	[self checkDeadKeyParameters];
}

//- (void)acceptStateName:(NSString *)stateName
//{
//	if (stateName == nil) {
//			// User cancelled
//		[self interactionCompleted];
//		return;
//	}
//	[deadKeyData setObject:stateName forKey:kDeadKeyDataStateName];
//	[self checkDeadKeyParameters];
//}
//
- (void)interactionCompleted
{
    [completionTarget interactionDidComplete:self];
}

- (void)handleMessage:(NSDictionary *)messageData
{
	NSString *messageName = messageData[kMessageNameKey];
	NSUInteger deadKeyModifiers = [parentDocumentWindow currentModifiers];
	NSInteger keyCode = kNoKeyCode;
	if ([messageName isEqualToString:kMessageClick]) {
			// Handle a click
		keyCode = [messageData[kMessageArgumentKey] integerValue];
		deadKeyData[kDeadKeyDataKeyCode] = @(keyCode);
		deadKeyData[kDeadKeyDataModifiers] = @(deadKeyModifiers);
		[parentDocumentWindow setMessageBarText:@""];
		[self checkDeadKeyParameters];
	}
	else if ([messageName isEqualToString:kMessageKeyDown]) {
			// Handle a key down
		keyCode = [messageData[kMessageArgumentKey] integerValue];
		deadKeyData[kDeadKeyDataKeyCode] = @(keyCode);
		deadKeyData[kDeadKeyDataModifiers] = @(deadKeyModifiers);
		[parentDocumentWindow setMessageBarText:@""];
		[self checkDeadKeyParameters];
	}
}

@end
