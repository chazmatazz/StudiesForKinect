class Morpher {
  MorpherPoint[] morpherPoints;

  Morpher(ArrayList live) {
    
    morpherPoints = new MorpherPoint[live.size()];
    for (int i = 0; i < live.size(); i++) {
    PVector location = (PVector)live.get(i);
    morpherPoints[i] = new MorpherPoint(location);
    }
  }

  void render(PVector bulgeCenter, PVector sinkCenter) {
    noStroke();
    fill(255,0,0);
    ellipse(bulgeCenter.x, bulgeCenter.y, 50, 50);

    fill(0,0,255);
    ellipse(sinkCenter.x, sinkCenter.y, 50, 50);
  }
  
  void run(PVector bulgeCenter, PVector sinkCenter, float bulgeMult, float sinkMult) {
    for (int i = 0; i < morpherPoints.length; i++) {
      morpherPoints[i].run(bulgeCenter, sinkCenter, bulgeMult, sinkMult);
    }
  }
}
