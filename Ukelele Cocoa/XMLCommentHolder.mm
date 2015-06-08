/*
 *  XMLCommentHolder.cpp
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "XMLCommentHolder.h"
#include <algorithm>
#include <iterator>
#include "NCocoa.h"

#pragma mark === XMLComment ===

	// Constructor

XMLComment::XMLComment(NString inComment, XMLCommentHolder *inHolder)
: mComment(inComment), mHolder(inHolder)
{
}

	// Copy constructor

XMLComment::XMLComment(const XMLComment& inOriginal)
: mComment(inOriginal.mComment), mHolder(inOriginal.mHolder)
{
}

	// Destructor

XMLComment::~XMLComment()
{
}

	// Set string

void
XMLComment::SetCommentString(NString inComment)
{
	mComment = inComment;
}

	// Add the comment to the given XML tree

void
XMLComment::AddCommentToXMLTree(NXMLNode& ioXMLTree)
{
	NXMLNode *commentTree = new NXMLNode(kNXMLNodeComment, mComment);
	ioXMLTree.AddChild(commentTree);
}

void
XMLComment::AddCommentToXML(NSXMLElement *xmlTree) {
	NSXMLElement *commentElement = [[NSXMLElement alloc] initWithKind:NSXMLCommentKind];
	[commentElement setStringValue:ToNS(mComment)];
	[xmlTree addChild:commentElement];
}

void XMLComment::SetHolder(XMLCommentHolder *inHolder)
{
	mHolder = inHolder;
}

	// Assignment operator

XMLComment&
XMLComment::operator=(const XMLComment& inOriginal)
{
	mComment = inOriginal.mComment;
	mHolder = inOriginal.mHolder;
	return *this;
}

	// Comparison

bool
XMLComment::operator<(const XMLComment& inCompareTo) const
{
	return mComment < inCompareTo.mComment;
}

bool
XMLComment::operator==(const XMLComment& inCompareTo) const
{
	return mComment == inCompareTo.mComment;
}

#pragma mark === XMLCommentHolder ===

	// Constructor

XMLCommentHolder::XMLCommentHolder(UInt32 inType)
: mHolderType(inType)
{
	mIterator = mCommentList.end();
}

	// Copy constructor

XMLCommentHolder::XMLCommentHolder(const XMLCommentHolder& inOriginal)
: mCommentList(inOriginal.mCommentList), mHolderType(inOriginal.mHolderType)
{
	mIterator = mCommentList.end();
}

	// Destructor

XMLCommentHolder::~XMLCommentHolder()
{
}

	// Set the type

void XMLCommentHolder::SetType(UInt32 inType)
{
	mHolderType = inType;
}

	// Get a description. Subclasses should override

NString XMLCommentHolder::GetDescription(void)
{
	return NString("Comment holder");
}

	// Add a comment

void
XMLCommentHolder::AddXMLComment(XMLComment *inXMLComment)
{
	if (mCommentList.empty() || mIterator == mCommentList.end()) {
		mCommentList.push_back(inXMLComment);
		mIterator = mCommentList.end();
	}
	else {
		mCommentList.insert(++mIterator, inXMLComment);
	}
	--mIterator;
}

void
XMLCommentHolder::AddXMLComment(NString inCommentString)
{
	XMLComment *newComment = new XMLComment(inCommentString, this);
	AddXMLComment(newComment);
}

	// Remove a comment. Returns true if the comment was present.

bool
XMLCommentHolder::RemoveComment(NString inCommentString)
{
	XMLCommentIterator pos;
	for (pos = mCommentList.begin(); pos != mCommentList.end(); ++pos) {
		NString commentString = (*pos)->GetCommentString();
		if (commentString == inCommentString) {
			if (pos == mIterator) {
				if (IsLastComment()) {
					if (pos != mCommentList.begin()) {
							// Only one comment in the list
						--mIterator;
					}
					else {
						mIterator = mCommentList.end();
					}
				}
				else {
					++mIterator;
				}
			}
			XMLComment *theComment = *pos;
			mCommentList.erase(pos);
			delete theComment;
			return true;
		}
	}
	return false;
}

	// Remove duplicate comments (two or more identical comments in a row)

void
XMLCommentHolder::RemoveDuplicateComments(void)
{
	if (mCommentList.empty()) {
		return;
	}
	
	NString lastComment;
	mIterator = mCommentList.begin();
	while (mIterator != mCommentList.end()) {
		NString commentString = (*mIterator)->GetCommentString();
		if (!lastComment.IsEmpty() && commentString == lastComment) {
			mIterator = mCommentList.erase(mIterator);
		}
		else {
			lastComment = (*mIterator)->GetCommentString();
			++mIterator;
		}
	}
}

	// Add comments to an XML tree

void
XMLCommentHolder::AddCommentsToXMLTree(NXMLNode& ioTree)
{
	for (mIterator = mCommentList.begin(); mIterator != mCommentList.end(); ++mIterator) {
		(*mIterator)->AddCommentToXMLTree(ioTree);
	}
	
}

void
XMLCommentHolder::AddCommentsToXML(NSXMLElement *xmlTree) {
	for (mIterator = mCommentList.begin(); mIterator != mCommentList.end(); ++mIterator) {
		(*mIterator)->AddCommentToXML(xmlTree);
	}
}

	// Find a comment

bool
XMLCommentHolder::FindComment(NString inCommentString, XMLComment*& outComment)
{
	XMLCommentIterator pos;
	for (pos = mCommentList.begin(); pos != mCommentList.end(); ++pos) {
		if ((*pos)->GetCommentString() == inCommentString) {
			outComment = *pos;
			return true;
		}
	}
	return false;
}

	// Find a comment beginning with a given string

bool
XMLCommentHolder::FindCommentWithPrefix(NString inPrefix, XMLComment*& outComment)
{
	XMLCommentIterator pos;
	for (pos = mCommentList.begin(); pos != mCommentList.end(); ++pos) {
		NString commentString = (*pos)->GetCommentString();
		if (commentString.StartsWith(inPrefix)) {
			outComment = *pos;
			return true;
		}
	}
	return false;
}

	// Replace a comment beginning with the given string by the new comment

bool
XMLCommentHolder::ReplaceCommentWithPrefix(NString inPrefix, NString inCommentString)
{
	XMLCommentIterator pos;
	for (pos = mCommentList.begin(); pos != mCommentList.end(); ++pos) {
		NString commentString = (*pos)->GetCommentString();
		if (commentString.StartsWith(inPrefix)) {
			(*pos)->SetCommentString(inCommentString);
			return true;
		}
	}
	return false;
}

	// Get the first comment in the list. Returns false if there are no comments.

bool
XMLCommentHolder::GetFirstComment(XMLComment*& outComment)
{
	if (mCommentList.empty()) {
		return false;
	}
	
	mIterator = mCommentList.begin();
	outComment = *mIterator;
	return true;
}

	// Get the last comment in the list. Returns false if there are no comments.

bool
XMLCommentHolder::GetLastComment(XMLComment*& outComment)
{
	if (mCommentList.empty()) {
		return false;
	}
	
	mIterator = mCommentList.end();
	--mIterator;
	outComment = *mIterator;
	return true;
}

	// Get the next comment in the list. Returns false if we were already at
	// the end of the list

bool
XMLCommentHolder::GetNextComment(XMLComment*& outComment)
{
	if (mCommentList.empty() || mIterator == mCommentList.end()) {
		return false;
	}
	
	if (++mIterator == mCommentList.end()) {
		return false;
	}
	outComment = *mIterator;
	return true;
}

	// Get the previous comment in the list. Returns false if we were already at
	// the beginning of the list

bool
XMLCommentHolder::GetPreviousComment(XMLComment*& outComment)
{
	if (mCommentList.empty() || mIterator == mCommentList.begin()) {
		return false;
	}
	
	--mIterator;
	outComment = *mIterator;
	return true;
}

	// Are we at the start of the comment list?

bool
XMLCommentHolder::IsFirstComment(void)
{
	if (mCommentList.empty()) {
		return false;
	}
	
	return distance(mCommentList.begin(), mIterator) == 0;
}

	// Are we at the end of the comment list?

bool
XMLCommentHolder::IsLastComment(void)
{
	if (mCommentList.empty()) {
		return false;
	}
	
	return distance(mIterator, mCommentList.end()) == 1;
}

	// Set the current comment to the supplied comment, that is, replace
	// the current comment with the supplied comment

void
XMLCommentHolder::SetCurrentComment(XMLComment *inComment)
{
	NN_ASSERT(!mCommentList.empty());
	NN_ASSERT(mIterator != mCommentList.end());
	*mIterator = inComment;
}

	// Return the current comment

bool
XMLCommentHolder::GetCurrentComment(XMLComment*& outComment)
{
	if (mCommentList.empty() || mIterator == mCommentList.end()) {
		return false;
	}
	
	outComment = *mIterator;
	return true;
}

	// Remove the current comment from the list

void
XMLCommentHolder::DeleteCurrentComment(void)
{
	NN_ASSERT(!mCommentList.empty());
	NN_ASSERT(mIterator != mCommentList.end());
	mIterator = mCommentList.erase(mIterator);
	if (!mCommentList.empty() && mIterator == mCommentList.end()) {
		--mIterator;
	}
}

	// Operators

/*
 XMLCommentHolder& XMLCommentHolder::operator=(const XMLCommentHolder& inOriginal)
 {
 mHolderType = inOriginal.mHolderType;
 mCommentList = inOriginal.mCommentList;
 return *this;
 }
 */

