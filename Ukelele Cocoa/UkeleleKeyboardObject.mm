//
//  UkeleleKeyboardObject.mm
//  Ukelele 3
//
//  Created by John Brownie on 11/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "UkeleleKeyboardObject.h"
#import "UkeleleKeyboard.h"
#import "NXMLEncoder.h"
#import "XMLErrors.h"
#import "KeyboardEnvironment.h"
#import "UkeleleConstantStrings.h"
#import "UkeleleErrorCodes.h"
#import "ModifiersSheet.h"
#import "ModifierMap.h"
#import "XMLCocoaUtilities.h"
#include "KeyStrokeLookupTable.h"
#include "XMLUtilities.h"
#include "UKXMLEncoder.h"

NSString *kUnlinkParameterModifiers = @"Modifiers";
NSString *kUnlinkParameterData = @"Data";
NSString *kUnlinkParameterKeyCode = @"KeyCode";
NSString *kUnlinkParameterKeyboardID = @"KeyboardID";
NSString *kUnlinkParameterOldActionName = @"OldActionName";
NSString *kUnlinkParameterNewActionName = @"NewActionName";

	// Helper class to wrap a key element bundle

@interface KeyElementBundleObject : NSObject {
	boost::shared_ptr<KeyElementBundle> keyElementBundle;
}

@property (nonatomic) boost::shared_ptr<KeyElementBundle> keyElementBundle;

@end

@implementation KeyElementBundleObject

@synthesize keyElementBundle = keyElementBundle;

- (instancetype)init {
	return [super init];
}

@end

	// Helper class to wrap an XML comment holder

@interface XMLCommentHolderObject : NSObject

@property (nonatomic) XMLCommentHolder *commentHolder;

@end

@implementation XMLCommentHolderObject

- (instancetype)init {
	return [super init];
}

@end

@implementation UkeleleKeyboardObject {
	NSDocument *parentDocument;
	std::vector<boost::shared_ptr<KeyElementBundle> > pasteKeyBundleStack;
}

@synthesize parentController = parentController;

- (instancetype)initWithName:(NSString *)keyboardName
{
	self = [super init];
	if (self) {
		_keyboard = new UkeleleKeyboard;
		_keyboard->CreateBasicKeyboard(ToNN(keyboardName));
	}
	return self;
}

- (instancetype)initWithName:(NSString *)keyboardName base:(NSUInteger)baseLayout command:(NSUInteger)commandLayout capsLock:(NSUInteger)capsLockLayout {
	self = [super init];
	if (self) {
		_keyboard = new UkeleleKeyboard;
		_keyboard->CreateStandardKeyboard(ToNN(keyboardName), (UInt32)baseLayout, (UInt32)commandLayout, (UInt32)capsLockLayout);
	}
	return self;
}

- (instancetype)initWithData:(NSData *)xmlData withError:(NSError **)outError
{
	self = [super init];
	if (self) {
		NXMLEncoder xmlEncoder;
		NString xmlString(ToNN(xmlData));
        NStatus xmlError;
        NSDictionary *errorDictionary;
		NXMLNode *treeRepresentation = xmlEncoder.Decode(xmlString, &xmlError);
        if (xmlError != kNoErr) {
            // Bad XML of some sort
            if (xmlError == kNErrMalformed) {
                // Malformed XML
                errorDictionary = @{NSLocalizedDescriptionKey: @"Could not open the file, as it was not valid XML"};
				if (outError != NULL) {
					*outError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorMalformedXML userInfo:errorDictionary];
				}
                self = nil;
                return self;
            }
            else {
                // Some other error
				NSString *errorMessage = [NSString stringWithFormat:@"Could not open the file, received error %d", xmlError];
				errorDictionary = @{NSLocalizedDescriptionKey: errorMessage};
				if (outError != NULL) {
					*outError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorMalformedXML userInfo:errorDictionary];
				}
                self = nil;
                return self;
            }
        }
		_keyboard = new UkeleleKeyboard;
		ErrorMessage error = _keyboard->CreateKeyboardFromXMLTree(*treeRepresentation);
		if (error != XMLNoError) {
			if (outError != nil) {
				errorDictionary = @{NSLocalizedDescriptionKey: ToNS(error.GetErrorMessage())};
				*outError = [NSError errorWithDomain:@"org.sil.ukelele"
												code:error.GetErrorCode()
											userInfo:errorDictionary];
			}
			self = nil;
		}
		else {
			// We need to check for various sanity conditions here...
			error = [self checkSanity];
			if (error != UKNoError) {
				if (outError != nil) {
					errorDictionary = @{NSLocalizedDescriptionKey: ToNS(error.GetErrorMessage())};
					*outError = [NSError errorWithDomain:@"org.sil.ukelele"
													code:error.GetErrorCode()
												userInfo:errorDictionary];
				}
				self = nil;
			}
		}
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	NSData *currentData = [self convertToData];
	UkeleleKeyboardObject *theCopy = [[UkeleleKeyboardObject allocWithZone:zone] initWithData:currentData withError:nil];
	return theCopy;
}

- (NSData *)convertToData
{
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	BOOL updateComment = [[theDefaults objectForKey:UKUpdateEditingComment] boolValue];
	if (updateComment) {
		[self updateEditingComment];
	}
	BOOL encodeNonAscii = [[theDefaults objectForKey:UKCodeNonAscii] boolValue];
	NXMLNode *treeRepresentation = self.keyboard->CreateXMLTree(encodeNonAscii);
	[parentDocument unblockUserInteraction];
	UKXMLEncoder xmlEncoder;
	static NDictionary attributeOrder;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NArray theAttributes;
		NStringList attributeNames;
		attributeNames.push_back(kGroupAttribute);
		attributeNames.push_back(kIDAttribute);
		attributeNames.push_back(kNameAttribute);
		attributeNames.push_back(kMaxoutAttribute);
		theAttributes.SetValuesString(attributeNames);
		attributeOrder.SetValue(kKeyboardElement, theAttributes);
		attributeNames.clear();
		attributeNames.push_back(kFirstAttribute);
		attributeNames.push_back(kLastAttribute);
		attributeNames.push_back(kModifiersAttribute);
		attributeNames.push_back(kMapSetAttribute);
		theAttributes.SetValuesString(attributeNames);
		attributeOrder.SetValue(kLayoutsElement, theAttributes);
		attributeNames.clear();
		attributeNames.push_back(kIDAttribute);
		attributeNames.push_back(kDefaultIndexAttribute);
		theAttributes.SetValuesString(attributeNames);
		attributeOrder.SetValue(kModifierMapElement, theAttributes);
		attributeNames.clear();
		attributeNames.push_back(kMapIndexAttribute);
		theAttributes.SetValuesString(attributeNames);
		attributeOrder.SetValue(kKeyMapSelectElement, theAttributes);
		attributeNames.clear();
		attributeNames.push_back(kKeysAttribute);
		theAttributes.SetValuesString(attributeNames);
		attributeOrder.SetValue(kModifierElement, theAttributes);
		attributeNames.clear();
		attributeNames.push_back(kIDAttribute);
		theAttributes.SetValuesString(attributeNames);
		attributeOrder.SetValue(kKeyMapSetElement, theAttributes);
		attributeNames.clear();
		attributeNames.push_back(kIndexAttribute);
		attributeNames.push_back(kBaseMapSetAttribute);
		attributeNames.push_back(kBaseIndexAttribute);
		theAttributes.SetValuesString(attributeNames);
		attributeOrder.SetValue(kKeyMapElement, theAttributes);
		attributeNames.clear();
		attributeNames.push_back(kCodeAttribute);
		attributeNames.push_back(kOutputAttribute);
		attributeNames.push_back(kActionAttribute);
		theAttributes.SetValuesString(attributeNames);
		attributeOrder.SetValue(kKeyElement, theAttributes);
		attributeNames.clear();
		attributeNames.push_back(kIDAttribute);
		theAttributes.SetValuesString(attributeNames);
		attributeOrder.SetValue(kActionElement, theAttributes);
		attributeNames.clear();
		attributeNames.push_back(kStateAttribute);
		attributeNames.push_back(kThroughAttribute);
		attributeNames.push_back(kNextAttribute);
		attributeNames.push_back(kOutputAttribute);
		attributeNames.push_back(kMultiplierAttribute);
		theAttributes.SetValuesString(attributeNames);
		attributeOrder.SetValue(kWhenElement, theAttributes);
	});
	xmlEncoder.setAttributeOrderDictionary(attributeOrder);
	NString xmlString = xmlEncoder.Encode(treeRepresentation);
	NData xmlData = xmlString.GetData(kNStringEncodingUTF8);
	return ToNS(xmlData);
}

