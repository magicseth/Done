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
}
- (NSString *) path;

@property (nonatomic, copy) NSString *filename;
@property (nonatomic, assign) CGPoint point;

@end
