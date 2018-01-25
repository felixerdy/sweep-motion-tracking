import org.christopherfrantz.dbscan.*;
import org.christopherfrantz.dbscan.metrics.DistanceMetricNumbers;
import ch.bildspur.sweep.*;
import processing.serial.*;

SweepSensor sweep;

ArrayList<SweepRecord> records;
ArrayList<SweepRecord> motion;

final int SWEEP_SPEED = 1;
final int SWEEP_SAMPLE_RATE = 1000;

DBSCANClusterer<SweepRecord> clusterer;

final int MIN_CLUSTER_ELEMENTS = 3;
final int MAX_CLUSTER_ELEMENTS_DISTANCE = 10;

final int DISTANCE_TRESHOLD = 20;

final float CLUSTER_OFFSET = 1.5;

// constants

//Button Stuff
int rect1X, rect2X, rect1Y, rect2Y;
int rectHeight = 60;
int rectWidth = 150;
color rectColor, currentColor, clickedColor, hoverColor;

float scale = 1;

int countdown = 5;
int countdownStart;
boolean isCountingDown = false;

int recordingTime = 10;
int recordingStart;
boolean isRecording = false;

boolean showMovement = false;

void setup() {
  size(1000, 1000, FX2D);
  rect1X=20;
  rect2X=20;
  rect1Y=100;
  rect2Y=200;
  records = new ArrayList<SweepRecord>();
  motion = new ArrayList<SweepRecord>();
  rectColor= color(100);
  clickedColor = color(200);
  hoverColor = color(150);
  sweep = new SweepSensor(this);
  println(Serial.list());
  sweep.startAsync(Serial.list()[3], SWEEP_SPEED, SWEEP_SAMPLE_RATE);
}

void keyPressed() {
  print(key);
  if (key == '/' && scale > 0.2) {
    scale = scale - 0.1;
  } else if (key == ']') {
    scale = scale + 0.1;
  } else if (key == 'D') {
    for (SweepRecord rec : records) {
      println(rec.angle + " " + rec.distance);
    }
  }
}

void draw()
{
  background(55);

  // draw distance circles
  stroke(110, 110, 110);
  noFill();
  for (int i = 200; i <= 3000; i += 200) {
    if (i % 1000 == 0) { // each 5m should be a bold stroke
      strokeWeight(4);
    } else {
      strokeWeight(1);
    }
    ellipse(width / 2, height / 2, i * scale, i * scale);
  }

  // record button
  if (overRect1(rect1X, rect1Y, rectWidth, rectHeight)) {
    if (mousePressed && (mouseButton == LEFT)) {
      fill(clickedColor);
      isCountingDown = true;
      countdownStart = millis();
      drawSamples();
    } else {
      fill(hoverColor);
    }
  } else {
    fill(rectColor);
  }
  rect(rect1X, rect1Y, rectWidth, rectHeight);
  textSize(24);
  fill(255, 255, 255);
  if (isRecording) {
    if (millis() - recordingStart > 1000) {
      recordingTime = recordingTime - 1;
      recordingStart = millis();
    }
    if (recordingTime == -1) {
      text("Record", rect1X + 10, rect1Y + 40);
      isRecording = false;
    } else {
      text("Recording " + recordingTime, rect1X + 10, rect1Y + 40);
      recordSamples();
    }
  } else if (!isCountingDown) {
    text("Record", rect1X + 10, rect1Y + 40);
  } else {
    if (millis() - countdownStart > 1000) {
      countdown = countdown - 1;
      countdownStart = millis();
    }
    if (countdown == -1) {
      text("Recording...", rect1X + 10, rect1Y + 40);
      isCountingDown = false;
      isRecording = true;
    } else {
      text("Record in " + countdown, rect1X + 10, rect1Y + 40);
    }
  }

  // movement button
  if (overRect2(rect2X, rect2Y, rectWidth, rectHeight)) {
    if (mousePressed && (mouseButton == LEFT)) {
      fill(clickedColor);
      showMovement = !showMovement;
    } else {
      fill(hoverColor);
    }
  } else {
    fill(rectColor);
  }
  rect(rect2X, rect2Y, rectWidth, rectHeight);
  textSize(24);
  fill(255, 255, 255);
  text("Movement", rect2X + 10, rect2Y + 40); 

  if (showMovement) {
    showRecords();
    delay(200);
  } else {
    drawSamples();
  }

  // sweep dot
  fill(0, 200, 0);
  noStroke();
  ellipse(width / 2, height / 2, 20, 20);
}