bool XMLCommentHolder::operator==(const XMLCommentHolder& inOriginal) const
{
	return (mHolderType == inOriginal.mHolderType) && (mCommentList == inOriginal.mCommentList);
}

bool XMLCommentHolder::operator<(const XMLCommentHolder& inOriginal) const
{
	return mCommentList < inOriginal.mCommentList;
}

#pragma mark === XMLCommentContainer ===

XMLCommentContainer::XMLCommentContainer(void)
{
	mIterator = mList.begin();
}

XMLCommentContainer::~XMLCommentContainer(void)
{
}

void XMLCommentContainer::AddCommentHolder(XMLCommentHolder *inCommentHolder)
{
	mList.push_back(inCommentHolder);
}

bool XMLCommentContainer::GetFirstComment(XMLComment*& outComment)
{
	if (mList.empty()) {
		outComment = NULL;
		return false;
	}
	for (mIterator = mList.begin(); mIterator != mList.end(); ++mIterator) {
		NN_ASSERT(*mIterator != NULL);
		bool gotElement = (*mIterator)->GetFirstComment(outComment);
		if (gotElement) {
			return true;
		}
	}
	outComment = NULL;
	return false;
}

bool XMLCommentContainer::GetLastComment(XMLComment*& outComment)
{
	if (mList.empty()) {
		outComment = NULL;
		return false;
	}
	for (std::list<XMLCommentHolder *>::reverse_iterator elementIterator = mList.rbegin(); elementIterator != mList.rend(); ++elementIterator) {
		NN_ASSERT(*elementIterator != NULL);
		bool gotElement = (*elementIterator)->GetLastComment(outComment);
		if (gotElement) {
			mIterator = find(mList.begin(), mList.end(), *elementIterator);
			return true;
		}
	}
	outComment = NULL;
	return false;
}

