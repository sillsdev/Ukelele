/*
 *  XMLCommentHolder.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _XMLCommentHolder_h_
#define _XMLCommentHolder_h_

#include <list>
#include "boost/tr1/memory.hpp"
#include "NString.h"
#include "NXMLNode.h"

class XMLCommentHolder; // Forward declaration

class XMLComment {
public:
	XMLComment(NString inComment = "", XMLCommentHolder *inHolder = NULL);
	XMLComment(const XMLComment& inOriginal);
	virtual ~XMLComment();
	
	void SetCommentString(NString inComment);
	NString GetCommentString(void) const { return mComment; }
	void AddCommentToXMLTree(NXMLNode& ioXMLTree);
	void AddCommentToXML(NSXMLElement *xmlTree);
	
	void SetHolder(XMLCommentHolder *inHolder);
	XMLCommentHolder *GetHolder(void) const { return mHolder; }
	
	XMLComment& operator=(const XMLComment& inOriginal);
	bool operator<(const XMLComment& inCompareTo) const;
	bool operator==(const XMLComment& inCompareTo) const;
	
private:
	NString mComment;
	XMLCommentHolder *mHolder;
};

typedef std::list<XMLComment *> XMLCommentList;
typedef std::list<XMLComment *>::iterator XMLCommentIterator;

enum {
	kNoElementType,
	kDocumentType,
	kWhenElementType,
	kTerminatorsElementType,
	kModifierMapType,
	kModifierElementType,
	kLayoutsElementType,
	kLayoutElementType,
	kKeyElementType,
	kKeyMapElementType,
	kKeyboardElementType,
	kKeyMapSetType,
	kKeyMapSelectType,
	kActionElementType,
	kActionElementSetType,
	kContainerElementType
};

class XMLCommentHolder {
public:
	XMLCommentHolder(UInt32 inType = kNoElementType);
	XMLCommentHolder(const XMLCommentHolder& inOriginal);
	virtual ~XMLCommentHolder();
	
		// Type
	void SetType(UInt32 inType);
	UInt32 GetType(void) const { return mHolderType; }
	
	virtual NString GetDescription(void);
	
		// Add and remove comments
	void AddXMLComment(XMLComment *inXMLComment);
	void AddXMLComment(NString inCommentString);
	bool RemoveComment(NString inCommentString);
	void RemoveDuplicateComments(void);
	void AddCommentsToXMLTree(NXMLNode& ioTree);
	void AddCommentsToXML(NSXMLElement *xmlTree);
	UInt32 GetCommentCount(void) { return static_cast<UInt32>(mCommentList.size()); }
	bool HasComments(void) { return !mCommentList.empty(); }
	
		// Find and replace
	bool FindComment(NString inCommentString, XMLComment*& outComment);
	bool FindCommentWithPrefix(NString inPrefix, XMLComment*& outComment);
	bool ReplaceCommentWithPrefix(NString inPrefix, NString inCommentString);
	
		// Iterator functions
	bool GetFirstComment(XMLComment*& outComment);
	bool GetLastComment(XMLComment*& outComment);
	bool GetNextComment(XMLComment*& outComment);
	bool GetPreviousComment(XMLComment*& outComment);
	bool IsFirstComment(void);
	bool IsLastComment(void);
	void SetCurrentComment(XMLComment *inComment);
	bool GetCurrentComment(XMLComment*& outComment);
	void DeleteCurrentComment(void);
	
		// Operators
		//	XMLCommentHolder& operator=(const XMLCommentHolder& inOriginal);
	bool operator==(const XMLCommentHolder& inOriginal) const;
	bool operator<(const XMLCommentHolder& inOriginal) const;
	
private:
	XMLCommentList mCommentList;
	XMLCommentIterator mIterator;
	UInt32 mHolderType;
};

typedef std::list<XMLCommentHolder *> XMLCommentHolderList;
typedef std::list<XMLCommentHolder *>::iterator XMLCommentHolderIterator;

class XMLCommentContainer {
public:
	XMLCommentContainer(void);
	virtual ~XMLCommentContainer(void);
	
	void AddCommentHolder(XMLCommentHolder *inCommentHolder);
	bool GetFirstComment(XMLComment*& outComment);
	bool GetLastComment(XMLComment*& outComment);
	bool GetNextComment(XMLComment*& outComment);
	bool GetPreviousComment(XMLComment*& outComment);
	bool IsFirstComment(void);
	bool IsLastComment(void);
	void SetCurrentComment(XMLComment *inComment);
	bool GetCurrentComment(XMLComment*& outComment);
	bool GetCurrentCommentHolder(XMLCommentHolder*& outCommentHolder);
	void DeleteCurrentComment(void);
	void JumpToCommentHolder(XMLCommentHolder *inCommentHolder);
	
	void AddCommentHolders(XMLCommentHolderList& inList);
	void RemoveCommentHolders(XMLCommentHolderList& inList);
	void Clear(void);
	
private:
	XMLCommentHolderList mList;
	XMLCommentHolderIterator mIterator;
};

#endif // _XMLCommentHolder_h_
