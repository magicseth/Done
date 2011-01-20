#include "testApp.h"
#import <AudioToolbox/AudioToolbox.h>
#define DURATION_OF_CIRCULAR_BUFFER 3 // in seconds
#define SAMPLES_TO_FADE 1000 // for a smooth sounding transition
#define CLICK_REMOVAL 1000 // take out this many samples at the end of the circular buffer

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
	
	playbackhead		= 0;
	writehead			= 0;
	playing				= false;

	
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

	// make it come out the loud speaker 
	UInt32 doChangeDefaultRoute = 1;
	
	AudioSessionSetProperty (
							 kAudioSessionProperty_OverrideCategoryDefaultToSpeaker,
							 sizeof (doChangeDefaultRoute),
							 &doChangeDefaultRoute
							 );
	
	recorder = new AQRecorder();

	recorder->StartRecord(CFSTR("recordedFile.caf"));
	
}

//--------------------------------------------------------------
void testApp::update(){

}

//--------------------------------------------------------------
void testApp::draw(){
	
	ofTranslate(0, -50, 0);
	
	// draw the input:
	ofSetColor(0x333333);
	ofRect(70,100,256,200);
	ofSetColor(0xFFFFFF);
	for (int i = 0; i < initialBufferSize; i++){
		ofLine(70+i,200,70+i,200+buffer[i]*100.0f);
	}
	
	ofSetColor(0x333333);
	drawCounter++;
	char reportString[255];
	sprintf(reportString, "buffers received: %i\ndraw routines called: %i\n", bufferCounter,drawCounter);
	ofDrawBitmapString(reportString, 70,308);
	
	
}
// 
//--------------------------------------------------------------
void testApp::audioReceived(float * input, int bufferSize, int nChannels){
	
	if( initialBufferSize != bufferSize ){
		ofLog(OF_LOG_ERROR, "your buffer size was set to %i - but the stream needs a buffer size of %i", initialBufferSize, bufferSize);
		return;
	}	
	
	if (!playing) {
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

void testApp::fadeAudio(float * soundToFade, int soundLength, int bufferLength, float rampLength, int startingPoint){
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
			output[i] = circularBuffer[playbackhead];
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
	playing = true;

	
	playbackhead=writehead;
	int sampleLength;
	if (bufferCounter*initialBufferSize>DURATION_OF_CIRCULAR_BUFFER*sampleRate) {
		sampleLength=DURATION_OF_CIRCULAR_BUFFER*sampleRate;
	}
	else {
		sampleLength= bufferCounter * initialBufferSize;
	}
	
	fadeAudio(circularBuffer, sampleLength, DURATION_OF_CIRCULAR_BUFFER*sampleRate, SAMPLES_TO_FADE, playbackhead);
	bufferCounter=0;

	recorder->SaveSamples(circBufferSize, circularBuffer);
	recorder->StopRecord();	
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs &touch){

}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs &touch){
	playing = false;
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

