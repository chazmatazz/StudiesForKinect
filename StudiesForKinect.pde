
// Expanding on:
// Daniel Shiffman
// Kinect Point Cloud example
// http://www.shiffman.net
// https://github.com/shiffman/libfreenect/tree/master/wrappers/java/processing

//Libraries
import org.openkinect.*;
import org.openkinect.processing.*;

import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;

Stage stage;
Kinect kinect;

Minim minim;
AudioInput in;
FFT fft;

char mode, submode;
boolean mirrorOn, record, rotateOn, freeze3D, kill, erase;
int bgColor;

// Angle of kinect camera
float deg;

// We'll use a lookup table so that we don't have to repeat the math over and over
float[] depthLookUp = new float[2048];
int depthThreshold;

// Size of kinect image
int w = 640;
int h = 480;

//Angle of rotation
float a = 0;

//Audio
float freq_aver=0;
boolean firstPeak;
int timePeak, gapPeak;

//Pre-calculated Stuff

final double fx_d = 1.0 / 5.9421434211923247e+02;
final double fy_d = 1.0 / 5.9104053696870778e+02;
final double cx_d = 3.3930780975300314e+02;
final double cy_d = 2.4273913761751615e+02;


void setup() {
  size(1280,700, P3D);
  smooth();

  stage = new Stage();
  kinect = new Kinect(this);

  kinect.start();
  kinect.enableDepth(true);
  // We don't need the grayscale image in this example
  // so this makes it more efficient
  kinect.processDepthImage(false);

  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO,1024);
  fft = new FFT(in.bufferSize(), in.sampleRate());

  // Lookup table for all possible depth values (0 - 2047)
  for (int i = 0; i < depthLookUp.length; i++) {
    depthLookUp[i] = rawDepthToMeters(i);
  }

  depthThreshold = -650;

  deg = 10;
  kinect.tilt(deg);

  mirrorOn = true;
  record = false;
  rotateOn = true;
  freeze3D = true;
  erase = true;
  mode = 'c';
  submode = 'p';

  firstPeak = false;
  timePeak = 0;
  gapPeak = 1000;
  
  bgColor = 55;
}


void draw() {
  if(erase){
  background(bgColor);
  }

  /*fill(255);
  textMode(SCREEN);
  text("Kinect FR: " + (int)kinect.getDepthFPS() + "\nProcessing FR: " + (int)frameRate + "\n\nEnter to Rotate\nm to morph\nc to capture\n  f for freeze frame\n  b for breath\n  p for playback\n  o for ooze", 10,16);
  */
  
  translate(width/2,height/2,-50);
  audio_anal();
  stage.run(capture());
}

void audio_anal() {
  fft.forward(in.left);
  int counter = 0;
  float sum = 0;
  float freq_sum = 0;
  for (int i = 0; i < fft.specSize(); i++) {
    if (fft.getBand(i)>10) {
      sum += fft.getBand(i);
      freq_sum += i;
      counter++;
    }
  }

  if(counter > 0 && gapPeak > 500 && !firstPeak) {
    firstPeak = true;
    timePeak = millis();
  }
  else if(counter > 0) {
    freq_aver=freq_sum/counter;
    firstPeak = false;
    timePeak = millis();
    gapPeak = 0;
  }
  else {
    gapPeak = millis() - timePeak;
    firstPeak = false;
  }

  if (firstPeak) {  
    record=true;
    println("RECORD!!");
  }
}

ArrayList capture() {
  // Get the raw depth as array of integers
  int[] depth = kinect.getRawDepth();

  ArrayList<PVector> live = new ArrayList<PVector>();

  // We're just going to calculate and draw every 4th pixel (equivalent of 160x120)
  int skip = 4;

  for(int x=0; x<w; x+=skip) {
    for(int y=0; y<h; y+=skip) {
      int offset = x+y*w;

      // Convert kinect data to world xyz coordinate
      int rawDepth = depth[offset];
      PVector v = depthToWorld(x,y,rawDepth);
      // Scale up by 200
      float factor = 300;
      if((factor-v.z*factor) > depthThreshold) {   
        live.add(new PVector(v.x*factor, v.y*factor, factor-v.z*factor));
      }
    }
  }
  return live;
}

// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}

PVector depthToWorld(int x, int y, int depthValue) {

  PVector result = new PVector();
  double depth =  depthLookUp[depthValue];//rawDepthToMeters(depthValue);
  result.x = (float)((x - cx_d) * depth * fx_d);
  result.y = (float)((y - cy_d) * depth * fy_d);
  result.z = (float)(depth);
  return result;
}


void stop() {
  kinect.quit();
  super.stop();
}

void keyPressed() {

  if(key == 'l') {
    mirrorOn = !mirrorOn; //just live
  }

  if(key == 'm') {
    mode = 'm'; //morph playback
  }
  else if(key == 'c') {
    mode = 'c'; //capture and play sequences from the past in various ways
  }

  ////////////////////////////////

  if(key == 'f') {
    submode = 'f';  //freeze single still;
  }  

  else if(key == 'b') {
    submode = 'b';
  } 

  else if(key == 'p') {
    submode = 'p';  //straight playback
  }

  else if(key == 'o') {
    submode = 'o'; //ooze points from still to still
  }


  if(key == ENTER) {
    rotateOn = !rotateOn;
    if(rotateOn) {
      freeze3D = true;
    }
  }  

  if(key == 32) {  //flag to record sequence
    record = true;
    println("RECORD");
  }
  
  if(key == TAB) {
    freeze3D = !freeze3D;
    if(!freeze3D) {
     rotateOn = false; 
    }
  }

  if (key == CODED) {
    if (keyCode == UP) {
      deg++;
    } 
    else if (keyCode == DOWN) {
      deg--;
    }

    deg = constrain(deg,0,30);
    kinect.tilt(deg);
  }
  
  if (key == 'e') {
    erase=false;
  }
  else{
    erase=true;
  }
  
  if(key == 'k') {
    kill = true; 
  }
  else {
    kill = false;
  }
  
  
  
}

