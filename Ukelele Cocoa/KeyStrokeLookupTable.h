/*
 *  KeyStrokeLookupTable.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 10/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _KeyStrokeLookUpTable_h_
#define _KeyStrokeLookUpTable_h_

#include <vector>
#include <map>
#include "boost/unordered_map.hpp"
#include "NString_hash.h"
#include "boost/tr1/memory.hpp"
using std::tr1::shared_ptr;

class StateTransition {
public:
	StateTransition(NString inFromState, NString inToState);
	StateTransition(const StateTransition& inOriginal);
	virtual ~StateTransition();
	
	NString GetFromState(void) const { return mFromState; }
	NString GetToState(void) const { return mToState; }
	
	StateTransition& operator=(const StateTransition& inOriginal);
	bool operator<(const StateTransition& inCompareTo) const;
	bool operator==(const StateTransition& inCompareTo) const;

private:
	NString mFromState;
	NString mToState;
};

typedef std::vector<StateTransition> StateTransitionList;
typedef std::vector<StateTransition>::iterator StateTransitionIterator;

class KeyStroke;

typedef std::vector<KeyStroke> KeyStrokeList;
typedef std::vector<KeyStroke>::iterator KeyStrokeIterator;

class KeyStroke {
public:
	KeyStroke(const SInt16 inKeyCode, const UInt32 inModifiers);
	KeyStroke(const KeyStroke& inOriginal);
	virtual ~KeyStroke();
	
	SInt16 GetKeyCode(void) const { return mKeyCode; }
	UInt32 GetModifiers(void) const { return mModifiers; }
	NString GetModifierString(void) const;
	
	KeyStroke& operator=(const KeyStroke& inOriginal);
	bool operator<(const KeyStroke& inCompareTo) const;
	bool operator==(const KeyStroke& inCompareTo) const;
	
	static CFComparisonResult CompareModifiers(const UInt32 inModifiers1, const UInt32 inModifiers2);
	static CFComparisonResult CompareKeyStrokeLists(KeyStrokeList inFirst, KeyStrokeList inSecond);
	static NString GetString(KeyStrokeList inKeyStrokeList);

private:
	SInt16 mKeyCode;
	SInt16 mModifierCount;
	UInt32 mModifiers;
};

class StateTransitionTable {
public:
	StateTransitionTable(void);
	virtual ~StateTransitionTable();
	
	void AddTransition(NString inFromState, NString inToState, const SInt16 inKeyCode, const UInt32 inModifiers);
	void AddTransition(NString inFromState, NString inToState, KeyStroke inKeyStroke);
	bool HasTransition(NString inFromState, NString inToState);
	KeyStroke FindTransition(NString inFromState, NString inToState);
	KeyStroke FindTransition(StateTransition inTransition);
	
	StateTransition GetFirstTransition(void);
	StateTransition GetNextTransition(void);

private:
	std::map<StateTransition, KeyStroke> mTable;
	std::map<StateTransition, KeyStroke>::iterator mIterator;
};

class StateAccessTable {
public:
	StateAccessTable(void);
	virtual ~StateAccessTable();
	
	void CreateAccessTable(shared_ptr<StateTransitionTable> inTransitionTable);
	KeyStrokeList GetKeyStrokes(NString inTargetState);

private:
	boost::unordered_map<NString, KeyStrokeList> mAccessTable;
};

class KeyStrokeLookUpTable {
public:
	KeyStrokeLookUpTable(void);
	virtual ~KeyStrokeLookUpTable();
	
	void SetTransitionTable(shared_ptr<StateTransitionTable> inTable);
	
	void AddKeyStroke(NString inState, KeyStroke inKeyStroke, NString inOutputString);
	std::pair<KeyStrokeList, NString> GetKeyStrokes(NString inOutputString);

private:
	shared_ptr<StateTransitionTable> mStateTable;
	StateAccessTable mAccessTable;
	boost::unordered_map<NString, std::pair<KeyStrokeList, NString> > mLookupTable;
};

#endif /* _KeyStrokeLookUpTable_h_ */
