/*
 *  UkeleleKeyboard.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 10/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _UkeleleKeyboard_h_
#define _UkeleleKeyboard_h_

#include <memory>
#include "XMLCommentHolder.h"
#include "NXMLNode.h"
#include "KeyboardElement.h"
using std::shared_ptr;

class KeyStrokeLookUpTable;

class UkeleleKeyboard : public XMLCommentHolder {
public:
	UkeleleKeyboard(void);
	virtual ~UkeleleKeyboard(void);
	
	// Creation functions
	ErrorMessage CreateKeyboardFromXMLTree(const NXMLNode& inXMLTree);
	NXMLNode *CreateXMLTree(const bool inCodeNonAscii);
	void CreateBasicKeyboard(NString inName);
	void CreateStandardKeyboard(NString inName, UInt32 inBaseLayout, UInt32 inCommandLayout, UInt32 inCapsLockLayout);
	
	shared_ptr<KeyboardElement> GetKeyboard(void) { return mKeyboard; }
	shared_ptr<XMLCommentContainer> GetCommentContainer(void) { return mCommentContainer; }

	NArray GetStateNames(void) const { return mKeyboard->GetStateNames(kStateNone, kAllStates); }
	NArray GetStateNames(NString inState) const { return mKeyboard->GetStateNames(inState, kAllStates); }
	
	shared_ptr<KeyStrokeLookUpTable> CreateKeyStrokeLookUpTable(const UInt32 inKeyboardID);
	
	virtual NString GetDescription(void);
	
	// Comments
	void AddCreationComment(void);
	void UpdateEditingComment(void);
	XMLComment *GetCurrentComment(void);
	XMLComment *GetFirstComment(void);
	XMLComment *GetPreviousComment(void);
	XMLComment *GetNextComment(void);
	XMLComment *GetLastComment(void);

private:
	shared_ptr<KeyboardElement> mKeyboard;
	NString mDTDHeader;
	shared_ptr<XMLCommentContainer> mCommentContainer;
	
	// Forbid assignment and copy
	UkeleleKeyboard& operator=(UkeleleKeyboard& inOriginal);
	UkeleleKeyboard(UkeleleKeyboard& inOriginal);
};

#endif /* _UkeleleKeyboard_h_ */