- (void)setParentDocument:(NSDocument *)parent
{
	parentDocument = parent;
}

- (NSArray *)modifierIndices
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	ModifierMap *modMap = keyboardElement->GetModifierMap(static_cast<UInt32>([[KeyboardEnvironment instance] currentKeyboardID]));
	int keyMapSelectCount = modMap->GetKeyMapSelectCount();
	NSMutableArray *modifierIndices = [NSMutableArray arrayWithCapacity:keyMapSelectCount];
	for (int selectIndex = 0; selectIndex < keyMapSelectCount; selectIndex++) {
		KeyMapSelect *selectElement = modMap->GetKeyMapSelectElement(selectIndex);
		if (selectElement == NULL) {
			continue;
		}
		unsigned int selectID = selectElement->GetKeyMapSelectIndex();
		[modifierIndices addObject:@(selectID)];
	}
	return modifierIndices;
}

- (NSUInteger)defaultModifierIndex
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	ModifierMap *modMap = keyboardElement->GetModifierMap(static_cast<UInt32>([[KeyboardEnvironment instance] currentKeyboardID]));
	return modMap->GetDefaultIndex();
}

- (unsigned int)getUkeleleModifiers:(unsigned int)systemModifiers
{
	unsigned int modifiers = 0;
	if (systemModifiers & NSShiftKeyMask) {
		modifiers |= shiftKey;
	}
	if (systemModifiers & NSControlKeyMask) {
		modifiers |= controlKey;
	}
	if (systemModifiers & NSAlternateKeyMask) {
		modifiers |= optionKey;
	}
	if (systemModifiers & NSCommandKeyMask) {
		modifiers |= cmdKey;
	}
	if (systemModifiers & NSAlphaShiftKeyMask) {
		modifiers |= alphaLock;
	}
	if (systemModifiers & NSNumericPadKeyMask) {
		modifiers |= kEventKeyModifierFnMask;
	}
	return modifiers;
}

- (unsigned int)getCocoaModifiers:(unsigned int)ukeleleModifiers
{
	unsigned int modifiers = 0;
	if (ukeleleModifiers & shiftKey) {
		modifiers |= NSShiftKeyMask;
	}
	if (ukeleleModifiers & controlKey) {
		modifiers |= NSControlKeyMask;
	}
	if (ukeleleModifiers & optionKey) {
		modifiers |= NSAlternateKeyMask;
	}
	if (ukeleleModifiers & cmdKey) {
		modifiers |= NSCommandKeyMask;
	}
	if (ukeleleModifiers & alphaLock) {
		modifiers |= NSAlphaShiftKeyMask;
	}
	if (ukeleleModifiers & kEventKeyModifierFnMask) {
		modifiers |= NSNumericPadKeyMask;
	}
	return modifiers;
}

