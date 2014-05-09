//
//  UnicodeTable.m
//  Ukelele 3
//
//  Created by John Brownie on 14/02/13.
//
//

#import "UnicodeTable.h"

#define kUnicodeTableFile	@"UCDNamesList"

@interface UnicodeTable () {
	NSMutableDictionary *unicodeTable;
}

@end

@implementation UnicodeTable

- (id)init {
	self = [super init];
	if (self) {
		unicodeTable = [NSMutableDictionary dictionaryWithCapacity:25000];
	}
	return self;
}

+ (UnicodeTable *)getInstance {
	static UnicodeTable *theInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		theInstance = [[UnicodeTable alloc] init];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
			[theInstance setupTable];
		});
	});
	return theInstance;
}

+ (void)setup {
	[UnicodeTable getInstance];
}

- (NSString *)descriptionForCodePoint:(NSInteger)codePoint {
	return unicodeTable[@(codePoint)];
}

- (void)setupTable {
	NSURL *tableURL = [[NSBundle mainBundle] URLForResource:kUnicodeTableFile withExtension:@"txt"];
	NSError *theError;
	NSString *unicodeInfo = [NSString stringWithContentsOfURL:tableURL encoding:NSUTF8StringEncoding error:&theError];
#ifdef USE_REGEX
	[self scanTable:unicodeInfo];
#else
	NSScanner *theScanner = [NSScanner scannerWithString:unicodeInfo];
	while (![theScanner isAtEnd]) {
		unsigned int codePoint;
		NSString *codePointDescription;
		if ([theScanner scanHexInt:&codePoint] && [theScanner scanUpToString:@"\n" intoString:&codePointDescription]) {
			[unicodeTable setObject:codePointDescription forKey:@(codePoint)];
		}
	}
#endif
}

- (void)scanTable:(NSString *)sourceString {
	NSError *theError;
	NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"([0-9A-Fa-f]+)\\t(.*)\\n" options:0 error:&theError];
	[regEx enumerateMatchesInString:sourceString options:0 range:NSMakeRange(0, [sourceString length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
		NSScanner *scanner = [NSScanner scannerWithString:[sourceString substringWithRange:[result rangeAtIndex:1]]];
		unsigned int codePoint;
		if ([scanner scanHexInt:&codePoint]) {
			[unicodeTable setObject:[sourceString substringWithRange:[result rangeAtIndex:2]] forKey:@(codePoint)];
		}
	}];
}

@end
