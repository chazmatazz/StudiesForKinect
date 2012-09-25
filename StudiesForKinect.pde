// draws on SimpleOpenNI DepthMap3d example

import SimpleOpenNI.*;

import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;

Stage stage;

SimpleOpenNI context;

Minim minim;
AudioInput in;
FFT fft;

char mode, submode;
boolean mirrorOn, record, rotateOn, freeze3D, kill, erase;
int bgColor;

// Size of kinect image
int w = 640;
int h = 480;

//Angle of rotation
float a = 0;

//Audio
float freq_aver = 0;
boolean firstPeak;
int timePeak, gapPeak;

void setup() {
  size(1280,700, P3D);
  smooth();

  stage = new Stage();
  context = new SimpleOpenNI(this);

  // enable depthMap generation 
  if(context.enableDepth() == false)
  {
     println("Can't open the depthMap, maybe the camera is not connected!"); 
     exit();
     return;
  }

  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO,1024);
  fft = new FFT(in.bufferSize(), in.sampleRate());

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
  
  // update the cam
  context.update();
  
  if(erase){
  background(bgColor);
  }

  fill(255);
  textMode(SCREEN);
  //text("Kinect FR: " + (int)context.getDepthFPS() + "\nProcessing FR: " + (int)frameRate, 10, 16);
  text("Enter to Rotate\nm to morph\nc to capture\n  f for freeze frame\n  b for breath\n  p for playback\n  o for ooze",  10, 32);
  
  
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

/*
return an ArrayList of points from the point cloud
*/
ArrayList capture() {
  ArrayList<PVector> ret = new ArrayList<PVector>();
  
    int[]   depthMap = context.depthMap();
  int     steps   = 10;
  int     index;
  PVector realWorldPoint;

  PVector[] realWorldMap = context.depthMapRealWorld();
  for(int y=0;y < context.depthHeight();y+=steps)
  {
    for(int x=0;x < context.depthWidth();x+=steps)
    {
      index = x + y * context.depthWidth();
      if(depthMap[index] > 0)
      { 
        // draw the projected point
        realWorldPoint = realWorldMap[index];
        ret.add(new PVector(realWorldPoint.x/4, -realWorldPoint.y/4, realWorldPoint.z/4));  // make realworld z negative, in the 3d drawing coordsystem +z points in the direction of the eye
      }
    }
  } 
  
  return ret;
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

