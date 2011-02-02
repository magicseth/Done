    //
//  InvisibleViewController.m
//  DoneProject
//
//  Created by Seth Raphael on 2/1/11.
//  Copyright 2011 None. All rights reserved.
//

#import "InvisibleViewController.h"


@implementation InvisibleViewController

@synthesize starMan = _starMan;
@synthesize currentStar = _currentStar;

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
	self.currentStar = star;
	
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Memory", @"Memory")
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
										 destructiveButtonTitle:NSLocalizedString(@"Erase", @"Erase this memory")
											  otherButtonTitles:NSLocalizedString(@"Email", @"E-mail"),
							nil];
	[sheet showInView:self.view];
	[sheet release];
	
	
}

- (void) deleteStar;
{
	[_starMan delete:_currentStar];
	_currentStar = nil;
}
- (void) showEmail;
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
	[picker setSubject:@"A moment of audio"];
	
	
	// Set up recipients
	NSArray *toRecipients = [NSArray arrayWithObject:@"first@example.com"]; 
	NSArray *ccRecipients = [NSArray arrayWithObjects:@"second@example.com", @"third@example.com", nil]; 
	NSArray *bccRecipients = [NSArray arrayWithObject:@"fourth@example.com"]; 
	
//	[picker setToRecipients:toRecipients];
//	[picker setCcRecipients:ccRecipients];	
//	[picker setBccRecipients:bccRecipients];
	
	// Attach an image to the email
	//			NSString *path = [[NSBundle mainBundle] pathForResource:@"rainy" ofType:@"png"];
	NSData *myData = [NSData dataWithContentsOfFile:_currentStar.path];
	[picker addAttachmentData:myData mimeType:@"audio/x-caf" fileName:_currentStar.filename];
	
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
			[self deleteStar];
			break;
		default:
			break;
	}
}


- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc {
	[_currentStar release];
	_currentStar = nil;

	[_starMan release];
	_starMan = nil;

    [super dealloc];
}


@end