bool XMLCommentContainer::GetNextComment(XMLComment*& outComment)
{
	if (mList.empty()) {
		outComment = NULL;
		return false;
	}
	if ((*mIterator)->GetNextComment(outComment)) {
		return true;
	}
	NN_ASSERT(mIterator != mList.end());
	for (++mIterator; mIterator != mList.end(); ++mIterator) {
		NN_ASSERT(*mIterator != NULL);
		bool gotElement = (*mIterator)->GetFirstComment(outComment);
		if (gotElement) {
			return true;
		}
	}
	outComment = NULL;
	return false;
}

bool XMLCommentContainer::GetPreviousComment(XMLComment*& outComment)
{
	if (mList.empty()) {
		outComment = NULL;
		return false;
	}
	bool gotElement = (*mIterator)->GetPreviousComment(outComment);
	if (gotElement) {
		return true;
	}
	while (mIterator != mList.begin()) {
		--mIterator;
		NN_ASSERT(*mIterator != NULL);
		gotElement = (*mIterator)->GetLastComment(outComment);
		if (gotElement) {
			return true;
		}
	}
	outComment = NULL;
	return false;
}

bool XMLCommentContainer::IsFirstComment(void)
{
	if (mList.empty() || mIterator == mList.end()) {
		return false;
	}
	XMLCommentHolderIterator localIterator;
	for (localIterator = mList.begin(); localIterator != mList.end(); ++localIterator) {
		if ((*localIterator)->HasComments()) {
			break;
		}
	}
	if (localIterator != mList.end()) {
		if (mIterator == localIterator) {
			return (*mIterator)->IsFirstComment();
		}
	}
	return false;
}

bool XMLCommentContainer::IsLastComment(void)
{
	if (mList.empty() || mIterator == mList.end()) {
		return false;
	}
	if ((*mIterator)->IsLastComment()) {
			// It's the last comment in the current holder. Is it the last holder with comments?
		XMLCommentHolderIterator localIterator = mIterator;
		for (++localIterator; localIterator != mList.end(); ++localIterator) {
			if ((*localIterator)->HasComments()) {
				return false;
			}
		}
		return true;
	}
	return false;
}

void XMLCommentContainer::SetCurrentComment(XMLComment *inComment)
{
	if (mList.empty() || mIterator == mList.end()) {
			// What do we do now?
	}
	else {
		(*mIterator)->SetCurrentComment(inComment);
	}
}

bool XMLCommentContainer::GetCurrentComment(XMLComment*& outComment)
{
	if (mList.empty() || mIterator == mList.end()) {
		outComment = NULL;
		return false;
	}
	else if ((*mIterator)->GetCurrentComment(outComment)) {
		return true;
	}
	else {
			// Case of having removed the last comment in a list
		return GetNextComment(outComment);
	}
}

bool XMLCommentContainer::GetCurrentCommentHolder(XMLCommentHolder*& outCommentHolder)
{
	if (mList.empty() || mIterator == mList.end()) {
		return false;
	}
	outCommentHolder = *mIterator;
	return true;
}

void XMLCommentContainer::DeleteCurrentComment(void)
{
	NN_ASSERT(!mList.empty());
	NN_ASSERT(mIterator != mList.end());
	(*mIterator)->DeleteCurrentComment();
}

void XMLCommentContainer::JumpToCommentHolder(XMLCommentHolder *inCommentHolder)
{
	mIterator = find(mList.begin(), mList.end(), inCommentHolder);
}

void XMLCommentContainer::AddCommentHolders(XMLCommentHolderList& inList)
{
	mList.splice(mList.end(), inList);
}

void XMLCommentContainer::RemoveCommentHolders(XMLCommentHolderList& inList)
{
	for (XMLCommentHolderIterator pos = inList.begin(); pos != inList.end(); ++pos) {
		mList.remove(*pos);
	}
}

void XMLCommentContainer::Clear(void)
{
	mList.clear();
}
