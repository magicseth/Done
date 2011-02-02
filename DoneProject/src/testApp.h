#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#import "AQRecorder.h"
#import "Star.h"
#import "StarManager.h"

class testApp : public ofxiPhoneApp {
	
public:
	void setup();
	void update();
	void draw();
	void exit();
	
	void touchDown(ofTouchEventArgs &touch);
	void touchMoved(ofTouchEventArgs &touch);
	void touchUp(ofTouchEventArgs &touch);
	void touchDoubleTap(ofTouchEventArgs &touch);

	void lostFocus();
	void gotFocus();
	void gotMemoryWarning();
	void deviceOrientationChanged(int newOrientation);
	
	void audioReceived( float * input, int bufferSize, int nChannels );
	void audioRequested(float * output, int bufferSize, int nChannels);

	void fadeAudio(short * soundToFade, int soundLength, int bufferLength, float rampLength, int startingPoint);

	
	int		initialBufferSize;
	int		sampleRate;
	int		drawCounter, bufferCounter;
	float 	* buffer;
	float	* circularBuffer;
	float	* awesomeBuffer;

	int		circBufferSize;
	int		playbackhead;// This points to the place in the circular Buffer that we are going to play back next
	int		writehead;
	bool	playing;
	int		soundLength;
	
	int		recordingDuration;
	AQRecorder * recorder;
	NSString * allThingsPath;
	NSArray * allThings;
	StarManager * starMan;	
	
	bool playingOldSound;

};


