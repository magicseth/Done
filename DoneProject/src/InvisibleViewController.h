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

	Star * _currentStar;
	StarManager *_starMan;
}


- (void) showMenuForStar:(Star*)star;

@property (nonatomic, retain) StarManager *starMan;
@property (nonatomic, retain) Star *currentStar;

@end