- (NSString *)getCharOutput:(NSDictionary *)keyDataDict isDead:(BOOL *)deadKey nextState:(NSString **)stateName
{
	NString currentState = ToNN((NSString *)keyDataDict[kKeyState]);
	NString nextState;
	bool isDeadKey;
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	NString outputString = keyboardElement->GetCharOutput([keyDataDict[kKeyKeyboardID] intValue],
														  [keyDataDict[kKeyKeyCode] intValue],
														  [self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
														  currentState,
														  isDeadKey,
														  nextState);
	if (isDeadKey && stateName != nil) {
		*stateName = ToNS(nextState);
	}
	if (deadKey != nil) {
		*deadKey = isDeadKey;
	}
	return ToNS(outputString);
}

- (BOOL)isDeadKey:(NSDictionary *)keyDataDict
{
	NString currentState = ToNN((NSString *)keyDataDict[kKeyState]);
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	return keyboardElement->IsDeadKey([keyDataDict[kKeyKeyboardID] intValue],
									  [keyDataDict[kKeyKeyCode] intValue],
									  [self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
									  currentState);
}

- (NSString *)getNextState:(NSDictionary *)keyDataDict
{
	NString currentState = ToNN((NSString *)keyDataDict[kKeyState]);
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	return ToNS(keyboardElement->GetNextState([keyDataDict[kKeyKeyboardID] intValue],
											  [keyDataDict[kKeyKeyCode] intValue],
											  [self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
											  currentState));
}

- (NSString *)getOutputInfoForKey:(NSDictionary *)keyDataDict {
    NSString *output;
    BOOL deadKey;
    NSString *nextState;
    output = [self getCharOutput:keyDataDict isDead:&deadKey nextState:&nextState];
    NSString *normalisedOutput = [XMLCocoaUtilities convertEncodedString:output];
    NSString *displayText = [XMLCocoaUtilities createCanonicalForm:normalisedOutput];
    if (deadKey) {
        displayText = [NSString stringWithFormat:@"Dead key, next state: %@\nTerminator: %@", nextState, displayText];
    }
	return displayText;
}

- (void)updateEditingComment {
	self.keyboard->UpdateEditingComment();
}

- (void)addCreationComment {
	self.keyboard->AddCreationComment();
}

- (void)assignRandomID {
	NSInteger newID = self.keyboard->GetKeyboard()->GetRandomKeyboardID((SInt32)self.keyboardGroup);
	[self setKeyboardID:newID];
}

#pragma mark Sanity checking

- (ErrorMessage)checkSanity {
		// Check for missing modifier maps
	NStringList modifierMaps;
	shared_ptr<KeyboardElement> theKeyboard = self.keyboard->GetKeyboard();
	if (theKeyboard->IsMissingModifierMaps(modifierMaps)) {
		NString missingMaps = NString::Join(modifierMaps, ", ");
		NString errorMessage;
		errorMessage.Format("The keyboard layout refers to modifier map(s) \"%@\", but does not include them", missingMaps);
		return ErrorMessage(UKMissingModifierMapError, errorMessage);
	}
		// Check for missing key map sets
	NStringList keyMapSets;
	if (theKeyboard->IsMissingKeyMapSets(keyMapSets)) {
		NString missingKeyMapSets = NString::Join(keyMapSets);
		NString errorMessage;
		errorMessage.Format("The keyboard refers to the key map set(s) \"%@\", but does not include them", missingKeyMapSets);
		return ErrorMessage(UKMissingKeyMapError, errorMessage);
	}
		// Check for missing actions
	NArray missingActions;
	if (theKeyboard->HasMissingActions(&missingActions)) {
		NString actionNames = NString::Join(missingActions.GetValuesString());
		NString errorMessage;
		errorMessage.Format("The keyboard refers to the action(s) \"%@\", but does not include them", actionNames);
		return ErrorMessage(UKMissingActionError, errorMessage);
	}
		// Passed all tests, so OK
	return ErrorMessage(UKNoError, "");
}

#pragma mark Accessors

- (NSInteger)keyboardGroup
{
	if (self.keyboard == nil) {
		return 0;
	}
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	return keyboardElement->GetKeyboardGroup();
}

- (void)setKeyboardGroup:(NSInteger)newGroup
{
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	if (keyboardElement->GetKeyboardGroup() != newGroup) {
		keyboardElement->SetKeyboardGroup((SInt32)newGroup);
		[self assignRandomID];
	}
}

- (NSInteger)keyboardID
{
	if (self.keyboard == nil) {
		return 0;
	}
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	return keyboardElement->GetKeyboardID();
}

- (void)setKeyboardID:(NSInteger)newID
{
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->SetKeyboardID((SInt32)newID);
}

- (NSString *)keyboardName
{
	if (self.keyboard == nil) {
		return @"";
	}
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	return ToNS(keyboardElement->GetKeyboardName());
}

- (void)setKeyboardName:(NSString *)newName
{
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->SetKeyboardName(ToNN(newName));
}

- (NSArray *)stateNamesExcept:(NSString *)stateToOmit
{
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	NArray stateNames = keyboardElement->GetStateNames(ToNN(stateToOmit), kAllStates);
	return ToNS(stateNames);
}

- (NSArray *)stateNamesNotInSet:(NSSet *)statesToOmit
{
	NArray omitStateArray;
	for (NSString *stateName in statesToOmit) {
		omitStateArray.AppendValue(ToNN(stateName));
	}
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	NArray result = keyboardElement->GetStateNames(omitStateArray, kAllStates);
	return ToNS(result);
}

- (NSUInteger)stateCount
{
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	NArray stateNames = keyboardElement->GetStateNames(kStateNone, kAllStates);
	return stateNames.GetSize();
}

- (BOOL)hasStateWithName:(NSString *)stateName
{
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	return keyboardElement->StateExists(ToNN(stateName));
}

- (NSString *)uniqueStateName
{
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	NString baseName = ToNN([[NSUserDefaults standardUserDefaults] stringForKey:UKStateNameBase]);
	return ToNS(keyboardElement->CreateStateName(baseName));
}

- (NSArray *)actionNames
{
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	return ToNS(keyboardElement->GetActionNames());
}

- (BOOL)hasActionWithName:(NSString *)actionName
{
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	return keyboardElement->ActionExists(ToNN(actionName));
}

- (NSString *)terminatorForState:(NSString *)stateName {
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	return ToNS(keyboardElement->GetTerminator(ToNN(stateName)));
}

- (NSDictionary *)getKeyStrokeForOutput:(NSString *)outputString forKeyboard:(NSUInteger)keyboardID {
	NSAssert(self.keyboard != nil, @"Must have a keyboard");
	boost::shared_ptr<KeyStrokeLookUpTable> lookupTable = (self.keyboard)->CreateKeyStrokeLookUpTable((UInt32)keyboardID);
	std::pair<KeyStrokeList, NString> result = lookupTable->GetKeyStrokes(ToNN(outputString));
	KeyStrokeList theList = result.first;
	KeyStrokeIterator theIterator;
	NString resultString = "";
	NString state = result.second;
	NSUInteger modifiers = 0;
	NSInteger keyCode = kNoKeyCode;
	for (theIterator = theList.begin(); theIterator != theList.end(); ++theIterator) {
		NString modifierString = theIterator->GetModifierString();
		keyCode = theIterator->GetKeyCode();
		if (resultString != "") {
			resultString += " ";
		}
		resultString += modifierString;
		if (keyCode == kNoKeyCode) {
				// No key code
			resultString += "(Terminator for state ";
			resultString += result.second;
			resultString += ")";
		}
		else {
			bool isDeadKey;
			NString oldState;
			NString baseString = (self.keyboard)->GetKeyboard()->GetCharOutput((UInt32)keyboardID, (SInt16)keyCode, 0, kStateNone, isDeadKey, oldState);
			resultString += XMLUtilities::ConvertEncodedString(baseString);
		}
		modifiers = theIterator->GetModifiers();
	}
	NSString *keyStrokeString = ToNS(resultString);
	modifiers = [self getCocoaModifiers:(unsigned int)modifiers];
	NSDictionary *resultDict = @{UKKeyStrokeLookupKeyStrokes: keyStrokeString,
								 UKKeyStrokeLookupState: ToNS(state),
								 UKKeyStrokeLookupModifiers: @(modifiers),
								 UKKeyStrokeLookupKeyCode: @(keyCode)};
	return resultDict;
}

#pragma mark Importing a dead key state

- (BOOL)hasEquivalentModifierMap:(UkeleleKeyboardObject *)otherKeyboard {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	boost::shared_ptr<KeyboardElement> sourceKeyboardElement = [otherKeyboard keyboard]->GetKeyboard();
	return keyboardElement->HasEquivalentModifierMap(sourceKeyboardElement.get());
}

- (void)importDeadKeyState:(NSString *)sourceState toState:(NSString *)localState fromKeyboard:(UkeleleKeyboardObject *)sourceKeyboard {
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] undoImportDeadKeyState:localState];
	[undoManager setActionName:@"Import dead key state"];
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	boost::shared_ptr<KeyboardElement> sourceKeyboardElement = [sourceKeyboard keyboard]->GetKeyboard();
	keyboardElement->ImportDeadKey(ToNN(localState), ToNN(sourceState), sourceKeyboardElement.get());
	[self.delegate documentDidChange];
}

- (void)undoImportDeadKeyState:(NSString *)importedState {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	RemoveStateData *removeData = keyboardElement->RemoveState(ToNN(importedState));
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] redoImportDeadKeyState:importedState data:removeData];
	[undoManager setActionName:@"Import dead key state"];
}

- (void)redoImportDeadKeyState:(NSString *)importedState data:(RemoveStateData *)removeStateData {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->ReplaceRemovedStates(removeStateData);
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] undoImportDeadKeyState:importedState];
	[undoManager setActionName:@"Import dead key state"];
}

