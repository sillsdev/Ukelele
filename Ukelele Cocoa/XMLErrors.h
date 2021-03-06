/*
 *  XMLErrors.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _XMLERRORS_H_
#define _XMLERRORS_H_

enum {
	XMLNoError = 0,
	XMLBadElementTypeError,
	XMLRepeatedWhenElement,
	XMLWrongXMLNodeTypeError,
	XMLMissingAttributeError,
	XMLUnknownModifierError,
	XMLOverSpecifiedFormError,
	XMLMissingBaseIndexError,
	XMLMissingBaseMapError,
	XMLMissingChildrenError,
	XMLRepeatedElementError,
	XMLUnknownNodeTypeError,
	XMLEmptyKeyboardError,
	XMLMultiplierActionError,
	XMLIndirectBaseMapError,
	XMLMissingActionsError,
	XMLRepeatedHeaderError,
	XMLRepeatedDTDError,
	XMLMissingLayoutsError,
	XMLMissingKeyMapSetsError,
	XMLMissingKeyMapError,
	XMLRepeatedKeyElementError,
	XMLRepeatedModifierMapError,
	XMLRepeatedKeyMapSetError,
	XMLRepeatedKeyMapError,
	XMLEmptyLayoutsElementError,
	XMLEmptyActionElementError,
	XMLTerminatorWhenNotOutputError,
	XMLSelfReferentialBaseMapError,
	XMLEmptyKeyMapSelectError,
	XMLEmptyModifierMapError,
	XMLRepeatedActionError
};

enum {
	UKNoError = 100,
	UKMissingModifierMapError,
	UKMissingKeyMapError,
	UKMissingActionError
};

#endif /* _XMLERRORS_H_ */
