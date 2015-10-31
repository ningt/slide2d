/* --------------------------------------------------------------------------
 * SimpleOpenNI NITE Slider2d
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / zhdk / http://iad.zhdk.ch/
 * date:  03/28/2011 (m/d/y)
 * ----------------------------------------------------------------------------
 *
 * ----------------------------------------------------------------------------
 */
import SimpleOpenNI.*;
import java.util.Random;

SimpleOpenNI          context;

// NITE
XnVSessionManager     sessionManager;
XnVSelectableSlider2D trackPad;

int gridX = 7;
int gridY = 6;

Trackpad   trackPadViz;

// unlock point sequence
int[] xPoints = new int[4];
int[] yPoints = new int[4];

Point[][] tokenPad = new Point[gridX][gridY-1];

Point highlight = randomPoint();

void setup() {
  context = new SimpleOpenNI(this,SimpleOpenNI.RUN_MODE_MULTI_THREADED);
   
  // mirror is by default enabled
  context.setMirror(true);
  
  // enable depthMap generation 
  context.enableDepth();
  
  // enable the hands + gesture
  context.enableGesture();
  context.enableHands();
 
  // setup NITE 
  sessionManager = context.createSessionManager("Click,Wave", "RaiseHand");

  trackPad = new XnVSelectableSlider2D(gridX,gridY);
  sessionManager.AddListener(trackPad);

  trackPad.RegisterItemHover(this);
  trackPad.RegisterValueChange(this);
  trackPad.RegisterItemSelect(this);
  
  trackPad.RegisterPrimaryPointCreate(this);
  trackPad.RegisterPrimaryPointDestroy(this);

  // create gui viz
  trackPadViz = new Trackpad(new PVector(context.depthWidth()/2, context.depthHeight()/2,0),
                                         gridX, gridY-1, 50, 50, 15);  

  size(context.depthWidth(), context.depthHeight()); 
  smooth();
  
   // info text
  println("-------------------------------");  
  println("1. Wave till the tiles get green");  
  println("2. The relative hand movement will select the tiles");  
  println("-------------------------------");   

  String fileName = "data/data.txt";
  readTokenPad(fileName);
}

void draw() {
  // update the cam
  context.update();
  
  // update nite
  context.update(sessionManager);
  
  // draw depthImageMap
  image(context.depthImage(),0,0);
  
  trackPadViz.draw();
}