#pragma mark Changing output

- (void)changeOutputForKey:(NSDictionary *)keyDataDict to:(NSString *)newOutput usingBaseMap:(BOOL)usingBaseMap
{
	NString currentState = ToNN((NSString *)keyDataDict[kKeyState]);
	NString nextState;
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	KeyElement *keyElement = keyboardElement->GetKeyElement([keyDataDict[kKeyKeyboardID] intValue],
                                                            [keyDataDict[kKeyKeyCode] intValue],
															[self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
															usingBaseMap);
	NString oldOutput = keyElement->ChangeOutput(currentState, ToNN(newOutput), keyboardElement->GetActionList());
	[[[parentController undoManager] prepareWithInvocationTarget:parentController] changeOutputForKey:keyDataDict
																							   to:ToNS(oldOutput)
																					 usingBaseMap:usingBaseMap];
	[[parentController undoManager] setActionName:@"Change output"];
    [self.delegate documentDidChange];
}

- (NSString *)getTerminatorForState:(NSString *)stateName
{
	NString theState = ToNN(stateName);
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	NString theTerminator = keyboardElement->GetTerminator(theState);
	return ToNS(theTerminator);
}

- (void)changeTerminatorForState:(NSString *)stateName to:(NSString *)newTerminator
{
	NString targetState = ToNN(stateName);
	NString newString = ToNN(newTerminator);
	NSString *oldTerminator = [self getTerminatorForState:stateName];
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->ReplaceTerminator(targetState, newString);
	[[[parentController undoManager] prepareWithInvocationTarget:parentController] changeTerminatorForState:stateName
																									 to:oldTerminator];
	[[parentController undoManager] setActionName:@"Change terminator"];
    [self.delegate documentDidChange];
}

- (void)makeKeyDeadKey:(NSDictionary *)keyDataDict state:(NSString *)nextState
{
	NString currentState = ToNN((NSString *)keyDataDict[kKeyState]);
	NString targetState = ToNN(nextState);
	NSString *currentOutput = [self getCharOutput:keyDataDict isDead:nil nextState:nil];
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->MakeKeyDeadKey([keyDataDict[kKeyKeyboardID] intValue], [keyDataDict[kKeyKeyCode] intValue],
                                    [self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]], currentState, targetState);
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:parentController] makeDeadKeyOutput:keyDataDict output:currentOutput];
	[undoManager setActionName:[undoManager isUndoing] ? @"Changed dead key to output" : @"Change to dead key"];
    [self.delegate documentDidChange];
}

- (void)makeDeadKeyOutput:(NSDictionary *)keyDataDict output:(NSString *)newOutput
{
	NString currentState = ToNN((NSString *)keyDataDict[kKeyState]);
	NString outputString = ToNN(newOutput);
	NSString *nextState = nil;
	[self getCharOutput:keyDataDict isDead:nil nextState:&nextState];
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->MakeDeadKeyOutput([keyDataDict[kKeyKeyboardID] intValue], [keyDataDict[kKeyKeyCode] intValue],
                                       [self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
									   currentState, outputString);
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:parentController] makeKeyDeadKey:keyDataDict state:nextState];
	[undoManager setActionName:[undoManager isUndoing] ? @"Change to dead key" : @"Change dead key to output"];
    [self.delegate documentDidChange];
}

- (void)changeDeadKeyNextState:(NSDictionary *)keyDataDict toState:(NSString *)newState
{
	NString currentState = ToNN((NSString *)keyDataDict[kKeyState]);
	NSString *nextState = [self getNextState:keyDataDict];
	NString newNextState = ToNN(newState);
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->ChangeDeadKeyNextState([keyDataDict[kKeyKeyboardID] intValue], [keyDataDict[kKeyKeyCode] intValue],
											[self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
											currentState, newNextState);
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] changeDeadKeyNextState:keyDataDict toState:nextState];
	[undoManager setActionName:@"Change next state"];
    [self.delegate documentDidChange];
}

- (void)createState:(NSString *)stateName withTerminator:(NSString *)terminator
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->CreateState(ToNN(stateName), ToNN(terminator));
}

#pragma mark Unlinking keys

- (BOOL)isActionElement:(NSDictionary *)keyDataDict
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	KeyElement *keyElement = keyboardElement->GetKeyElement([keyDataDict[kKeyKeyboardID] intValue],
															[keyDataDict[kKeyKeyCode] intValue],
															[self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
															true);
	if (keyElement == NULL) {
		return NO;
	}
	return keyElement->GetElementType() == kKeyFormAction;
}

- (NSString *)actionNameForKey:(NSDictionary *)keyDataDict
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	KeyElement *keyElement = keyboardElement->GetKeyElement([keyDataDict[kKeyKeyboardID] intValue],
															[keyDataDict[kKeyKeyCode] intValue],
															[self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
															true);
	if (keyElement == NULL) {
		return @"";
	}
	return ToNS(keyElement->GetActionName());
}

- (void)relinkKey:(NSDictionary *)keyDataDict actionName:(NSString *)originalAction
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	KeyElement *keyElement = keyboardElement->GetKeyElement([keyDataDict[kKeyKeyboardID] intValue],
															[keyDataDict[kKeyKeyCode] intValue],
															[self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
															true);
	keyElement->ChangeActionName(keyElement->GetActionName(), ToNN(originalAction));
    [self.delegate documentDidChange];
}

- (void)unlinkKey:(NSDictionary *)keyDataDict
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	KeyElement *keyElement = keyboardElement->GetKeyElement([keyDataDict[kKeyKeyboardID] intValue],
															[keyDataDict[kKeyKeyCode] intValue],
															[self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
															true);
	NString actionName = keyElement->GetActionName();
	NString newActionName = keyboardElement->CreateDuplicateAction(actionName);
	keyElement->ChangeActionName(actionName, newActionName);
    [self.delegate documentDidChange];
}

- (void)swapModifierSet:(NSDictionary *)parameters inReverse:(BOOL)reverse
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] swapModifierSet:parameters inReverse:!reverse];
	[undoManager setActionName:@"Unlink Modifiers"];
	NSUInteger modifierCombination = [parameters[kUnlinkParameterModifiers] unsignedIntegerValue];
	NSInteger keyboardID = [parameters[kUnlinkParameterKeyboardID] integerValue];
	KeyMapElement *keyMap = keyboardElement->GetKeyMapElement((unsigned int)keyboardID, [self getUkeleleModifiers:(unsigned int)modifierCombination]);
	NSDictionary *dataDict = parameters[kUnlinkParameterData];
	for (NSNumber *theKey in dataDict) {
		NSUInteger keyCode = [theKey unsignedIntegerValue];
		NSDictionary *keyData = dataDict[theKey];
		NSString *oldActionName = keyData[kUnlinkParameterOldActionName];
		NSString *newActionName = keyData[kUnlinkParameterNewActionName];
		KeyElement *keyElement = keyMap->GetKeyElement((UInt32)keyCode);
		NSAssert(keyElement->GetElementType() == kKeyFormAction, @"Key element must be action");
		NString oldString = reverse ? ToNN(newActionName) : ToNN(oldActionName);
		NString newString = reverse ? ToNN(oldActionName) : ToNN(newActionName);
		keyElement->ChangeActionName(oldString, newString);
	}
    [self.delegate modifierMapDidChange];
    [self.delegate documentDidChange];
}

