/*
 *  ModifiersTableInfo.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 14/05/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _ModifiersTableInfo_h_
#define _ModifiersTableInfo_h_

#include <vector>

const unsigned int kInvalidModifiersIndex = 0xffffffff;

class ModifiersTableInfo {
public:
	ModifiersTableInfo(unsigned int inIndex, unsigned int inSubIndex, unsigned int inShift,
					   unsigned int inCapsLock, unsigned int inOption, unsigned int inCommand, unsigned int inControl);
	ModifiersTableInfo();
	virtual ~ModifiersTableInfo();
	
		// Member access
	void	SetIndex(const unsigned int inIndex) { mIndex = inIndex; }
	unsigned int	GetIndex() const { return mIndex; }
	void	SetSubIndex(const unsigned int inSubIndex) { mSubIndex = inSubIndex; }
	unsigned int	GetSubIndex() const { return mSubIndex; }
	void	SetShift(const unsigned int inShift) { mShift = inShift; }
	unsigned int	GetShift() const { return mShift; }
	void	SetCapsLock(const unsigned int inCapsLock) { mCapsLock = inCapsLock; }
	unsigned int	GetCapsLock() const { return mCapsLock; }
	void	SetOption(const unsigned int inOption) { mOption = inOption; }
	unsigned int	GetOption() const { return mOption; }
	void	SetCommand(const unsigned int inCommand) { mCommand = inCommand; }
	unsigned int	GetCommand() const { return mCommand; }
	void	SetControl(const unsigned int inControl) { mControl = inControl; }
	unsigned int	GetControl() const { return mControl; }
	
private:
	unsigned int mIndex;
	unsigned int mSubIndex;
	unsigned int mShift;
	unsigned int mCapsLock;
	unsigned int mOption;
	unsigned int mCommand;
	unsigned int mControl;
};

typedef std::vector<ModifiersTableInfo *> ModifiersTableInfoList;

#endif /* _ModifiersTableInfo_h_ */
