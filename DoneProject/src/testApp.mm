#include "testApp.h"
#import <AudioToolbox/AudioToolbox.h>
#define DURATION_OF_CIRCULAR_BUFFER 30 // in seconds
#define STAR_SIZE 10
#define STAR_TOUCH_SIZE 10
#define SAMPLES_TO_FADE 1000 // for a smooth sounding transition
#define CLICK_REMOVAL 1000 // take out this many samples at the end of the circular buffer
#import "AQPlayer.h"
#include <sys/utsname.h>

#define NUM_CHANNELS 1
//--------------------------------------------------------------
void testApp::setup(){	
	
	
	// register touch events
	ofRegisterTouchEvents(this);
	
	// initialize the accelerometer
	ofxAccelerometer.setup();
	
	//iPhoneAlerts will be sent to this.
	ofxiPhoneAlerts.addListener(this);
	
	//If you want a landscape oreintation 
	//iPhoneSetOrientation(OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT);
	
	ofBackground(127,127,127);
	
	//for some reason on the iphone simulator 256 doesn't work - it comes in as 512!
	//so we do 512 - otherwise we crash
	initialBufferSize	= 512;
	sampleRate 			= 44100;
	drawCounter			= 0;
	bufferCounter		= 0;
	
	buffer				= new float[initialBufferSize];
	memset(buffer, 0, initialBufferSize * sizeof(float));


	// Allocate a buffer that we will put three seconds of sound into, we will fill it, and then move back to the
	// beginning;
	circBufferSize		= sampleRate*DURATION_OF_CIRCULAR_BUFFER;
	circularBuffer		= new float[circBufferSize];
	awesomeBuffer		= new float[circBufferSize];	
	memset(circularBuffer, 0, circBufferSize * sizeof(float));

	recordingDuration	= 10;
	
	playbackhead		= 0;
	writehead			= 0;
	playing				= false;
	recording			= true;
	playingOldSound		= false;

	
	UInt32 session = kAudioSessionCategory_PlayAndRecord;
	AudioSessionSetProperty (		
							 kAudioSessionProperty_AudioCategory,
							 sizeof (session),
							 &session
							 );
	
	// 0 output channels,
	// 1 input channels
	// 44100 samples per second
	// 512 samples per buffer
	// 4 num buffers (latency)
	ofSoundStreamSetup(NUM_CHANNELS, NUM_CHANNELS, this, sampleRate, initialBufferSize, 4);
	ofSetFrameRate(60);
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];

	allThingsPath = [[documentsDirectory stringByAppendingPathComponent:@"allThings.keys"] retain];
	starMan = [[StarManager alloc] initWithPath:allThingsPath];
	allThings = [starMan allStars];

	// make it come out the loud speaker 
	UInt32 doChangeDefaultRoute = 1;
	
	AudioSessionSetProperty (
							 kAudioSessionProperty_OverrideCategoryDefaultToSpeaker,
							 sizeof (doChangeDefaultRoute),
							 &doChangeDefaultRoute
							 );
	
	recorder = new AQRecorder();
	
	invis = [[InvisibleViewController alloc] init];
	UIView * v = iPhoneGetGLView();
	[[invis view] setUserInteractionEnabled:NO];
	[invis setStarMan:starMan];
	[[[UIApplication sharedApplication] keyWindow] insertSubview:invis.view aboveSubview:v];
	
	
	/// Check to see if we are running on the simulator
	NSString *hwid;
	// could use this but less specific: hwid = [[UIDevice currentDevice] model];
	struct utsname u;
	uname(&u);	// u.machine = "i386" for simulator, "iPod1,1" on iPod Touch, "iPhone1,1" on iPhone V1 & "iPhone1,2" on iPhone3G
	hwid = [NSString stringWithFormat:@"%s",u.machine];
	if ([hwid isEqualToString:@"i386"]) {
		simulator = YES;
	} else {
		simulator = NO;
	}

	


}

//--------------------------------------------------------------
void testApp::update(){

}

//--------------------------------------------------------------
void testApp::draw(){
	
	ofTranslate(0, 0, 0);
	
	// draw the input:
	ofSetColor(0x333333);
	ofRect(0,0,360,480);
	ofSetColor(0xFFFFFF);
	int circIndex;
	int theEnd=300;
	float ave;
	int aveSampleSkip=32*(recordingDuration/3);
	for (int i = 0; i < circBufferSize; i=i+initialBufferSize*(recordingDuration/3)){
		ave=0;
		circIndex = (writehead-1-i+circBufferSize)%circBufferSize;
//		ofLine(300);
		for(int j=0; j<initialBufferSize; j=j+aveSampleSkip)
		{
			ave+=abs(circularBuffer[(circIndex+j)%circBufferSize]);
		}		
		ave=ave / (initialBufferSize / aveSampleSkip);
		ofLine(theEnd-(i/initialBufferSize)/(recordingDuration/3.0f),200,theEnd-(i/initialBufferSize)/(recordingDuration/3.0f),200+ave*1000.0f);
		ofLine(theEnd-(i/initialBufferSize)/(recordingDuration/3.0f),200,theEnd-(i/initialBufferSize)/(recordingDuration/3.0f),200-ave*1000.0f);

	}
	
	for (Star * star in allThings) {
		float x = star.point.x;
		float y = star.point.y;
		ofLine(x+STAR_SIZE,y,x-STAR_SIZE,y);
		ofLine(x,y+STAR_SIZE,x,y-STAR_SIZE);
		ofLine(x+STAR_SIZE,y-STAR_SIZE,x-STAR_SIZE,y+STAR_SIZE);
		ofLine(x+STAR_SIZE,y+STAR_SIZE,x-STAR_SIZE,y-STAR_SIZE);

	}
	
	
	ofSetColor(0x333333);
	drawCounter++;
	char reportString[255];
	sprintf(reportString, "buffers received: %i\ndraw routines called: %i\n", bufferCounter,drawCounter);
	//ofDrawBitmapString(reportString, 70,308);
	
	
}
// 
//--------------------------------------------------------------
void testApp::audioReceived(float * input, int bufferSize, int nChannels){
	
	if( initialBufferSize != bufferSize ){
		ofLog(OF_LOG_ERROR, "your buffer size was set to %i - but the stream needs a buffer size of %i", initialBufferSize, bufferSize);
		return;
	}	
	
	if (recording) {
		// samples are "interleaved"
		for (int i = 0; i < bufferSize; i++){
			buffer[i] = input[i];
			circularBuffer[writehead] = input[i];
			writehead++;
			writehead = writehead % circBufferSize;
		}
	}
	
	bufferCounter++;
	
}

