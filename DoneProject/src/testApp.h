#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#import "AQRecorder.h"
#import "AQPlayer.h"

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
	void recordAudioToNewStar(float tx, float ty);
	void playStar(Star * star);
	void stopPlaying();
	void drawStar(float x, float y, boolean_t this_star_dragged, uint32_t color);
	void invisibleViewControllerDismissed();
	void audioInterrupted();
	void audioAvailable();

	void drawWave(float height, float speed, float period);
	float getVolume();
	void setVolume(float volume);
	void drawJaySound();
	float stepWise(float ave);



	Star * whichStar(float tx, float ty);
	AQPlayer *audioFilePlayer;


	
	int		initialBufferSize;
	int		sampleRate;
	int		drawCounter, bufferCounter;
	float 	* buffer;
	float	* circularBuffer;
	float   * volumeBuffer;
	float   * screenVisBuffer;
	float	* awesomeBuffer;

	int		circBufferSize;
	int		playbackhead;// This points to the place in the circular Buffer that we are going to play back next
	int		writehead;
	bool	playing;
	bool	recording;
	int		soundLength;
	
	bool	dragged;
	Star *  touchedStar;
	
	int		recordingDuration;
	AQRecorder * recorder;
	NSString * allThingsPath;
	NSArray * allThings;
	StarManager * starMan;	
	
	BOOL selecting;
	CGPoint selectStart;
	CGPoint selectEnd;
	
	BOOL simulator;
	
	NSObject * invis;

bool playingOldSound;
	BOOL wehaveagoodaudiosession;

};


