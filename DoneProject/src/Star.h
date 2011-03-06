//
//  Star.h
//  DoneProject
//
//  Created by Seth Raphael on 2/2/11.
//  Copyright 2011 None. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Star : NSObject <NSCoding> {
	NSString *_filename;
	CGPoint _point;
	uint32_t _color;
}

@property (nonatomic, assign) uint32_t color;

- (NSString *) path;

@property (nonatomic, copy) NSString *filename;
@property (nonatomic, assign) CGPoint point;

@end
