//
//  StarManager.m
//  DoneProject
//
//  Created by Seth Raphael on 2/2/11.
//  Copyright 2011 None. All rights reserved.
//

#import "StarManager.h"
#import "Star.h"

@implementation StarManager

@synthesize allStars = _allStars;

- (id) initWithPath:(NSString *)path;
{
	if (self =[super init]) {
		_path = [path copy];
		_allStars =  [[NSKeyedUnarchiver unarchiveObjectWithFile:_path] retain];
		if (!_allStars) {
			_allStars = [[NSMutableArray alloc] init];
		}
	}
	return self;
}

- (void)dealloc
{
	[_allStars release];
	_allStars = nil;
	[_path release];
	[super dealloc];
}

- (void) addStarAtPoint:(CGPoint) point withName:(NSString*) filename;
{
	int randcolor = [StarManager randomColor];
	
	Star * newStar = [[Star alloc] init];
	[newStar setPoint:point];
	[newStar setFilename:filename];
	[newStar setColor:randcolor];
	[_allStars addObject:newStar];
	[NSKeyedArchiver archiveRootObject:_allStars toFile:_path];
}
- (void) delete:(Star*) star;
{
	// deleteFile:
	[_allStars removeObject:star];
	[NSKeyedArchiver archiveRootObject:_allStars toFile:_path];	
}

+ (int) randomColor;
{
	int colors[] = {
		
		0x5b58dd,
		0x252dac,
		0xd350ee,
		0xb50e5e,
		0xd573d8,
		0x5e81e7,
		0xd27017,
		0xfdff2d,
		0x455c0d,
		0xbfe552,
		
		0xFFFF00,
		0xFF00FF,
		0x00FFFF,
		0xFF0000,
		0x0000FF,
		0x00FF00,
		
		0xFFFFAA,
		0xFFAAFF,
		0xAAFFFF,
		0xFFAAAA,
		0xAAAAFF,
		0xAAFFAA,
		
		0xAAAA00,
		0xAA00AA,
		0x00AAAA,
		0xAA0000,
		0x0000AA,
		0x00AA00,
		
	};
	static int lastColor = 0;
	return colors[lastColor++ % 9];
}

@end
