//
//  StarManager.h
//  DoneProject
//
//  Created by Seth Raphael on 2/2/11.
//  Copyright 2011 None. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface StarManager : NSObject {
	NSMutableArray *_allStars;
	NSString * _path;
}
- (id) initWithPath:(NSString *)path;
- (void) addStarAtPoint:(CGPoint) point withName:(NSString*) filename;

@property (nonatomic, retain) NSMutableArray *allStars;

@end
