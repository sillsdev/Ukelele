/*
 *  KeyStrokeLookupTable.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 10/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "KeyStrokeLookupTable.h"

#include "UkeleleConstants.h"
#include "UkeleleStrings.h"
#include "NMathUtilities.h"
#include "boost/scoped_array.hpp"
#include "XMLUtilities.h"

#pragma mark === StateTransition ===

StateTransition::StateTransition(NString inFromState, NString inToState)
	: mFromState(inFromState), mToState(inToState)
{
}

StateTransition::StateTransition(const StateTransition& inOriginal)
	: mFromState(inOriginal.mFromState), mToState(inOriginal.mToState)
{
}

StateTransition::~StateTransition(void)
{
}

StateTransition& StateTransition::operator=(const StateTransition& inOriginal)
{
	mFromState = inOriginal.mFromState;
	mToState = inOriginal.mToState;
	return *this;
}

bool StateTransition::operator<(const StateTransition& inCompareTo) const
{
	return (mFromState < inCompareTo.mFromState) ||
		(mFromState == inCompareTo.mFromState && mToState < inCompareTo.mToState);
}

bool StateTransition::operator==(const StateTransition& inCompareTo) const
{
	return mFromState == inCompareTo.mFromState &&
		mToState == inCompareTo.mToState;
}

#pragma mark === KeyStroke ===

KeyStroke::KeyStroke(const SInt16 inKeyCode, const UInt32 inModifiers)
	: mKeyCode(inKeyCode), mModifiers(inModifiers)
{
	mModifierCount = (SInt16)NMathUtilities::CountBits(mModifiers);
}

KeyStroke::KeyStroke(const KeyStroke& inOriginal)
	: mKeyCode(inOriginal.mKeyCode), mModifierCount(inOriginal.mModifierCount), mModifiers(inOriginal.mModifiers)
{
}

KeyStroke::~KeyStroke(void)
{
}

NString KeyStroke::GetModifierString(void) const
{
	NString result = "";
	UniChar stringBuffer[2];
	stringBuffer[1] = '\0';
	if (mModifiers & (controlKey | rightControlKey)) {
		stringBuffer[0] = kControlUnicode;
		result += NString(stringBuffer, sizeof(UniChar), kNStringEncodingUTF16);
	}
	if (mModifiers & cmdKey) {
		stringBuffer[0] = kCommandUnicode;
		result += NString(stringBuffer, sizeof(UniChar), kNStringEncodingUTF16);
	}
	if (mModifiers & alphaLock) {
		stringBuffer[0] = kCapsLockUnicode;
		result += NString(stringBuffer, sizeof(UniChar), kNStringEncodingUTF16);
	}
	if (mModifiers & (optionKey | rightOptionKey)) {
		stringBuffer[0] = kOptionUnicode;
		result += NString(stringBuffer, sizeof(UniChar), kNStringEncodingUTF16);
	}
	if (mModifiers & (shiftKey | rightShiftKey)) {
		stringBuffer[0] = kShiftUnicode;
		result += NString(stringBuffer, sizeof(UniChar), kNStringEncodingUTF16);
	}
	return result;
}

KeyStroke& KeyStroke::operator=(const KeyStroke& inOriginal)
{
	mKeyCode = inOriginal.mKeyCode;
	mModifierCount = inOriginal.mModifierCount;
	mModifiers = inOriginal.mModifiers;
	return *this;
}

bool KeyStroke::operator<(const KeyStroke& inCompareTo) const
{
	return (mModifierCount < inCompareTo.mModifierCount) ||
		(mModifierCount == inCompareTo.mModifierCount && mModifiers < inCompareTo.mModifiers) ||
		(mModifiers == inCompareTo.mModifiers && mKeyCode < inCompareTo.mKeyCode);
}

bool KeyStroke::operator==(const KeyStroke& inCompareTo) const
{
	return mKeyCode == inCompareTo.mKeyCode && mModifierCount == inCompareTo.mModifierCount &&
		mModifiers == inCompareTo.mModifiers;
}

CFComparisonResult KeyStroke::CompareKeyStrokeLists(KeyStrokeList inFirst, KeyStrokeList inSecond)
{
	SInt32 firstSize = static_cast<SInt32>(inFirst.size());
	SInt32 secondSize = static_cast<SInt32>(inSecond.size());
	if (firstSize == 0) {
		return secondSize == 0 ? kCFCompareEqualTo : kCFCompareLessThan;
	}
	if (firstSize < secondSize) {
		return kCFCompareLessThan;
	}
	else if (firstSize > secondSize) {
		return kCFCompareGreaterThan;
	}
	
	// Lexicographic ordering
	for (SInt32 i = 0; i < firstSize; i++) {
		KeyStroke firstKeyStroke = inFirst[i];
		KeyStroke secondKeyStroke = inSecond[i];
		if (firstKeyStroke < secondKeyStroke) {
			return kCFCompareLessThan;
		}
		else if (!(firstKeyStroke == secondKeyStroke)) {
			return kCFCompareGreaterThan;
		}
	}
	// Equal
	return kCFCompareEqualTo;
}

#pragma mark === StateTransitionTable ===

StateTransitionTable::StateTransitionTable(void)
{
}

StateTransitionTable::~StateTransitionTable(void)
{
}

void StateTransitionTable::AddTransition(NString inFromState, NString inToState, const SInt16 inKeyCode, const UInt32 inModifiers)
{
	StateTransition theTransition(inFromState, inToState);
	KeyStroke theKeyStroke(inKeyCode, inModifiers);
	mTable.insert(std::make_pair(theTransition, theKeyStroke));
}

bool StateTransitionTable::HasTransition(NString inFromState, NString inToState)
{
	StateTransition theTransition(inFromState, inToState);
	std::map<StateTransition, KeyStroke>::iterator pos = mTable.find(theTransition);
	return pos != mTable.end();
}

KeyStroke StateTransitionTable::FindTransition(StateTransition inTransition)
{
	std::map<StateTransition, KeyStroke>::iterator pos = mTable.find(inTransition);
	if (pos != mTable.end()) {
		return pos->second;
	}
	// Not present, so we return a dummy
	return KeyStroke(0, 0);
}

StateTransition StateTransitionTable::GetFirstTransition(void)
{
	mIterator = mTable.begin();
	if (mIterator != mTable.end()) {
		return mIterator->first;
	}
	// No transitions
	StateTransition theTransition("", "");
	return theTransition;
}

StateTransition StateTransitionTable::GetNextTransition(void)
{
	if (++mIterator != mTable.end()) {
		return mIterator->first;
	}
	// No more transitions
	StateTransition theTransition("", "");
	return theTransition;
}

#pragma mark === StateAccessTable ===

StateAccessTable::StateAccessTable(void)
{
}

StateAccessTable::~StateAccessTable(void)
{
}

void StateAccessTable::CreateAccessTable(shared_ptr<StateTransitionTable> inTransitionTable)
{
	StateTransition theTransition = inTransitionTable->GetFirstTransition();
	bool changeMade = true;
	while (changeMade) {
		changeMade = false;
		while (theTransition.GetFromState() != "") {
			KeyStroke transitionKeyStroke = inTransitionTable->FindTransition(theTransition);
			boost::unordered_map<NString, KeyStrokeList>::iterator keyStroke;
			NString fromState = theTransition.GetFromState();
			NString toState = theTransition.GetToState();
			if (fromState == kStateNone) {
				// This is a transition from state none to a new state
				keyStroke = mAccessTable.find(toState);
				KeyStrokeList theList;
				theList.push_back(transitionKeyStroke);
				if (keyStroke == mAccessTable.end()) {
					// We don't have this transition, so record it
					mAccessTable.insert(std::make_pair(toState, theList));
					changeMade = true;
				}
				else {
					// We have a transition, but is this shorter?
					if ((keyStroke->second).size() > 1 || transitionKeyStroke < keyStroke->second[0]) {
						// Replace it with this one
						mAccessTable.erase(keyStroke);
						mAccessTable.insert(std::make_pair(toState, theList));
						changeMade = true;
					}
				}
			}
			else if (toState != kStateNone) {
				// See if we have a transition from state none to the target state
				keyStroke = mAccessTable.find(toState);
				if (keyStroke == mAccessTable.end()) {
					// No transition direct to the state. Do we have one to the start state?
					KeyStrokeList endList;
					endList.push_back(transitionKeyStroke);
					keyStroke = mAccessTable.find(fromState);
					if (keyStroke != mAccessTable.end()) {
						// We have a key stroke now
						KeyStrokeList startList = keyStroke->second;
						startList.insert(startList.end(), endList.begin(), endList.end());
						mAccessTable.insert(std::make_pair(toState, startList));
						changeMade = true;
					}
				}
				else {
					// See if we now have a shorter transition
					KeyStrokeList currentList = keyStroke->second;
					keyStroke = mAccessTable.find(fromState);
					if (keyStroke != mAccessTable.end()) {
						// We can create an alternate sequence
						KeyStrokeList alternateList = keyStroke->second;
						alternateList.push_back(transitionKeyStroke);
						if (KeyStroke::CompareKeyStrokeLists(alternateList, currentList) == kCFCompareLessThan) {
							// It's shorter
							mAccessTable.erase(keyStroke);
							mAccessTable.insert(std::make_pair(toState, alternateList));
							changeMade = true;
						}
					}
				}
			}
			theTransition = inTransitionTable->GetNextTransition();
		}
	}
}

KeyStrokeList StateAccessTable::GetKeyStrokes(NString inTargetState)
{
	KeyStrokeList resultList;
	boost::unordered_map<NString, KeyStrokeList>::iterator pos = mAccessTable.find(inTargetState);
	if (pos != mAccessTable.end()) {
		resultList = pos->second;
	}
	return resultList;
}

#pragma mark === KeyStrokeLookUpTable ===

KeyStrokeLookUpTable::KeyStrokeLookUpTable(void)
{
}

KeyStrokeLookUpTable::~KeyStrokeLookUpTable(void)
{
}

void KeyStrokeLookUpTable::SetTransitionTable(shared_ptr<StateTransitionTable> inTable)
{
	mStateTable = inTable;
	mAccessTable.CreateAccessTable(mStateTable);
}

void KeyStrokeLookUpTable::AddKeyStroke(NString inState, KeyStroke inKeyStroke, NString inOutputString)
{
	KeyStrokeList keyStrokes;
	if (inState != kStateNone) {
		KeyStrokeList stateStrokes = mAccessTable.GetKeyStrokes(inState);
		if (stateStrokes.size() == 0) {
			// Unreachable state
			return;
		}
		keyStrokes.insert(keyStrokes.end(), stateStrokes.begin(), stateStrokes.end());
	}
	keyStrokes.push_back(inKeyStroke);
	NString keyString = XMLUtilities::ConvertEncodedString(inOutputString);
	boost::unordered_map<NString, std::pair<KeyStrokeList, NString> >::iterator pos = mLookupTable.find(keyString);
	if (pos != mLookupTable.end() && KeyStroke::CompareKeyStrokeLists(keyStrokes, (pos->second).first) == kCFCompareLessThan) {
		mLookupTable.erase(pos);
	}
	if (mLookupTable.find(keyString) == mLookupTable.end()) {
		mLookupTable.insert(std::make_pair(keyString, std::make_pair(keyStrokes, inState)));
	}
}

std::pair<KeyStrokeList, NString> KeyStrokeLookUpTable::GetKeyStrokes(NString inOutputString)
{
	std::pair<KeyStrokeList, NString> result;
	NString keyString = XMLUtilities::ConvertEncodedString(inOutputString);
	boost::unordered_map<NString, std::pair<KeyStrokeList, NString> >::iterator pos = mLookupTable.find(keyString);
	if (pos != mLookupTable.end()) {
		result = pos->second;
	}
	return result;
}
