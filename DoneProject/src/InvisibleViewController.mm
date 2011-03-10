    //
//  InvisibleViewController.m
//  DoneProject
//
//  Created by Seth Raphael on 2/1/11.
//  Copyright 2011 None. All rights reserved.
//

#import "InvisibleViewController.h"
#import <AVFoundation/AVAudioSession.h>

@implementation InvisibleViewController

@synthesize placemark = _placemark;
@synthesize geocoder = _geocoder;
@synthesize testApp = _testApp;
@synthesize selectedStars = _selectedStars;
@synthesize starMan = _starMan;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self.view setBackgroundColor:[UIColor clearColor]];
	[[AVAudioSession sharedInstance] setDelegate:self];

	// Create the location manager if this object does not
    // already have one.
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];
	
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	
    // Set a movement threshold for new events.
    locationManager.distanceFilter = 500;
	
    [locationManager startUpdatingLocation];
	
}

- (void) updateLocation;
{
    [locationManager startUpdatingLocation];
}
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation;
{
    // If it's a relatively recent event, turn off updates to save power
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
			  newLocation.coordinate.latitude,
			  newLocation.coordinate.longitude);
		[locationManager stopUpdatingLocation];
		if (!_geocoder) {
			_geocoder = [[MKReverseGeocoder alloc] initWithCoordinate:newLocation.coordinate];
			[_geocoder setDelegate:self];
			[_geocoder start];
		}

    }
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark;
{
	self.placemark = placemark;
	self.geocoder = nil;
}
// There are at least two types of errors:
//   - Errors sent up from the underlying connection (temporary condition)
//   - Result not found errors (permanent condition).  The result not found errors
//     will have the domain MKErrorDomain and the code MKErrorPlacemarkNotFound
- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error;
{
	self.geocoder = nil;
}
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) showMenuForStar:(Star*)star;
{
	[self showMenuForStars: [NSArray arrayWithObject:star]];
		
	
}
- (void) showMenuForStars:(NSArray *)stars;
{
	self.selectedStars = stars;
	
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:(NSLocalizedString(@"%d Memories", @"a number of memories")), [stars count]]
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
										 destructiveButtonTitle:NSLocalizedString(@"Erase", @"Erase selected memories")
											  otherButtonTitles:NSLocalizedString(@"Email", @"E-mail"),
							nil];
	[sheet setAlpha:0.7];
	[sheet showInView:self.view];
	[sheet release];
	
	
}

- (void) deleteStars;
{
	for (Star * star in _selectedStars) {
		[_starMan delete:star];
	}
	self.selectedStars = nil;
}
- (void) showEmail;
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
	[picker setSubject:@"A moment of audio"];
	
//	[picker setToRecipients:toRecipients];
//	[picker setCcRecipients:ccRecipients];	
//	[picker setBccRecipients:bccRecipients];
	
	// Attach an image to the email
	//			NSString *path = [[NSBundle mainBundle] pathForResource:@"rainy" ofType:@"png"];
	
	for (Star * star in _selectedStars) {

		NSData *myData = [NSData dataWithContentsOfFile:star.path];
		[picker addAttachmentData:myData mimeType:@"audio/x-caf" fileName:star.filename];
	}
	// Fill out the email body text
	NSString *emailBody = @"Here is the audio I recorded with 'Listening' for the iPhone:";
	[picker setMessageBody:emailBody isHTML:NO];
	
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	switch (buttonIndex) {
		case 1:
			[self showEmail];
			break;
		case 0: // Delete
			[self deleteStars];
			break;
		default:
			break;
	}
	(*_testApp).invisibleViewControllerDismissed();
}


- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc {

	[_starMan release];
	_starMan = nil;

	[_selectedStars release];
	_selectedStars = nil;

	[_testApp release];
	_testApp = nil;

	[_geocoder release];
	_geocoder = nil;

	[_placemark release];
	_placemark = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Audio Interruption handlers
- (void)beginInterruption;
{
	//	exit(0);
	_testApp->audioInterrupted();
	NSLog(@"Interrupted");
}
- (void)endInterruption; /* endInterruptionWithFlags: will be called instead if implemented. */
{
	_testApp->audioAvailable();

	NSLog(@"Resumed");
}
- (void)inputIsAvailableChanged:(BOOL)isInputAvailable
{
	NSLog(@"Resumed");
}



@end