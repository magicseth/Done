//
//  Star.m
//  DoneProject
//
//  Created by Seth Raphael on 2/2/11.
//  Copyright 2011 None. All rights reserved.
//

#import "Star.h"


@implementation Star

@synthesize filename = _filename;
@synthesize point = _point;

- (void)dealloc
{
	[_filename release];
	_filename = nil;

	[super dealloc];
}

- (NSString *) path;
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:_filename];	
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
	[aCoder encodeFloat:_point.x forKey:@"x"];
	[aCoder encodeFloat:_point.y forKey:@"y"];
	[aCoder encodeObject:_filename forKey:@"filename"];
}
- (id)initWithCoder:(NSCoder *)aDecoder;
{
	if (self = [super init]) {
		float x = [aDecoder decodeFloatForKey:@"x"];
		float y = [aDecoder decodeFloatForKey:@"y"];
		_filename = [[aDecoder decodeObjectForKey:@"filename"] retain];
		_point = CGPointMake(x, y);
	}
	return self;
}


@end
