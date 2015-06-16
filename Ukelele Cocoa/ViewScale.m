//
//  ViewScale.m
//  Ukelele 3
//
//  Created by John Brownie on 23/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "ViewScale.h"


@implementation ViewScale

+ (ViewScale *)createWithLabel:(NSString *)label value:(float)value
{
	ViewScale *viewScale = [[ViewScale alloc] init];
	[viewScale setScaleLabel:label];
	[viewScale setScaleValue:value];
	return viewScale;
}

+ (NSMutableArray *)standardScales
{
	NSMutableArray *scalesArray = [NSMutableArray arrayWithObjects:[ViewScale createWithLabel:@"100%" value:1.0],
								   [ViewScale createWithLabel:@"125%" value:1.25],
								   [ViewScale createWithLabel:@"150%" value:1.5],
								   [ViewScale createWithLabel:@"200%" value:2.0],
								   [ViewScale createWithLabel:@"250%" value:2.5],
								   [ViewScale createWithLabel:@"300%" value:3.0],
								   [ViewScale createWithLabel:@"350%" value:3.5],
								   [ViewScale createWithLabel:@"400%" value:4.0],
								   [ViewScale createWithLabel:@"Fit width" value:-1.0],
								   nil];
	return scalesArray;
}

@end
