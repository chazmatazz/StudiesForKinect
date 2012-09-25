class Stage {

  ArrayList<Sequence> sequences = new ArrayList<Sequence>();
  ArrayList<PVector> closests = new ArrayList<PVector>();
  ArrayList<PVector> farthests = new ArrayList<PVector>();

  Morpher morpher;

  float a, fadeAttenuator;  

  Stage() {
    a = 0;  //Angle of rotation
    fadeAttenuator = (255-bgColor)/255;  //attenuate fade rate to whatever background color we have
  }

  void run(ArrayList<PVector> live) { //choose a mode

      if(rotateOn) {
      a += 0.015 + freq_aver/500;
    }

    if(freeze3D) {
      rotateY(a);
    }
    
    if(kill) {
      println("KILL ALL");
      killall();
    }

    //in straight playback mode, display the live point cloud
    if(mirrorOn) {
      mirror(live);
    }

    //in sequence mode, display live point cloud AND record, capture and move sequences
    if(mode == 'c') { //enter capture mode

      if(record) {
        //println("RECORD!"); 
        record(live);
      }

      if(somethingCapturing()) {
        capture(live);
        //println("SOMETHINGCAPTURING? " + somethingCapturing);
      }

      if(submode == 'o' && somethingMoving() && !somethingCapturing()) {
        move();
        //println("SOMETHINGMOVING? " + somethingMoving);
      }
      else if(submode == 'p' || submode == 'f' || submode == 'b') {
        play();
      }

      if(sequences.size() > 0) {
        checkfordead();
      }
    }

    //in morph mode, morph on top of the live point cloud
    if(mode == 'm') {
      morph(live);
    }
  }

  // display live point cloud
  void mirror(ArrayList<PVector> live) {

    for(int i=0; i < live.size(); i++) { 
      PVector thisPoint = (PVector)live.get(i); 
      stroke(255);
      pushMatrix();

      translate(thisPoint.x,thisPoint.y,thisPoint.z);

      // Draw a point
      point(0,0);
      popMatrix();
    }
  }

  void record(ArrayList live) {  //when this function is called, create a new sequence and hit record       
    int numberStills = 0;
    int durationPlay = 0;
    int repeatPlay = 0;
    float fadeRate = 0;
    int timeRecord = millis();

    if(submode == 'p' || submode == 'o') {
      numberStills = 7;
      repeatPlay = 10;
      durationPlay = int(random(100,200));
      fadeRate = (15750 / (numberStills*durationPlay*repeatPlay));
      fadeRate *= fadeAttenuator;
    }
    if(submode == 'o') {
      numberStills = 5;
    }   

    else if(submode == 'b' || submode == 'f') {
      numberStills = 1;
      durationPlay = int(random(10000,15000));
      repeatPlay = 1;
      fadeRate = 12500 / (numberStills*durationPlay*repeatPlay);
      fadeRate *= fadeAttenuator;
    }  

    sequences.add(new Sequence(live, numberStills, durationPlay, repeatPlay, fadeRate, timeRecord));
    record = false;
  }

  boolean somethingCapturing() {
    boolean somethingCapturing = false;
    for(int i = 0; i < sequences.size(); i++) {
      Sequence thisSequence = (Sequence)sequences.get(i);
      if(thisSequence.isCapturing()) {
        somethingCapturing = true;
      }
    }
    //println("SOMETHING IS CAPTURING! " + somethingCapturing);
    return somethingCapturing;
  }

  void capture(ArrayList<PVector> live) {  //capture the stills
    for(int i = 0; i < sequences.size(); i++) {
      Sequence thisSequence = (Sequence)sequences.get(i);
      if(thisSequence.ready()) { //load the latest point cloud array from the kinect into the new sequence's still objects
        thisSequence.capture(live);
      }
    }
  }


  void play() {
    for(int i = 0; i < sequences.size(); i++) {
      Sequence thisSequence = (Sequence)sequences.get(i);
      thisSequence.play();
      //println("SOMETHING IS PLAYING!");
    }
  } 

  boolean somethingMoving() {
    boolean somethingMoving = false;
    for(int i = 0; i < sequences.size(); i++) {
      Sequence thisSequence = (Sequence)sequences.get(i);
      if(thisSequence.isMoving) {
        somethingMoving = true;
      }
    }
    //println("SOMETHING IS MOVING! " + somethingMoving);
    return somethingMoving;
  }

  void move() {
    for(int i = 0; i < sequences.size(); i++) {
      Sequence thisSequence = (Sequence)sequences.get(i);
      if(thisSequence.isMoving) {
        thisSequence.move();
      }
    }
    //println("SOMETHING IS MOVING!" + somethingMoving);
  }

  void checkfordead() {
    for(int i = 0; i < sequences.size(); i++) {
      Sequence thisSequence = (Sequence)sequences.get(i);
      if(thisSequence.isDead()) {
        sequences.remove(thisSequence);
      }
    }
  }

  void killall() {
    for(int i = 0; i < sequences.size(); i++) {
      Sequence thisSequence = (Sequence)sequences.get(i);
      sequences.remove(thisSequence);
    }
  }


  void morph(ArrayList<PVector> live) { 
    int closestsMax = 20;
    int farthestsMax = 20;

    PVector closest = new PVector(0,0,-200);
    PVector farthest = new PVector(0,0,200);

    for (int i = 0; i < live.size()-1; i++) {
      PVector thisLive = (PVector)live.get(i);

      if(thisLive.z < 200 && thisLive.z > -200) {
        if(thisLive.z >= closest.z) {  //compare z-locations to find the closest and farthest points
          closest = thisLive.get();
        }
        if(thisLive.z <=farthest.z) {
          farthest = thisLive.get();
        }
      }
    }

    // Avergage the last 20 closest values to smooth it out
    if(closests.size() < closestsMax) {
      closests.add(closest);
    }
    else {
      PVector oldestClosest = (PVector)closests.get(0);
      closests.remove(oldestClosest);
    } 

    PVector closestSum = new PVector(0,0,0);    
    for(int i = 0; i < closests.size(); i++) {
      closestSum.add(closests.get(i));
    }

    closestSum.div(closests.size());   
    closest = closestSum.get();

    // Avergage the last 20 farthest values to smooth it out
    if(farthests.size() < farthestsMax) {
      farthests.add(farthest);
    }
    else {
      PVector oldestFarthest = (PVector)farthests.get(0);
      farthests.remove(oldestFarthest);
    } 

    PVector farthestSum = new PVector(0,0,0);    
    for(int i = 0; i < farthests.size(); i++) {
      farthestSum.add(farthests.get(i));
    }

    farthestSum.div(farthests.size());   
    farthest = farthestSum.get();

    println("CLOSEST: " + closest.z + "\t" + "FARTHEST: " + farthest.z);

    //(Re-)Initialize the first Morpher mass around the closest point and pass it the closest point and the closestNeighbors array
    morpher = new Morpher(live);
    //morpher.render(closest, farthest);
    morpher.run(closest, farthest, 300, 100);
  }
}

