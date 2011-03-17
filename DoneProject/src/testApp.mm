#include "testApp.h"
#import <AudioToolbox/AudioToolbox.h>
#define DURATION_OF_CIRCULAR_BUFFER (30 * 1) // in seconds
#define STAR_SIZE 15
#define DRAGGED_STAR_SIZE 35
#define STAR_TOUCH_SIZE 35
#define STAR_DRAG_MULTIPLIER 5
#define SAMPLES_TO_FADE 1000 // for a smooth sounding transition
#define CLICK_REMOVAL 1000 // take out this many samples at the end of the circular buffer
#define DEFAULT_RECORDING_DURATION 10
#define SUPPRESS_WAVE false
boolean_t drawBig;
int volumeBufferWidth;
int volumeBufferWriteIndex;
int volumeBufferReadIndex;

#include <sys/utsname.h>
#import "InvisibleViewController.h"


#define NUM_CHANNELS 1
//--------------------------------------------------------------
void testApp::setup(){	
	volumeBufferWriteIndex = 0;
	volumeBufferWriteIndex = 0;
	
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
	
	drawBig = false; // start out by drawing all stars small (when a star is touched draw it bigger)


	// Allocate a buffer that we will put three seconds of sound into, we will fill it, and then move back to the
	// beginning;
	circBufferSize		= sampleRate*DURATION_OF_CIRCULAR_BUFFER;
	circularBuffer		= new float[circBufferSize];
	volumeBufferWidth   = (DURATION_OF_CIRCULAR_BUFFER*((float)sampleRate/(float)initialBufferSize))+1;
	volumeBuffer		= new float[volumeBufferWidth];	
	screenVisBuffer     = new float[ofGetWidth()];
	awesomeBuffer		= new float[circBufferSize];	
	memset(circularBuffer, 0, circBufferSize * sizeof(float));

	recordingDuration	= DEFAULT_RECORDING_DURATION;
	
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
	[invis setTestApp:this];
	[[[UIApplication sharedApplication] keyWindow] insertSubview:[(InvisibleViewController *)invis view] aboveSubview:v];
	
	
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

void testApp::drawWave(float height = 20, float speed = 0.1f, float period = 0.04f) {
	ofNoFill();
	
	int spacing = 30;
	ofBeginShape();
	float yoffset = 50;//ofGetHeight()/2.0;
	for(int x=-spacing; x<=ofGetWidth() +spacing; x+= spacing) {
		ofCurveVertex(x, yoffset  + height * sin(x*period + ofGetFrameNum() * speed));
	}
	ofEndShape(false);
	ofFill();
}
void testApp::drawStar(float x, float y, boolean_t this_star_dragged)
{
	int star_size;
	int style = 3;
	
	float points = 5.0;
	float outerLength = 14;
	float innerLength = 6;
	float rotation = .5;
	
	if(this_star_dragged && drawBig)
	{
//		star_size=DRAGGED_STAR_SIZE;
		innerLength=innerLength*STAR_DRAG_MULTIPLIER;
		outerLength=outerLength*STAR_DRAG_MULTIPLIER;
	}
	else 
	{
//		star_size=STAR_SIZE;
	}
	
	
	if (style == 0) {
		ofLine(x+star_size,y,x-star_size,y);
		ofLine(x,y+star_size,x,y-star_size);
		ofLine(x+star_size,y-star_size,x-star_size,y+star_size);
		ofLine(x+star_size,y+star_size,x-star_size,y-star_size);	
	} else if (style == 1) {
		// Asterisk
		for (int i = 0; i < points; i++) {
			float outerx = sin((((i/points) * 360.0) * DEG_TO_RAD)) * outerLength;
			float outery = cos((((i/points) * 360.0) * DEG_TO_RAD)) * outerLength;
			ofLine(x, y, x+outerx, y+outery);
		}
	} else if (style == 2) {
		// Polygon
		for (int i = 0; i < points; i++) {
			float outerx = sin((((i/points) * 360.0) * DEG_TO_RAD)) * outerLength;
			float outery = cos((((i/points) * 360.0) * DEG_TO_RAD)) * outerLength;
			float innerx1 = sin(((((i+.5)/points) * 360.0) * DEG_TO_RAD)) * innerLength;
			float innery1 = cos(((((i+.5)/points) * 360.0) * DEG_TO_RAD)) * innerLength;
			float innerx2 = sin(((((i-.5)/points) * 360.0) * DEG_TO_RAD)) * innerLength;
			float innery2 = cos(((((i-.5)/points) * 360.0) * DEG_TO_RAD)) * innerLength;
			ofLine(x+innerx1, y+innery1, x+outerx, y+outery);
			ofLine(x+innerx2, y+innery2, x+outerx, y+outery);
		}
	} else if (style == 3) {
		// Filled Polygon
//		int twinkle = arc4random() %5;
		int max_twinkle = 60;
		int twinkle = (int)(drawCounter * .05 + x) %max_twinkle;
		if (twinkle > max_twinkle/2) {
			twinkle = max_twinkle-twinkle;
		}
		int max_growth = 6000;
		int growth = (int)(drawCounter * 10 + y) %max_growth;
		if (growth > max_growth) {
			growth = max_growth - growth; 
		}
//		outerLength += growth/1000.0;
		for (int i = 0; i < points; i++) {
			float rotationOffset = 360 * rotation + x + y + twinkle;
			float outerx = sin((((i/points) * 360.0 + rotationOffset) * DEG_TO_RAD)) * outerLength;
			float outery = cos((((i/points) * 360.0 + rotationOffset) * DEG_TO_RAD)) * outerLength;
			float innerx1 = sin(((((i+.5)/points) * 360.0 + rotationOffset) * DEG_TO_RAD)) * innerLength;
			float innery1 = cos(((((i+.5)/points) * 360.0 + rotationOffset) * DEG_TO_RAD)) * innerLength;
			float innerx2 = sin(((((i-.5)/points) * 360.0 + rotationOffset) * DEG_TO_RAD)) * innerLength;
			float innery2 = cos(((((i-.5)/points) * 360.0 + rotationOffset) * DEG_TO_RAD)) * innerLength;
			ofTriangle(x, y, x+innerx1, y+innery1, x+outerx, y+outery);
			ofTriangle(x, y, x+innerx2, y+innery2, x+outerx, y+outery);
//			ofLine(x+innerx1, y+innery1, x+outerx, y+outery);
//			ofLine(x+innerx2, y+innery2, x+outerx, y+outery);
		}
	}
}
float testApp::stepWise(float ave){
	float p1 = .05;// break points for piecewise linear scaling of sound visualization
	float p2 = 0.3;

	if(ave<p1)
	{
		ave=ave*10;
	}
	else if(ave<p2)
	{
		ave/1000;
	}
	else {
		ave/5000;
	}
	
	ave=ave*70.0f;
	if(ave>50)
	{
		ave=50;
	}
	return ave;
}
void testApp::drawJaySound(){
	float yValue = 50; // y value at which the sound file is centered vertically
	
	int circIndex;
	int theEnd=300;
	float ave;
	int displayWindowLength = DURATION_OF_CIRCULAR_BUFFER;
	float aveSampleSkip=32*(displayWindowLength/3.0);
	for (int i = 0; i < circBufferSize; i=i+initialBufferSize*(displayWindowLength/3)){
		ave=0;
		circIndex = (writehead-1-i+circBufferSize)%circBufferSize;
		for(int j=0; j<initialBufferSize; j=j+aveSampleSkip)
		{
			ave+=abs(circularBuffer[(circIndex+j)%circBufferSize]);
		}		
		ave=ave / (initialBufferSize / aveSampleSkip);
		ave = stepWise(ave);
		ofLine(theEnd-(i/initialBufferSize)/(displayWindowLength/3.0f),yValue,theEnd-(i/initialBufferSize)/(displayWindowLength/3.0f),50+ave);
		ofLine(theEnd-(i/initialBufferSize)/(displayWindowLength/3.0f),yValue,theEnd-(i/initialBufferSize)/(displayWindowLength/3.0f),50-ave);

	}
	
}

//--------------------------------------------------------------
void testApp::draw(){
	
	ofTranslate(0, 0, 0);
	// draw the input:
	ofSetColor(0x000000);
	ofRect(0,0,360,480);
	
	if (selecting) {
		ofSetColor(0x888888);   
		ofRect(selectStart.x, selectStart.y, selectEnd.x - selectStart.x,  selectEnd.y - selectStart.y);
	}

	ofSetColor(0x777777);
	float ave;

	////////////////////// draw sound wave to screen
	float aveVol;
	int counter;
	int valsInOnePixel = ((float)volumeBufferWidth)/((float)ofGetWidth());
	volumeBufferReadIndex = volumeBufferWriteIndex;
	for(int j=0;j<ofGetWidth(); j++)
	{
		aveVol=0;
		counter = 0;
		for (int i=0; i<valsInOnePixel; i++) 
		{
			aveVol = aveVol + getVolume();
			counter++;
		}
		screenVisBuffer[j] = aveVol/counter;
	}
	float radius=0;
	for(int j=0;j<ofGetWidth(); j++)
	{
		radius = screenVisBuffer[j]*200;
		if (radius>10){radius=10;}
		ofCircle(j, 50, radius);
	}
	
	

//	drawJaySound();
	
//	float xwidth = 320;
//	float yheight = 40;
//	
//	int samplesPerPixel = circBufferSize/xwidth;
//	int firstIndex = ((0 + samplesPerPixel)/ samplesPerPixel) % circBufferSize;
//	for (int i = 0; i < xwidth; i++) {
//		float value = 0;
//		for (int subSample = 0; subSample < samplesPerPixel * 10; subSample++) {
//			value += circularBuffer[(firstIndex + subSample + i * samplesPerPixel)%circBufferSize];
//		}
//		value = value / samplesPerPixel;
//		
////		int index = i/ xwidth * circBufferSize;
////		circIndex = (writehead-1-index+circBufferSize)%circBufferSize;
////		NSLog(@"writehead %d, percent %f, width %f",writehead,(writehead/(float)circBufferSize), xwidth);
//		int xvalue =   (int(2 * xwidth - (int)(-i + (writehead/(float)circBufferSize) * xwidth)) % (int)xwidth)  ;
////		NSLog(@"trying to print at %d", xvalue);
////		ave = circularBuffer[circIndex];
//		ave = value;
//		if(ave<p1)
//		{
//			ave=ave*10;
//		}
//		else if(ave<p2)
//		{
//			ave/1000;
//		}
//		else {
//			ave/5000;
//		}
//		
//		ave=ave*70.0f;
//		if(ave>50)
//		{
//			ave=50;
//		}
//		float yvalue = ave * 10 * 3;
//		ofLine(xvalue, 0, xvalue, yvalue);
//		
//	}
////	for (int i = 0; i < circBufferSize; i ++) {
////		circIndex = (writehead-1-i+circBufferSize)%circBufferSize;
////		float xvalue = xwidth * i/circBufferSize;
////		float yvalue = circularBuffer[circIndex];
////		ofLine(xvalue, 100, xvalue, -yvalue);
////		
////	}
	int	i = 0;
	for (Star * star in allThings) {
		int color = [star color];
		if (!color) {
			[star setColor:[StarManager randomColor]];
			color = [star color];
		}
		if (0 && star == touchedStar) {
			ofSetColor(0xFFFF00);
		} else {
			ofSetColor(color);
		}
		
		
		float x = star.point.x;
		float y = star.point.y;
		CGRect selection = CGRectMake(selectStart.x, selectStart.y, selectEnd.x - selectStart.x, selectEnd.y - selectStart.y);
		if (selecting & CGRectContainsPoint(selection, CGPointMake(x, y))) {
			ofSetColor(0, 0, 0);
		} else {
			ofSetColor(color);
		}
		
		if(star==touchedStar)
		{
			drawStar(x,y,true);
		}
		else
		{
			drawStar(x,y,false);
		}
		
		i++;
	}
	
	
	ofSetColor(0x333333);
	drawCounter++;
	char reportString[255];
	sprintf(reportString, "buffers received: %i\ndraw routines called: %i\n", bufferCounter,drawCounter);
	//ofDrawBitmapString(reportString, 70,308);
	
	int startX = 100;
	startX = 320 - (recordingDuration / (DURATION_OF_CIRCULAR_BUFFER *1.0) *320);

	
	const char * seconds = [[NSString stringWithFormat:@"%ds", recordingDuration] cStringUsingEncoding:NSUTF8StringEncoding];
	ofSetColor(0x666666);
	ofLine(startX, 80, startX, 30);
	ofDrawBitmapString(seconds, startX + 2, 75);
	ofEnableAlphaBlending();
	ofSetColor(0,100,100,90);
	ofRect(startX, 30, ofGetWidth()-startX, 50);
	ofDisableAlphaBlending();
	
	
//	ofEnableAlphaBlending();
//	ofSetColor(255,0,0,80);   // red, 50% transparent
//	ofRect(startX,0, 320-startX, 100);
//	ofDisableAlphaBlending();
	

	ave = abs(circularBuffer[writehead-1]);
	float mult = .7 + 2*stepWise(ave)/50.0;
	
	ofSetColor(0x751E33);
	float height = 40/3  * mult;
	float speed = 0.1;
	float period = 0.01*2;
	
	if(!SUPPRESS_WAVE)
	{
//	drawWave(height, speed, period);
	}
	ofSetColor(0xFF8954);
	height = 20/3 * mult;
	speed = 0.2;
	period = 0.04*2;
	if(!SUPPRESS_WAVE)
	{
//	drawWave(height, speed, period);
	}
	ofSetColor(0x8130A6);
	height = 70/3  * mult;
	speed = 0.034;
	period = 0.02*2;
	if(!SUPPRESS_WAVE)
	{
	drawWave(height, speed, period);
	}

	
}


float testApp::getVolume()
{
	float toReturn;
	toReturn = volumeBuffer[volumeBufferReadIndex];
	volumeBufferReadIndex++;
	volumeBufferReadIndex = volumeBufferReadIndex%volumeBufferWidth;
	return toReturn;
	
}
void testApp::setVolume(float loudness)
{
	volumeBuffer[volumeBufferWriteIndex]=loudness;
	volumeBufferWriteIndex++;
	volumeBufferWriteIndex = volumeBufferWriteIndex%volumeBufferWidth;
	
}

// 
//--------------------------------------------------------------
void testApp::audioReceived(float * input, int bufferSize, int nChannels){
	
	if( initialBufferSize != bufferSize ){
		ofLog(OF_LOG_ERROR, "your buffer size was set to %i - but the stream needs a buffer size of %i", initialBufferSize, bufferSize);
		return;
	}	
	
	if (recording) {
		/*
		int i;
		for (i=0; i<bufferSize; i++) {
			;
		}
		sprintf(reportString, "bufferSize: %i\ndraw routines called: %i\n", bufferCounter,drawCounter);

		cout<<i;
		cout<<bufferSize;
		 */
		float avg=0;
		int skip=32;
		int counter = 1;
		for (int i = 0; i < bufferSize; i=i+skip)
		{
			avg += ABS( input[i] );
			counter++;
		} 
		avg=avg/counter;
		setVolume(avg);
		// samples are "interleaved"
		// We must write them in two chunks, because we have a circular buffer.
		// We write all the way up to the end of our buffer, and then wrap around.
		int remainingSpaceInCircularBuffer = circBufferSize - writehead;
		int firstbytes = MIN(remainingSpaceInCircularBuffer, bufferSize);
		memmove(&circularBuffer[writehead], input, firstbytes * sizeof(float));
		writehead += firstbytes;
		if (writehead >= circBufferSize) {
			writehead = writehead - circBufferSize;
		}
		if (bufferSize > remainingSpaceInCircularBuffer) {
			int leftoverbytes = bufferSize - remainingSpaceInCircularBuffer;
			memmove(circularBuffer, &input[remainingSpaceInCircularBuffer], leftoverbytes  *sizeof(float));
			writehead= leftoverbytes;
		}
//		for (int i = 0; i < bufferSize; i++){
//			circularBuffer[writehead] = input[i];
//			writehead++;
//			if (writehead >= circBufferSize) {
//				writehead = writehead - circBufferSize;
//			}
////			writehead = writehead % circBufferSize;
//		}
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
		bzero(output, bufferSize * sizeof(float));
//		for (int i = 0; i < bufferSize; i++) {
//			output[i] = 0;
//		}		
	}
}
//--------------------------------------------------------------
void testApp::exit(){

}
void testApp::stopPlaying()
{
	playing = false;
	if (audioFilePlayer) {
		audioFilePlayer->StopQueue();
		audioFilePlayer->DisposeQueue(YES);
		delete audioFilePlayer;
		audioFilePlayer = nil;
	}
	
}

void testApp::playStar(Star * star)
{
	playingOldSound = true;
	stopPlaying();
	audioFilePlayer = new AQPlayer;
	if (!simulator) {
		audioFilePlayer->CreateQueueForFile((CFStringRef) star.path);
		audioFilePlayer->StartQueue(false);
	}
}

Star * testApp::whichStar(float tx, float ty)
{
	for (Star * star in allThings) {
		float x = star.point.x;
		float y = star.point.y;
		if (tx > x - STAR_TOUCH_SIZE  &&  tx < x + STAR_TOUCH_SIZE  && 
			ty > y - STAR_TOUCH_SIZE  &&  ty < y + STAR_TOUCH_SIZE ) {
			//we have a star touched.
			return star;
			break;	
		}
	}	
	return nil;
}


#pragma mark -
#pragma mark Touch Handling:


//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs &touch){
	
	drawBig=true;
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
	touchedStar = whichStar(touch.x, touch.y);
	if (touchedStar) {
		// Start playing the star that was touched.
		playStar(touchedStar);
	}
	dragged = false;
	selectStart = CGPointMake(touch.x, touch.y);
	selectEnd = CGPointMake(touch.x, touch.y);
}