void drawSamples() {
  for (SensorSample sample : sweep.getSamples()) {
    fill(255, 0, sample.getSignalStrength());
    noStroke();
    SweepRecord tempRec = new SweepRecord(sample.getAngle(), sample.getDistance());
    float x =  (width / 2) + tempRec.getCartesianX() * scale;
    float y = (height / 2) - tempRec.getCartesianY() * scale;
    ellipse(x, y, 10, 10);
  }
}

boolean overRect1(int x, int y, int width, int height) {
  if (mouseX >= x && mouseX <= x+width && 
    mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}
boolean overRect2(int x, int y, int width, int height) {
  if (mouseX >= x && mouseX <= x+width && 
    mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

void recordSamples() {
  for (SensorSample sample : sweep.getSamples()) {
    boolean found = false;
    SweepRecord compareRecord = new SweepRecord(sample.getAngle(), sample.getDistance());
    for (SweepRecord record : records) {
      if (record.angle == compareRecord.angle) {
        record.distance = (record.distance + sample.getDistance()) / 2;
        found = true;
        break;
      }
    }
    if (!found || records.size() == 0) {
      records.add(compareRecord);
    }
  }
}

void showRecords() {
  motion.clear();
  for (SweepRecord record : records) {
    fill(0, 0, 255);
    noStroke();
    float recx =  (width / 2) + record.getCartesianX() * scale;
    float recy = (height / 2) - record.getCartesianY() * scale;
    ellipse(recx, recy, 10, 10);

    for (SensorSample sample : sweep.getSamples()) {
      SweepRecord scanSample = new SweepRecord(sample.getAngle(), sample.getDistance());
      if (scanSample.angle == record.angle) {
        if (Math.abs(scanSample.distance - record.distance) > DISTANCE_TRESHOLD) {
          motion.add(scanSample);
        }
      }
    }
  }

  try {
    clusterer = new DBSCANClusterer<SweepRecord>(motion, MIN_CLUSTER_ELEMENTS, MAX_CLUSTER_ELEMENTS_DISTANCE, new DistanceMetricSweepRecord());
    ArrayList<ArrayList<SweepRecord>> clusters = clusterer.performClustering();
    println(clusters.size());
    for (ArrayList<SweepRecord> cluster : clusters) {
      if (cluster.size() > MIN_CLUSTER_ELEMENTS - 1) {
        //color rand = color(random(255), random(255), random(255));
        float minx, miny, maxx, maxy;
        minx = miny = maxx = maxy = -1;
        for (SweepRecord clusterPoint : cluster) {
          //fill(rand);
          //noStroke();
          float cluPoiX = (width / 2) + clusterPoint.getCartesianX() * scale;
          float cluPoiY = (height / 2) - clusterPoint.getCartesianY() * scale;
          //ellipse(cluPoiX, cluPoiY, 10, 10);

          if (minx == -1 || cluPoiX < minx) {
            minx = cluPoiX;
          }
          if (miny == -1 || cluPoiY < miny) {
            miny = cluPoiY;
          }
          if (maxx == -1 || cluPoiX > maxx) {
            maxx = cluPoiX;
          }
          if (maxy == -1 || cluPoiY > maxy) {
            maxy = cluPoiY;
          }
        }
        fill(255, 255, 255);
        float clusterCenterX = (maxx+minx) / 2;
        float clusterCenterY =  (maxy+miny) / 2;
        float clusterWidth = maxx - minx;
        float clusterHeight = maxy - miny;
        ellipse(clusterCenterX, 
          clusterCenterY, 
          clusterWidth * CLUSTER_OFFSET, 
          clusterHeight * CLUSTER_OFFSET);
      }
    }
  } 
  catch (Exception e) {
    //println(e);
  }
}