- (void)unlinkModifierSet:(NSUInteger)modifierCombination forKeyboard:(NSInteger)keyboardID
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	KeyMapElement *keyMap = keyboardElement->GetKeyMapElement((unsigned int)keyboardID, [self getUkeleleModifiers:(unsigned int)modifierCombination]);
	NSAssert(keyMap != NULL, @"Key map should not be null");
	NSMutableDictionary *parameterDictionary = [NSMutableDictionary dictionary];
	NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
	parameterDictionary[kUnlinkParameterModifiers] = @(modifierCombination);
	parameterDictionary[kUnlinkParameterKeyboardID] = @(keyboardID);
	SInt32 numKeyElements = keyMap->GetKeyElementCount();
	for (SInt32 keyCode = 0; keyCode < numKeyElements; keyCode++) {
		KeyElement *keyElement = keyMap->GetKeyElement(keyCode);
		if (keyElement != NULL && keyElement->GetElementType() == kKeyFormAction) {
			NString oldActionName = keyElement->GetActionName();
			NString newActionName = keyboardElement->CreateDuplicateAction(oldActionName);
			NSDictionary *actionDict = @{kUnlinkParameterOldActionName: ToNS(oldActionName),
										kUnlinkParameterNewActionName: ToNS(newActionName)};
			dataDictionary[@(keyCode)] = actionDict;
			keyElement->ChangeActionName(oldActionName, newActionName);
		}
	}
	parameterDictionary[kUnlinkParameterData] = dataDictionary;
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] swapModifierSet:parameterDictionary inReverse:YES];
	[undoManager setActionName:@"Unlink Modifiers"];
    [self.delegate modifierMapDidChange];
    [self.delegate documentDidChange];
}

- (NSUInteger)modifiersForIndex:(NSUInteger)theIndex forKeyboard:(NSInteger)keyboardID
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	ModifierMap *modifierMap = keyboardElement->GetModifierMap((UInt32)keyboardID);
	return [self getCocoaModifiers:modifierMap->GetMatchingModifiers((UInt32)theIndex)];
}

#pragma mark Swap keys

- (void)swapKeyCode:(NSInteger)keyCode1 withKeyCode:(NSInteger)keyCode2 {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->SwapKeys((UInt32)keyCode1, (UInt32)keyCode2);
    [self.delegate documentDidChange];
}

#pragma mark Cut, copy & paste keys

- (void)cutKeyCode:(NSInteger)keyCode {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	boost::shared_ptr<KeyElementBundle> keyBundle(new KeyElementBundle);
	keyboardElement->CutKeyBundle((UInt32)keyCode, keyBundle);
	pasteKeyBundleStack.push_back(keyBundle);
    [self.delegate documentDidChange];
}

- (void)undoCutKeyCode:(NSInteger)keyCode {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	boost::shared_ptr<KeyElementBundle> keyBundle = pasteKeyBundleStack.back();
	keyboardElement->SetKeyBundle((UInt32)keyCode, keyBundle);
	pasteKeyBundleStack.pop_back();
    [self.delegate documentDidChange];
}

- (void)copyKeyCode:(NSInteger)keyCode {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	boost::shared_ptr<KeyElementBundle> keyBundle = keyboardElement->BuildKeyBundle((UInt32)keyCode);
	pasteKeyBundleStack.push_back(keyBundle);
}

- (BOOL)hasKeyOnPasteboard {
	return !pasteKeyBundleStack.empty();
}

- (void)pasteKeyCode:(NSInteger)keyCode {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	boost::shared_ptr<KeyElementBundle> keyBundle = keyboardElement->BuildKeyBundle((UInt32)keyCode);
	keyboardElement->SetKeyBundle((UInt32)keyCode, pasteKeyBundleStack.back());
	KeyElementBundleObject *keyElementBundle = [[KeyElementBundleObject alloc] init];
	[keyElementBundle setKeyElementBundle:keyBundle];
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] undoPasteKeyCode:keyCode bundle:keyElementBundle];
	[undoManager setActionName:@"Paste Key"];
    [self.delegate documentDidChange];
}

- (void)undoPasteKeyCode:(NSInteger)keyCode bundle:(KeyElementBundleObject *)keyBundle {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->SetKeyBundle((UInt32)keyCode, [keyBundle keyElementBundle]);
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] pasteKeyCode:keyCode];
	[undoManager setActionName:@"Paste Key"];
    [self.delegate documentDidChange];
}

#pragma mark Changing modifiers

- (void)setDefaultModifierIndex:(NSUInteger)defaultIndex
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	ModifierMap *modMap = keyboardElement->GetModifierMap((UInt32)[[KeyboardEnvironment instance] currentKeyboardID]);
	NSUInteger oldIndex = modMap->GetDefaultIndex();
	modMap->SetDefaultIndex((UInt32)defaultIndex);
	[[[parentController undoManager] prepareWithInvocationTarget:self] setDefaultModifierIndex:oldIndex];
	[[parentController undoManager] setActionName:@"Set default index"];
    [self.delegate modifierMapDidChange];
    [self.delegate documentDidChange];
}

- (BOOL)keyMapSelectHasOneModifierCombination:(NSInteger)modifierIndex
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	ModifierMap *modMap = keyboardElement->GetModifierMap((SInt32)[[KeyboardEnvironment instance] currentKeyboardID]);
	KeyMapSelect *keyMapSelect = modMap->GetKeyMapSelectElement((SInt32)modifierIndex);
	return keyMapSelect->GetModifierElementCount() == 1;
}

- (void)changeModifiersIndex:(NSInteger)index
					subIndex:(NSInteger)subindex
					   shift:(NSInteger)newShift
					  option:(NSInteger)newOption
					capsLock:(NSInteger)newCapsLock
					 command:(NSInteger)newCommand
					 control:(NSInteger)newControl
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	ModifierMap *modMap = keyboardElement->GetModifierMap((SInt32)[[KeyboardEnvironment instance] currentKeyboardID]);
	KeyMapSelect *selectElement = modMap->GetKeyMapSelectElement((SInt32)index);
	ModifierElement *modElement = selectElement->GetModifierElement((SInt32)subindex);
	UInt32 oldShift, oldOption, oldCapsLock, oldCommand, oldControl;
	modElement->GetModifierStatus(oldShift, oldCapsLock, oldOption, oldCommand, oldControl);
	modElement->SetModifierStatus((UInt32)newShift, (UInt32)newCapsLock, (UInt32)newOption, (UInt32)newCommand, (UInt32)newControl);
	modMap->UpdateModifiers();
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] changeModifiersIndex:index
                                                                subIndex:subindex
                                                                   shift:oldShift
                                                                  option:oldOption
                                                                capsLock:oldCapsLock
                                                                 command:oldCommand
                                                                 control:oldControl];
	[undoManager setActionName:@"Change modifiers"];
    [self.delegate modifierMapDidChange];
    [self.delegate documentDidChange];
}

