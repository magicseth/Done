//
//  InvisibleViewController.h
//  DoneProject
//
//  Created by Seth Raphael on 2/1/11.
//  Copyright 2011 None. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Star.h"
#import "StarManager.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface InvisibleViewController : UIViewController <UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {

	StarManager *_starMan;
	NSArray * _selectedStars;
}

@property (nonatomic, copy) NSArray *selectedStars;


- (void) showMenuForStar:(Star*)star;
- (void) showMenuForStars:(NSArray *)stars;

@property (nonatomic, retain) StarManager *starMan;

@end