//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs &touch){
	
	dragged = true;
	if (touchedStar) {
		touchedStar.point = CGPointMake(touch.x, touch.y);
	} else {
		selecting = YES;
	}

	if (touch.y < 80) {
		float ratio = 1-(touch.x)/320;
		recordingDuration = MAX(ceil(DURATION_OF_CIRCULAR_BUFFER * ratio), 5);
		recordingDuration = MIN(DURATION_OF_CIRCULAR_BUFFER, recordingDuration);
		int straightBufferSize = recordingDuration * sampleRate;
		playbackhead=writehead - straightBufferSize;
	}
	
	selectEnd = CGPointMake(touch.x, touch.y);

	
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs &touch){
	//dragged = false;
	
	drawBig=false;
	Star * endStar = whichStar(touch.x, touch.y);
	// Find if we have touched one of the stars;
	BOOL wasSelecting = selecting;
	selecting = NO;

	if (endStar && !dragged) {
		// disable star menu unless highlighted
		//[invis performSelector:@selector(showMenuForStar:) withObject:endStar afterDelay:.001];
	} else {
		if (dragged) {
			// we may have selected some stars
			CGRect selection = CGRectMake(selectStart.x, selectStart.y, selectEnd.x - selectStart.x, selectEnd.y - selectStart.y);
			NSMutableArray * selectedStars = [NSMutableArray array];

			for (Star * star in allThings) {

				float x = star.point.x;
				float y = star.point.y;
				if (CGRectContainsPoint(selection, CGPointMake(x, y))) {
					[selectedStars addObject:star];
				}
			}
			if ([selectedStars count] && wasSelecting) {
				// leave selection highlighting on the screen
				selecting = YES;
				[invis performSelector:@selector(showMenuForStars:) withObject:selectedStars afterDelay:.001];
			}


		} else 
		{
			// We just tapped one spot, record new star
			recordAudioToNewStar(touch.x, touch.y);
		}
		stopPlaying();
	}
	
	if (playingOldSound) {
		playingOldSound = false;
	}
	else {

	}
	playing = false;
	recording = true;

	
}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs &touch){

}