- (void)addModifierElement:(NSInteger)keyboardID
					 index:(NSInteger)index
				  subIndex:(NSInteger)subindex
					 shift:(NSInteger)shiftValue
				  capsLock:(NSInteger)capsLockValue
					option:(NSInteger)optionValue
				   command:(NSInteger)commandValue
				   control:(NSInteger)controlValue
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	ModifierMap *modMap = keyboardElement->GetModifierMap((UInt32)keyboardID);
	KeyMapSelect *selectElement = modMap->GetKeyMapSelectElement((SInt32)index);
	ModifierElement *modifierElement = new ModifierElement;
	modifierElement->SetModifierStatus((UInt32)shiftValue, (UInt32)capsLockValue, (UInt32)optionValue, (UInt32)commandValue, (UInt32)controlValue);
	XMLCommentHolderList newModifierElementList;
	modifierElement->AppendToList(newModifierElementList);
	if (subindex < selectElement->GetModifierElementCount()) {
		selectElement->InsertModifierElementAtIndex(modifierElement, (SInt32)subindex);
	}
	else {
		selectElement->AddModifierElement(modifierElement);
	}
	modMap->UpdateModifiers();
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeModifierElement:keyboardID
                                                                    index:index
                                                                 subindex:subindex];
	[undoManager setActionName:[undoManager isUndoing] ? @"Remove modifier combination" : @"Add modifier combination"];
    [self.delegate modifierMapDidChange];
    [self.delegate documentDidChange];
}

- (void)removeModifierElement:(NSInteger)keyboardID index:(NSInteger)index subindex:(NSInteger)subindex
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	ModifierMap *modMap = keyboardElement->GetModifierMap((UInt32)[[KeyboardEnvironment instance] currentKeyboardID]);
	KeyMapSelect *selectElement = modMap->GetKeyMapSelectElement((SInt32)index);
	ModifierElement *modifierElement = selectElement->RemoveModifierElement((SInt32)subindex);
	XMLCommentHolderList oldModifierElementList;
	modifierElement->AppendToList(oldModifierElementList);
	UInt32 oldShift, oldCapsLock, oldOption, oldCommand, oldControl;
	modifierElement->GetModifierStatus(oldShift, oldCapsLock, oldOption, oldCommand, oldControl);
	modMap->UpdateModifiers();
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] addModifierElement:keyboardID
                                                                 index:index
                                                              subIndex:subindex
                                                                 shift:oldShift
                                                              capsLock:oldCapsLock
                                                                option:oldOption
                                                               command:oldCommand
                                                               control:oldControl];
	[undoManager setActionName:[undoManager isUndoing] ? @"Add modifier combination" : @"Remove modifier combination"];
	shared_ptr<XMLCommentContainer> theCommentContainer = self.keyboard->GetCommentContainer();
	theCommentContainer->RemoveCommentHolders(oldModifierElementList);
    [self.delegate modifierMapDidChange];
    [self.delegate documentDidChange];
}

- (void)removeKeyMap:(NSInteger)index forKeyboard:(NSInteger)keyboardID newDefaultIndex:(NSInteger)newDefaultIndex
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	ModifierMap *modMap = keyboardElement->GetModifierMap((UInt32)[[KeyboardEnvironment instance] currentKeyboardID]);
	KeyMapSetList *keyMapSets = keyboardElement->GetKeyMapSetsForKeyboard((UInt32)keyboardID);
	SInt32 keyMapSetCount = keyMapSets->GetCount();
	KeyMapElementVector *deletedKeyMapElements = new KeyMapElementVector;
	for (SInt32 i = 1; i <= keyMapSetCount; i++) {
		KeyMapSet *keyMapSet = keyMapSets->GetKeyMapSet(i);
		KeyMapElement *keyMapElement = keyMapSet->RemoveKeyMapElement((UInt32)index);
		deletedKeyMapElements->push_back(keyMapElement);
	}
	KeyMapSelect *keyMapSelect = modMap->RemoveKeyMapSelectElement((SInt32)index);
	NSAssert(keyMapSelect->GetModifierElementCount() == 1, @"KeyMapSelect should have only one element");
	XMLCommentHolderList oldKeyMapSelectList;
	keyMapSelect->AppendToList(oldKeyMapSelectList);
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceKeyMap:index
                                                      forKeyboard:keyboardID
                                                     defaultIndex:modMap->GetDefaultIndex()
                                                     keyMapSelect:keyMapSelect
                                                   keyMapElements:deletedKeyMapElements];
	[undoManager setActionName:@"Remove key map"];
	modMap->SetDefaultIndex((UInt32)newDefaultIndex);
	shared_ptr<XMLCommentContainer> theCommentContainer = self.keyboard->GetCommentContainer();
	theCommentContainer->RemoveCommentHolders(oldKeyMapSelectList);
    [self.delegate modifierMapDidChange];
    [self.delegate documentDidChange];
}

- (void)replaceKeyMap:(NSInteger)index
		  forKeyboard:(NSInteger)keyboardID
		 defaultIndex:(NSInteger)defaultIndex
		 keyMapSelect:(void *)keyMapSelect
	   keyMapElements:(void *)deletedKeyMapElements
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	KeyMapSetList *keyMapSets = keyboardElement->GetKeyMapSetsForKeyboard((UInt32)keyboardID);
	SInt32 keyMapSetCount = keyMapSets->GetCount();
	for (SInt32 i = 1; i <= keyMapSetCount; i++) {
		KeyMapSet *keyMapSet = keyMapSets->GetKeyMapSet(i);
		KeyMapElement *keyMapElement = (*(KeyMapElementVector *)deletedKeyMapElements)[i - 1];
		keyMapSet->AddKeyMap(keyMapElement);
	}
	ModifierMap *modifierMap = keyboardElement->GetModifierMap((UInt32)keyboardID);
	modifierMap->InsertKeyMapSelectAtIndex((KeyMapSelect *)keyMapSelect, (UInt32)index);
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeKeyMap:index
                                                     forKeyboard:keyboardID
                                                 newDefaultIndex:defaultIndex];
	[undoManager setActionName:@"Replace key map"];
	modifierMap->SetDefaultIndex((UInt32)defaultIndex);
    [self.delegate modifierMapDidChange];
    [self.delegate documentDidChange];
}

