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
	Star * newStar = [[Star alloc] init];
	[newStar setPoint:point];
	[newStar setFilename:filename];
	[_allStars addObject:newStar];
	[NSKeyedArchiver archiveRootObject:_allStars toFile:_path];
}
- (void) delete:(Star*) star;
{
	// deleteFile:
	[_allStars removeObject:star];
	[NSKeyedArchiver archiveRootObject:_allStars toFile:_path];	
}

@end