void testApp::recordAudioToNewStar(float tx, float ty)
{
	
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
	NSString *place;
	if ([(InvisibleViewController*)invis placemark]) {
		MKPlacemark *placemark = [(InvisibleViewController*)invis placemark];
		place = [placemark subLocality];
		if (!place) {
			place = [placemark locality];
		}
	}
	NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
	
	NSString * fileName; 
	if (place) {
		place = [place stringByReplacingOccurrencesOfString:@" " withString:@""];
		place = [place stringByReplacingOccurrencesOfString:@"," withString:@""];
		fileName = [NSString stringWithFormat:@"%@.%@.caf", dateString, place];

	} else {
		fileName = [NSString stringWithFormat:@"%@.caf", dateString];
	}
	[starMan addStarAtPoint:CGPointMake(tx, ty) withName:fileName];	


	recorder->StartRecord((CFStringRef)fileName);
	recorder->SaveSamples(straightBufferSize, straightBuffer);
	recorder->StopRecord();	
	
}


//--------------------------------------------------------------
void testApp::lostFocus(){

}

//--------------------------------------------------------------
void testApp::gotFocus(){
	audioAvailable();
	NSLog(@"We're back");
}

//--------------------------------------------------------------
void testApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){

}

void testApp::invisibleViewControllerDismissed(){
	selecting = NO;
}
void testApp::audioInterrupted(){
	ofSoundStreamStop();
	wehaveagoodaudiosession = NO;
}
void testApp::audioAvailable(){
	UInt32 session = kAudioSessionCategory_PlayAndRecord;
	AudioSessionSetProperty (		
							 kAudioSessionProperty_AudioCategory,
							 sizeof (session),
							 &session
							 );
	
	ofSoundStreamStart();
	// make it come out the loud speaker 
	UInt32 doChangeDefaultRoute = 1;
	
	AudioSessionSetProperty (
							 kAudioSessionProperty_OverrideCategoryDefaultToSpeaker,
							 sizeof (doChangeDefaultRoute),
							 &doChangeDefaultRoute
							 );
	
//	wehaveagoodaudiosession = YES;

}