- (void)addKeyMap:(KeyMapElement *)keyMap atIndex:(NSInteger)newIndex forKeyboard:(NSInteger)keyboardID withModifiers:(ModifiersInfo *)modifierInfo
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
    ModifierMap *modifierMap = keyboardElement->GetModifierMap((UInt32)keyboardID);
    NSInteger oldDefaultIndex = modifierMap->GetDefaultIndex();
    KeyMapSelect *keyMapSelect = new KeyMapSelect((UInt32)newIndex);
	ModifierElement *modifierElement = new ModifierElement;
	modifierElement->SetModifierStatus((UInt32)[modifierInfo shiftValue], (UInt32)[modifierInfo capsLockValue],
                                       (UInt32)[modifierInfo optionValue], (UInt32)[modifierInfo commandValue], (UInt32)[modifierInfo controlValue]);
	keyMapSelect->AddModifierElement(modifierElement);
	if (static_cast<SInt32>(newIndex) < modifierMap->GetKeyMapSelectCount()) {
		modifierMap->InsertKeyMapSelectAtIndex(keyMapSelect, (SInt32)newIndex);
	}
	else {
		modifierMap->AddKeyMapSelectElement(keyMapSelect);
	}
	XMLCommentHolderList newKeyMapSelectList;
	keyMapSelect->AppendToList(newKeyMapSelectList);
	KeyMapSetList *keyMapSets = keyboardElement->GetKeyMapSetsForKeyboard((UInt32)keyboardID);
	SInt32 keyMapSetCount = keyMapSets->GetCount();
	for (SInt32 i = 1; i <= keyMapSetCount; i++) {
		KeyMapSet *keyMapSet = keyMapSets->GetKeyMapSet(i);
		KeyMapElement *keyMapElement;
		if (keyMapSet->IsRelative()) {
			KeyMapElement *existingKeyMap = keyMapSet->GetKeyMapElement(0);
			keyMapElement = new KeyMapElement((UInt32)newIndex, existingKeyMap->GetBaseMapSet(), (UInt32)newIndex, 0);
		}
		else {
			keyMapElement = keyMap;
		}
		keyMapSet->InsertKeyMapAtIndex((UInt32)newIndex, keyMapElement);
	}
	modifierMap->UpdateModifiers();
	shared_ptr<XMLCommentContainer> theCommentContainer = self.keyboard->GetCommentContainer();
	theCommentContainer->AddCommentHolders(newKeyMapSelectList);
	NSUndoManager *undoManager = [parentController undoManager];
    [[undoManager prepareWithInvocationTarget:parentController] removeKeyMap:newIndex
                                                               forKeyboard:keyboardID
                                                           newDefaultIndex:oldDefaultIndex];
    [undoManager setActionName:@"Add key map"];
    [self.delegate modifierMapDidChange];
    [self.delegate documentDidChange];
}

- (void)addEmptyKeyMapForKeyboard:(NSInteger)keyboardID withModifiers:(ModifiersInfo *)modifierInfo
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
    ModifierMap *modifierMap = keyboardElement->GetModifierMap((UInt32)keyboardID);
    SInt32 newIndex = (SInt32)[modifierInfo keyMapIndex];
    if (newIndex == -1) {
        newIndex = modifierMap->GetKeyMapSelectCount();
    }
    KeyMapElement *keyMap = KeyMapElement::CreateDefaultKeyMapElement(newIndex, "", 0);
    [self addKeyMap:keyMap atIndex:newIndex forKeyboard:keyboardID withModifiers:modifierInfo];
}

- (void)addStandardKeyMap:(NSInteger)standardType forKeyboard:(NSInteger)keyboardID withModifiers:(ModifiersInfo *)modifierInfo
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
    ModifierMap *modifierMap = keyboardElement->GetModifierMap((UInt32)keyboardID);
    SInt32 newIndex = (SInt32)[modifierInfo keyMapIndex];
    if (newIndex == -1) {
        newIndex = modifierMap->GetKeyMapSelectCount();
    }
    KeyMapElement *keyMap = KeyMapElement::CreateDefaultKeyMapElement((UInt32)standardType, newIndex, "", 0);
    [self addKeyMap:keyMap atIndex:newIndex forKeyboard:keyboardID withModifiers:modifierInfo];
}

- (void)addCopyKeyMap:(NSInteger)indexToCopy unlink:(BOOL)unlinkMap forKeyboard:(NSInteger)keyboardID withModifiers:(ModifiersInfo *)modifierInfo
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
    ModifierMap *modifierMap = keyboardElement->GetModifierMap((UInt32)keyboardID);
    SInt32 newIndex = (SInt32)[modifierInfo keyMapIndex];
    if (newIndex == -1) {
        newIndex = modifierMap->GetKeyMapSelectCount();
    }
	KeyMapSet *keyMapSet = keyboardElement->GetKeyMapSet((UInt32)keyboardID);
    KeyMapElement *keyMap = new KeyMapElement(*keyMapSet->GetKeyMapElement((UInt32)indexToCopy));
	keyMap->SetIndex(newIndex);
    if (unlinkMap) {
        keyMap->UnlinkKeyMapElement(keyboardElement->GetActionList());
    }
    [self addKeyMap:keyMap atIndex:newIndex forKeyboard:keyboardID withModifiers:modifierInfo];
}

- (void)replaceModifierMaps:(ModifierMapList *)newModifierMaps
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
    ModifierMapList *oldModifiers = keyboardElement->ReplaceModifierMaps(newModifierMaps);
	NSUndoManager *undoManager = [parentController undoManager];
    [[undoManager prepareWithInvocationTarget:self] replaceModifierMaps:oldModifiers];
    [undoManager setActionName:@"Replace Modifiers"];
    [self.delegate modifierMapDidChange];
    [self.delegate documentDidChange];
}

- (void)simplifyModifiers
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
    ModifierMapList *simplifiedModifierList = keyboardElement->SimplifiedModifierMaps();
    [self replaceModifierMaps:simplifiedModifierList];
}

- (BOOL)hasSimplifiedModifiers
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
    return keyboardElement->HasSimplifiedModifierMaps();
}

- (NSUInteger)modifierSetCountForKeyboard:(NSUInteger)keyboardID {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	ModifierMap *modMap = keyboardElement->GetModifierMap((UInt32)keyboardID);
	return modMap->GetKeyMapSelectCount();
}

- (NSUInteger)modifierSetIndexForModifiers:(NSUInteger)modifiers forKeyboard:(NSUInteger)keyboardID {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	ModifierMap *modMap = keyboardElement->GetModifierMap((UInt32)keyboardID);
	return modMap->GetMatchingKeyMapSelect([self getUkeleleModifiers:(unsigned int)modifiers]);
}

- (void)moveModifierSetIndex:(NSInteger)sourceSet toIndex:(NSInteger)destinationSet forKeyboard:(NSUInteger)keyboardID {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->MoveModifierMap((UInt32)sourceSet, (UInt32)destinationSet, (UInt32)keyboardID);
	NSUndoManager *undoManager = [parentController undoManager];
	[[undoManager prepareWithInvocationTarget:self] moveModifierSetIndex:destinationSet toIndex:sourceSet forKeyboard:keyboardID];
	[undoManager setActionName:@"Move modifier set"];
	[self.delegate modifierMapDidChange];
    [self.delegate documentDidChange];
}

- (BOOL)hasModifierSetWithIndex:(NSInteger)setIndex {
#pragma unused(setIndex)
	return YES;
}

#pragma mark Comments

- (void)addComment:(NSString *)commentText toHolder:(XMLCommentHolderObject *)commentHolder {
	XMLComment *newComment = new XMLComment(ToNN(commentText));
	XMLCommentHolder *theHolder = [commentHolder commentHolder];
	newComment->SetHolder(theHolder);
	theHolder->AddXMLComment(newComment);
}

- (void)removeComment:(NSString *)commentText fromHolder:(XMLCommentHolderObject *)commentHolder {
	XMLCommentHolder *theHolder = [commentHolder commentHolder];
	theHolder->RemoveComment(ToNN(commentText));
}

