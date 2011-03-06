//
//  InvisibleViewController.h
//  DoneProject
//
//  Created by Seth Raphael on 2/1/11.
//  Copyright 2011 None. All rights reserved.
//
#import <UIKit/UIKit.h>

#import "testApp.h"
#import "Star.h"
#import "StarManager.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>


@interface InvisibleViewController : UIViewController <UIActionSheetDelegate, 
MFMailComposeViewControllerDelegate, 
CLLocationManagerDelegate,
MKReverseGeocoderDelegate> {

	StarManager *_starMan;
	NSArray * _selectedStars;
	testApp * _testApp;
	CLLocationManager * locationManager;
	MKReverseGeocoder * _geocoder;
	MKPlacemark * _placemark;
}

@property (nonatomic, retain) MKPlacemark *placemark;
@property (nonatomic, retain) MKReverseGeocoder *geocoder;
@property (nonatomic, assign) testApp* testApp;
@property (nonatomic, copy) NSArray *selectedStars;


- (void) showMenuForStar:(Star*)star;
- (void) showMenuForStars:(NSArray *)stars;
- (void) updateLocation;

@property (nonatomic, retain) StarManager *starMan;

@end
