//
//  LanguageRegistry.m
//  Ukelele 3
//
//  Created by John Brownie on 15/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "LanguageRegistry.h"

	// Dictionary keys
NSString *kLTRLanguageNameKey = @"LanguageName";
NSString *kLTRLanguageCodeKey = @"LanguageCode";
NSString *kLTRLanguageSuppressScriptKey = @"LanguageSuppressScript";
NSString *kLTRScriptNameKey = @"ScriptName";
NSString *kLTRScriptCodeKey = @"ScriptCode";
NSString *kLTRRegionNameKey = @"RegionName";
NSString *kLTRRegionCodeKey = @"RegionCode";
NSString *kLTRVariantNameKey = @"VariantName";
NSString *kLTRVariantCodeKey = @"VariantCode";

	// XML tags
NSString *kLTRRegistryTag = @"registry";
NSString *kLTRLanguageTag = @"language";
NSString *kLTRScriptTag = @"script";
NSString *kLTRRegionTag = @"region";
NSString *kLTRVariantTag = @"variant";
NSString *kLTRDescriptionTag = @"description";
NSString *kLTRSubtagTag = @"subtag";
NSString *kLTRSuppressScriptTag = @"suppress-script";

	// Registry file
NSString *kLTRRegistryFileName = @"language-subtag-registry";

@implementation LanguageRegistryEntry

- (id)init {
	self = [super init];
	if (self) {
		_code = @"";
		_name = @"";
		_other = @"";
	}
	return self;
}

- (BOOL)isEqualTo:(id)object {
	if ([object isKindOfClass:[LanguageRegistryEntry class]]) {
		return [self.code isEqualToString:[(LanguageRegistryEntry *)object code]] &&
		[self.name isEqualToString:[object name]] &&
		[self.other isEqualToString:[object other]];
	}
	return NO;
}

@end

@implementation LanguageRegistry {
	NSMutableArray *languageList;
	NSMutableArray *scriptList;
	NSMutableArray *regionList;
	NSMutableArray *variantList;
}

@synthesize languageList = languageList;
@synthesize scriptList = scriptList;
@synthesize regionList = regionList;
@synthesize variantList = variantList;

- (id)init {
	self = [super init];
	if (self) {
		languageList = [NSMutableArray array];
		scriptList = [NSMutableArray array];
		regionList = [NSMutableArray array];
		variantList = [NSMutableArray array];
	}
	return self;
}

+ (LanguageRegistry *)getInstance {
	static LanguageRegistry *theInstance = nil;
	if (nil == theInstance) {
			// Create the instance
		theInstance = [[LanguageRegistry alloc] init];
		NSURL *registryURL = [[NSBundle mainBundle] URLForResource:kLTRRegistryFileName withExtension:@"xml"];
		NSData *registryData = [NSData dataWithContentsOfURL:registryURL];
		[theInstance parseXMLFile:registryData];
	}
	return theInstance;
}

- (void)parseXMLFile:(NSData *)xmlData {
	NSError *theError;
	NSXMLDocument *theDocument = [[NSXMLDocument alloc] initWithData:xmlData options:0 error:&theError];
	if (nil == theDocument) {
			// Failed to read the document
		return;
	}
	NSXMLNode *rootNode = nil;
	for (NSXMLNode *childNode in [theDocument children]) {
			// Look for the root node
		if ([childNode kind] == NSXMLElementKind && [[childNode name] isEqualToString:kLTRRegistryTag]) {
			rootNode = childNode;
			break;
		}
	}
	for (NSXMLNode *childNode in [rootNode children]) {
			// Check the type of node
		if ([childNode kind] != NSXMLElementKind) {
			continue;
		}
		NSString *childName = [childNode name];
		if ([childName isEqualToString:kLTRLanguageTag]) {
				// Language name
			[self readLanguage:childNode];
		}
		else if ([childName isEqualToString:kLTRScriptTag]) {
				// Script name
			[self readScript:childNode];
		}
		else if ([childName isEqualToString:kLTRRegionTag]) {
				// Region name
			[self readRegion:childNode];
		}
		else if ([childName isEqualToString:kLTRVariantTag]) {
				// Variant name
			[self readVariant:childNode];
		}
	}
}