void testApp::fadeAudio(short * soundToFade, int soundLength, int bufferLength, float rampLength, int startingPoint){
	float f;
	int indexBegin;
	int indexEnd;
	for (int i = 0; i < rampLength; i++) {
		indexBegin = (i+startingPoint)%bufferLength;
		indexEnd = (startingPoint+soundLength-CLICK_REMOVAL-i)%bufferLength;
		f=(float) i; // need to do a percentage calculation, but i'm not sure if this is necessary just a precaution
		soundToFade[indexBegin] = soundToFade[indexBegin]*(f/rampLength); // fade in
		soundToFade[indexEnd] = soundToFade[indexEnd]*(f/rampLength); // fade out
	}	
	for (int i = 0; i < CLICK_REMOVAL; i++) {
		indexEnd = (startingPoint+soundLength-i)%bufferLength;
		soundToFade[indexEnd] = 0; // fade out
	}	
	
}

void testApp::audioRequested(float * output, int bufferSize, int nChannels){
	if (playing) {
		for (int i = 0; i < bufferSize; i++) {
			output[i] = circularBuffer[abs(playbackhead)% circBufferSize];
			playbackhead++;
			playbackhead = playbackhead % circBufferSize;
		}
	} else {
		// Output silence
		for (int i = 0; i < bufferSize; i++) {
			output[i] = 0;
		}		
	}

}
//--------------------------------------------------------------
void testApp::exit(){

}

//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs &touch){
	
	
	int sampleLength;
	// This code shrinks our sampleLength if we haven't yet recorded enough
	// to fill the whole circular buffer
	if (bufferCounter*initialBufferSize>DURATION_OF_CIRCULAR_BUFFER*sampleRate) {
		sampleLength=DURATION_OF_CIRCULAR_BUFFER*sampleRate;
	}
	else {
		sampleLength= bufferCounter * initialBufferSize;
	}
	// Reset the length of our next recorded sample to 0
	bufferCounter=0;

	// Find if we have touched one of the stars;
	for (Star * star in allThings) {
		float x = star.point.x;
		float y = star.point.y;
		if (touch.x > x - STAR_TOUCH_SIZE  &&  touch.x < x + STAR_TOUCH_SIZE  && 
			touch.y > y - STAR_TOUCH_SIZE  &&  touch.y < y + STAR_TOUCH_SIZE ) {
			//we have a star touched.
			playingOldSound = true;
			playing = false;
			AQPlayer * p = new AQPlayer;
			
			
			if (!simulator) {
				p->CreateQueueForFile((CFStringRef) star.path);
				p->StartQueue(false);
			}
			UIView * v = iPhoneGetGLView();
			
			[invis showMenuForStar:star];
			break;	
		}
	}
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs &touch){
	float ratio = (touch.x)/320;
	recordingDuration = MAX(ceil(DURATION_OF_CIRCULAR_BUFFER * ratio), 5);
	recordingDuration = MIN(DURATION_OF_CIRCULAR_BUFFER, recordingDuration);
	int straightBufferSize = recordingDuration * sampleRate;
	
	playbackhead=writehead - straightBufferSize;
	
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs &touch){

	if (playingOldSound) {
		playingOldSound = false;
	}
	else {
		// First, straighten out the circular buffer:
		int endingPoint = writehead;
		
		int straightBufferSize = recordingDuration * sampleRate;
		short int *  straightBuffer = new short int[straightBufferSize];
		for (int i = 0; i < straightBufferSize; i++) {
			straightBuffer[i] = circularBuffer[((i+ endingPoint - straightBufferSize + circBufferSize)%circBufferSize)] * 32000;
		}
		
		playbackhead=writehead - straightBufferSize;
		
		// Then fade the beginning and end:
		
		//	void testApp::fadeAudio(float * soundToFade, int soundLength, int bufferLength, float rampLength, int startingPoint){
		
		fadeAudio(straightBuffer, straightBufferSize, straightBufferSize, SAMPLES_TO_FADE, 0);
		
		
		//	recorder->SaveSamples(circBufferSize, circularBuffer);
		
		NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy.MM.dd.hh:mm:ss"];
		NSString *dateString = [[dateFormatter stringFromDate:[NSDate date]] stringByAppendingString:@".caf"];
		recorder->StartRecord((CFStringRef)dateString);
		recorder->SaveSamples(straightBufferSize, straightBuffer);
		recorder->StopRecord();	
		
		[starMan addStarAtPoint:CGPointMake(touch.x, touch.y) withName:dateString];
		
		playing = false;
		recording = true;
		
	}

}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs &touch){

}

//--------------------------------------------------------------
void testApp::lostFocus(){

}

//--------------------------------------------------------------
void testApp::gotFocus(){

}

//--------------------------------------------------------------
void testApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){

}