- (void)changeCommentText:(NSString *)oldText
					   to:(NSString *)newText
				forHolder:(XMLCommentHolderObject *)commentHolder {
	XMLCommentHolder *theHolder = [commentHolder commentHolder];
	XMLComment *theComment;
	bool gotComment = theHolder->FindComment(ToNN(oldText), theComment);
#pragma unused(gotComment)
	NSAssert(gotComment, @"Must have a valid comment to change");
	theComment->SetCommentString(ToNN(newText));
}

- (XMLCommentHolderObject *)currentCommentHolder {
	XMLCommentHolderObject *commentHolder = nil;
	XMLComment *currentComment = self.keyboard->GetCurrentComment();
	if (currentComment) {
		commentHolder = [[XMLCommentHolderObject alloc] init];
		[commentHolder setCommentHolder:currentComment->GetHolder()];
	}
	return commentHolder;
}

- (XMLCommentHolderObject *)commentHolderForKey:(NSDictionary *)keyDataDict {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	KeyElement *keyElement = keyboardElement->GetKeyElement([keyDataDict[kKeyKeyboardID] intValue],
                                                            [keyDataDict[kKeyKeyCode] intValue],
															[self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
															YES);
	XMLCommentHolderObject *commentHolder = [[XMLCommentHolderObject alloc] init];
	[commentHolder setCommentHolder:keyElement];
	return commentHolder;
}

- (XMLCommentHolderObject *)documentCommentHolder {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	XMLCommentHolderObject *commentHolder = [[XMLCommentHolderObject alloc] init];
	[commentHolder setCommentHolder:keyboardElement.get()];
	return commentHolder;
}

- (BOOL)isFirstComment {
	boost::shared_ptr<XMLCommentContainer> commentContainer = self.keyboard->GetCommentContainer();
	return commentContainer->IsFirstComment();
}

- (BOOL)isLastComment {
	boost::shared_ptr<XMLCommentContainer> commentContainer = self.keyboard->GetCommentContainer();
	return commentContainer->IsLastComment();
}

- (BOOL)isEditableComment {
	XMLComment *currentComment = self.keyboard->GetCurrentComment();
	if (currentComment) {
		NString commentString = currentComment->GetCommentString();
		return !commentString.StartsWith(kCreationComment) && !commentString.StartsWith(kEditComment);
	}
	else {
		return NO;
	}
}

- (NSString *)firstComment {
	XMLComment *theComment = self.keyboard->GetFirstComment();
	NSAssert(theComment, @"First comment cannot be nil");
	NString commentString = theComment->GetCommentString();
	return ToNS(commentString);
}

- (NSString *)previousComment {
	XMLComment *theComment = self.keyboard->GetPreviousComment();
	NSAssert(theComment, @"Previous comment cannot be nil");
	NString commentString = theComment->GetCommentString();
	return ToNS(commentString);
}

- (NSString *)nextComment {
	XMLComment *theComment = self.keyboard->GetNextComment();
	NSAssert(theComment, @"Next comment cannot be nil");
	NString commentString = theComment->GetCommentString();
	return ToNS(commentString);
}

- (NSString *)lastComment {
	XMLComment *theComment = self.keyboard->GetLastComment();
	NSAssert(theComment, @"Last comment cannot be nil");
	NString commentString = theComment->GetCommentString();
	return ToNS(commentString);
}

- (void)addComment:(NSString *)commentText keyData:(NSDictionary *)keyDataDict {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	KeyElement *keyElement = keyboardElement->GetKeyElement([keyDataDict[kKeyKeyboardID] intValue],
                                                            [keyDataDict[kKeyKeyCode] intValue],
															[self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
															YES);
	keyElement->AddXMLComment(ToNN(commentText));
}

- (void)removeComment:(NSString *)commentText keyData:(NSDictionary *)keyDataDict {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	KeyElement *keyElement = keyboardElement->GetKeyElement([keyDataDict[kKeyKeyboardID] intValue],
                                                            [keyDataDict[kKeyKeyCode] intValue],
															[self getUkeleleModifiers:[keyDataDict[kKeyModifiers] unsignedIntValue]],
															YES);
	keyElement->RemoveComment(ToNN(commentText));
}

- (NSString *)currentComment {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	XMLComment *theComment = self.keyboard->GetCurrentComment();
	if (theComment) {
		return ToNS(theComment->GetCommentString());
	}
		// No comment, so make sure the iterator is set up
	theComment = self.keyboard->GetFirstComment();
	if (theComment) {
		return ToNS(theComment->GetCommentString());
	}
	else {
		return nil;
	}
}

- (NSString *)currentHolderText {
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	XMLComment *theComment = self.keyboard->GetCurrentComment();
	if (theComment) {
		return ToNS(theComment->GetHolder()->GetDescription());
	}
		// No comment, so make sure the iterator is set up
	theComment = self.keyboard->GetFirstComment();
	if (theComment) {
		return ToNS(theComment->GetHolder()->GetDescription());
	}
	else {
		return nil;
	}
}

#pragma mark Housekeeping

- (RemoveStateData *)removeUnusedStates
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	RemoveStateData *result = keyboardElement->RemoveUnusedStates();
    [self.delegate documentDidChange];
	return result;
}

- (void)undoRemoveUnusedStates:(RemoveStateData *)removeStateData
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->ReplaceRemovedStates(removeStateData);
    [self.delegate documentDidChange];
}

- (ActionElementSetWrapper *)removeUnusedActions
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	shared_ptr<ActionElementSet> removedActions = keyboardElement->RemoveUnusedActions();
	ActionElementSetWrapper *result = nil;
	if (!removedActions->IsEmpty()) {
			// Some actions actually got removed
		ActionElementSetHolder *holder = new ActionElementSetHolder(removedActions);
		result = [[ActionElementSetWrapper alloc] init];
		[result setActionElements:holder];
	}
    [self.delegate documentDidChange];
	return result;
}

- (void)undoRemoveUnusedActions:(ActionElementSetWrapper *)removedActions
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->ReplaceActions([removedActions actionElements]->GetActionElementSet());
    [self.delegate documentDidChange];
}

- (void)changeStateName:(NSString *)oldStateName toName:(NSString *)newStateName
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->ReplaceStateName(ToNN(oldStateName), ToNN(newStateName));
    [self.delegate documentDidChange];
}

- (void)changeActionName:(NSString *)oldActionName toName:(NSString *)newActionName
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->ChangeActionName(ToNN(oldActionName), ToNN(newActionName));
    [self.delegate documentDidChange];
}

- (AddMissingOutputData *)addSpecialKeyOutput
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	AddMissingOutputData *data = keyboardElement->AddSpecialKeyOutput();
    [self.delegate documentDidChange];
	return data;
}

- (void)undoAddSpecialKeyOutput:(AddMissingOutputData *)addMissingOutputData
{
	boost::shared_ptr<KeyboardElement> keyboardElement = self.keyboard->GetKeyboard();
	keyboardElement->ReplaceOldOutput(addMissingOutputData);
    [self.delegate documentDidChange];
}

@end