- (void)readLanguage:(NSXMLNode *)languageNode {
	LanguageRegistryEntry *languageEntry = [[LanguageRegistryEntry alloc] init];
	for (NSXMLNode *childNode in [languageNode children]) {
		if ([childNode kind] != NSXMLElementKind) {
			continue;
		}
		NSString *childName = [childNode name];
		if ([childName isEqualToString:kLTRSubtagTag]) {
				// This is the code
			[languageEntry setCode:[childNode stringValue]];
		}
		else if ([childName isEqualToString:kLTRDescriptionTag]) {
				// One of possibly more than one descriptions
			NSString *existingDescription = [languageEntry name];
			NSString *descriptionEntry;
			if (existingDescription == nil || [existingDescription isEqualToString:@""]) {
				descriptionEntry = [childNode stringValue];
			}
			else {
				descriptionEntry = [NSString stringWithFormat:@"%@; %@", existingDescription, [childNode stringValue]];
			}
			[languageEntry setName:descriptionEntry];
		}
		else if ([childName isEqualToString:kLTRSuppressScriptTag]) {
			[languageEntry setOther:[childNode stringValue]];
		}
	}
	[languageList addObject:languageEntry];
}

- (void)readScript:(NSXMLNode *)scriptNode {
	LanguageRegistryEntry *scriptEntry = [[LanguageRegistryEntry alloc] init];
	for (NSXMLNode *childNode in [scriptNode children]) {
		if ([childNode kind] != NSXMLElementKind) {
			continue;
		}
		NSString *childName = [childNode name];
		if ([childName isEqualToString:kLTRSubtagTag]) {
				// This is the code
			[scriptEntry setCode:[childNode stringValue]];
		}
		else if ([childName isEqualToString:kLTRDescriptionTag]) {
				// One of possibly more than one descriptions
			NSString *existingDescription = [scriptEntry name];
			NSString *descriptionEntry;
			if (existingDescription == nil || [existingDescription isEqualToString:@""]) {
				descriptionEntry = [childNode stringValue];
			}
			else {
				descriptionEntry = [NSString stringWithFormat:@"%@; %@", existingDescription, [childNode stringValue]];
			}
			[scriptEntry setName:descriptionEntry];
		}
	}
	[scriptList addObject:scriptEntry];
}

- (void)readRegion:(NSXMLNode *)regionNode {
	LanguageRegistryEntry *regionEntry = [[LanguageRegistryEntry alloc] init];
	for (NSXMLNode *childNode in [regionNode children]) {
		if ([childNode kind] != NSXMLElementKind) {
			continue;
		}
		NSString *childName = [childNode name];
		if ([childName isEqualToString:kLTRSubtagTag]) {
				// This is the code
			[regionEntry setCode:[childNode stringValue]];
		}
		else if ([childName isEqualToString:kLTRDescriptionTag]) {
				// One of possibly more than one descriptions
			NSString *existingDescription = [regionEntry name];
			NSString *descriptionEntry;
			if (existingDescription == nil || [existingDescription isEqualToString:@""]) {
				descriptionEntry = [childNode stringValue];
			}
			else {
				descriptionEntry = [NSString stringWithFormat:@"%@; %@", existingDescription, [childNode stringValue]];
			}
			[regionEntry setName:descriptionEntry];
		}
	}
	[regionList addObject:regionEntry];
}

