class SweepRecord { 
  float angle;
  int distance; 
  SweepRecord (float a, int d) {  
    // convert to radians and round to next 0.5 decimal
    angle = (float) Math.ceil(Math.abs(a) / 0.5) * 0.5; 
    distance = d;
  }
  
  float getCartesianX() {
    return cos(radians(this.angle)) * this.distance;
  }
  
  float getCartesianY() {
    return sin(radians(this.angle)) * this.distance;
  }
} 