void keyPressed() {
  switch(key) {
  case 'e':
    // end sessions
    sessionManager.EndSession();
    println("end session");
    break;
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// session callbacks

void onStartSession(PVector pos) {
  println("onStartSession: " + pos);
}

void onEndSession() {
  println("onEndSession: ");
}

void onFocusSession(String strFocus,PVector pos,float progress) {
  println("onFocusSession: focus=" + strFocus + ",pos=" + pos + ",progress=" + progress);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// XnVSelectableSlider2D callbacks

void onItemHover(int nXIndex,int nYIndex) {
  println("onItemHover: nXIndex=" + nXIndex +" nYIndex=" + nYIndex);
  
  trackPadViz.update(nXIndex, nYIndex);
}

void onValueChange(float fXValue,float fYValue) {
 // println("onValueChange: fXValue=" + fXValue +" fYValue=" + fYValue);
}

void onItemSelect(int nXIndex, int nYIndex, int eDir) {
  println("onItemSelect: nXIndex=" + nXIndex + " nYIndex=" + nYIndex + " eDir=" + eDir);
  trackPadViz.push(nXIndex, nYIndex, eDir);
}

void onPrimaryPointCreate(XnVHandPointContext pContext,XnPoint3D ptFocus) {
  println("onPrimaryPointCreate");
  
  trackPadViz.enable();
}

void onPrimaryPointDestroy(int nID) {
  // println("onPrimaryPointDestroy");
  
  trackPadViz.disable();
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// save and read data from file
void readFile(String fileName) {
  String[] lines = loadStrings(fileName);
  
  if (lines.length != 4) {
    println("Must have exactly 4 points");  
  }
  else {
    for (int i = 0; i < lines.length; i++) {
      xPoints[i] = int(split(lines[i], ' ')[0]);
      yPoints[i] = int(split(lines[i], ' ')[1]);
    }

    println(xPoints);
    println(yPoints);  
  }
}

void readTokenPad(String fileName) {
  String[] lines = loadStrings(fileName);

  if (lines.length != gridY-1) {
    println("Invalid tokenPad");
  } 
  else {
    for (int i = 0; i < lines.length; i++) {
      String[] points = split(lines[i], ' ');

      if (points.length != gridX) {
        println("Invalid tokenPad");
        return;
      }

      for (int j = 0; j < points.length; j++) {
        int x = int(split(points[j], ',')[0]);
        int y = int(split(points[j], ',')[1]);

        tokenPad[j][i] = new Point(x, y);
      }
    }
  } 
}

Point randomPoint() {
  Random r = new Random();
  
  int x = r.nextInt(100) % gridX;
  int y = r.nextInt(100) % (gridY-1);

  return new Point(x, y);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Trackpad

class Trackpad {
  int     xRes;
  int     yRes;
  int     width;
  int     height;
  
  boolean active;
  PVector center;
  PVector offset;
  
  int      space;
  
  int      focusX;
  int      focusY;
  int      selX;
  int      selY;
  int      dir;
  
  int      unlockCount = 0;
  
  Trackpad(PVector center,int xRes,int yRes,int width,int height,int space) {
    this.xRes     = xRes;
    this.yRes     = yRes;
    this.width    = width;
    this.height   = height;
    active        = false;
    
    this.center = center.get();
    offset = new PVector();
    offset.set(-(float)(xRes * width + (xRes -1) * space) * .5f,
               -(float)(yRes * height + (yRes -1) * space) * .5f,
               0.0f);
    offset.add(this.center);
    
    this.space = space;
  }
  
  void enable() {
    active = true;
    
    focusX = -1;
    focusY = -1;
    selX = -1;
    selY = -1;

    unlockCount = 0;
    yRes = gridY - 1;
  }
  
  void update(int indexX,int indexY) {
    focusX = indexX;
    focusY = (yRes-1) - indexY;
  }
  
  void push(int indexX, int indexY, int dir) {
    selX = indexX;
    selY =  (yRes-1) - indexY;
    this.dir = dir;
    
    if (unlockCount >= 0 && unlockCount < 3) {
      println("unlock count: " + unlockCount);
      println("1: " + selX + " " + selY);
      println("2: " + xPoints[unlockCount] + " " + yPoints[unlockCount]);  
    }

    // push restart button
    if (selY == 5) {
      enable();
    }
    else {
      Point point = tokenPad[highlight.x][highlight.y];

      if (unlockCount >= 2) {
        println("System unlocked");  
      }
      else if (unlockCount != -1 && (selX == point.x && selY == point.y)) { 
        unlockCount++;

        highlight = randomPoint();
      }
      else {
        unlockCount = -1;
        yRes = gridY;
        println("Failed to unlock");
      }
    }    
  }
  
  void disable() {
    active = false;
  }

  void drawRestart() {
    if(active && selY == 5) {
      // selected object 
      fill(100,100,220,190);
      strokeWeight(3);
      stroke(100,200,100,220);

      rect(2 * (width + space), 5 * (width + space), width * 3 + 2 * space, height);
    }
    else if(active && focusY == 5) { 
      // focus object 
      fill(100,255,100,220);
      strokeWeight(3);
      stroke(100,200,100,220);

      rect(2 * (width + space), 5 * (width + space), width * 3 + 2 * space, height);
    }
    else {
      PFont f = createFont("Arial", 16, true);
      textFont(f, 24);             
      fill(255);
      text("RESTART", 2 * width + 4 * space, 5 * width + 7 * space);

      // normal
      strokeWeight(3);
      stroke(100,200,100,190);
      noFill();
      rect(2 * (width + space), 5 * (width + space), width * 3 + 2 * space, height);  
    }
  }
  
  void draw() {    
    pushStyle();
    pushMatrix();
    
    translate(offset.x,offset.y);

    for(int y=0; y < yRes; y++) {
      for(int x=0; x < xRes; x++) {
        if (unlockCount >= 2) {
          drawRestart();

          // success
          fill(100,255,100,220);
          strokeWeight(3);
          stroke(100,200,100,220);
        }
        else if (unlockCount <= -1) {
          drawRestart();

          // fail
          fill(255, 100, 100, 220);
          strokeWeight(3);
          stroke(100, 200, 100, 220);
        }
        else {
          if(active && (selX == x) && (selY == y)) {
            // selected object 
            fill(100,100,220,190);
            strokeWeight(3);
            stroke(100,200,100,220);
          }
          else if(active && ((highlight.x == x && highlight.y == y) || (focusX == x && focusY == y))) { 
            // focus object 
            fill(100,255,100,220);
            strokeWeight(3);
            stroke(100,200,100,220);
          }
          else if(active) {  
            // normal
            if (y < gridY-1) {
              PFont f = createFont("Arial", 16, true);
              textFont(f, 24);             
              fill(255);
              text(y * 7 + x, x * (width + space) + space, y * (width + space) + 2 * space);
            }

            strokeWeight(3);
            stroke(100,200,100,190);
            noFill();
          }
          else {
            strokeWeight(2);
            stroke(200,100,100,60);
            noFill();
          }  
        }
        
        if (y < 5) {
          rect(x * (width + space), y * (width + space), width, height);  
        }
      }
    }

    popMatrix();
    popStyle();  
  }
}

class Point {
  int x;
  int y;

  Point(int x, int y) {
    this.x = x;
    this.y = y;
  }
}