- (void)readVariant:(NSXMLNode *)variantNode {
	LanguageRegistryEntry *variantEntry = [[LanguageRegistryEntry alloc] init];
	for (NSXMLNode *childNode in [variantNode children]) {
		if ([childNode kind] != NSXMLElementKind) {
			continue;
		}
		NSString *childName = [childNode name];
		if ([childName isEqualToString:kLTRSubtagTag]) {
				// This is the code
			[variantEntry setCode:[childNode stringValue]];
		}
		else if ([childName isEqualToString:kLTRDescriptionTag]) {
				// One of possibly more than one descriptions
			NSString *existingDescription = [variantEntry name];
			NSString *descriptionEntry;
			if (existingDescription == nil || [existingDescription isEqualToString:@""]) {
				descriptionEntry = [childNode stringValue];
			}
			else {
				descriptionEntry = [NSString stringWithFormat:@"%@; %@", existingDescription, [childNode stringValue]];
			}
			[variantEntry setName:descriptionEntry];
		}
	}
	[variantList addObject:variantEntry];
}

- (NSArray *)searchLanguage:(NSString *)searchTerm {
	if (searchTerm == nil || [searchTerm length] == 0) {
		return [self languageList];
	}
	NSMutableArray *resultArray = [NSMutableArray array];
	for (LanguageRegistryEntry *languageEntry in languageList) {
		NSString *languageName = [languageEntry name];
		NSRange searchRange = [languageName rangeOfString:searchTerm options:NSCaseInsensitiveSearch];
		if (searchRange.location != NSNotFound) {
			[resultArray addObject:languageEntry];
		}
	}
	return resultArray;
}

- (NSArray *)searchScript:(NSString *)searchTerm {
	if (searchTerm == nil || [searchTerm length] == 0) {
		return [self scriptList];
	}
	NSMutableArray *resultArray = [NSMutableArray array];
	for (LanguageRegistryEntry *scriptEntry in scriptList) {
		NSString *scriptName = [scriptEntry name];
		NSRange searchRange = [scriptName rangeOfString:searchTerm options:NSCaseInsensitiveSearch];
		if (searchRange.location != NSNotFound) {
			[resultArray addObject:scriptEntry];
		}
	}
	return resultArray;
}

- (NSArray *)searchRegion:(NSString *)searchTerm {
	if (searchTerm == nil || [searchTerm length] == 0) {
		return [self regionList];
	}
	NSMutableArray *resultArray = [NSMutableArray array];
	for (LanguageRegistryEntry *regionEntry in regionList) {
		NSString *regionName = [regionEntry name];
		NSRange searchRange = [regionName rangeOfString:searchTerm options:NSCaseInsensitiveSearch];
		if (searchRange.location != NSNotFound) {
			[resultArray addObject:regionEntry];
		}
	}
	return resultArray;
}

- (NSArray *)searchVariant:(NSString *)searchTerm {
	if (searchTerm == nil || [searchTerm length] == 0) {
		return [self variantList];
	}
	NSMutableArray *resultArray = [NSMutableArray array];
	for (LanguageRegistryEntry *variantEntry in variantList) {
		NSString *variantName = [variantEntry name];
		NSRange searchRange = [variantName rangeOfString:searchTerm options:NSCaseInsensitiveSearch];
		if (searchRange.location != NSNotFound) {
			[resultArray addObject:variantEntry];
		}
	}
	return resultArray;
}

- (LanguageCode *)normaliseLanguageCode:(LanguageCode *)originalCode {
	LanguageCode *normalisedCode = [[LanguageCode alloc] init];
	NSString *language = [originalCode languageCode];
	NSString *script = [originalCode scriptCode];
	NSString *region = [originalCode regionCode];
	NSString *variant = [originalCode variantCode];
	for (LanguageRegistryEntry *languageEntry in languageList) {
		NSString *languageCode = [languageEntry code];
		if ([languageCode isEqualToString:language]) {
			NSString *suppressScriptString = [languageEntry other];
			if (suppressScriptString != nil && [suppressScriptString isEqualToString:script]) {
				script = @"";
			}
			break;
		}
	}
	[normalisedCode setLanguageCode:language];
	[normalisedCode setScriptCode:script];
	[normalisedCode setRegionCode:region];
	[normalisedCode setVariantCode:variant];
	return normalisedCode;
}

@end