import gab.opencv.*;
import processing.video.*;
import java.awt.*;

Capture video;
OpenCV opencv;

//syphon library
import codeanticode.syphon.*;
SyphonServer server;

// start OSC config
import oscP5.*;
import netP5.*;
  
/*portToListenTo, port we are listening on, this should be the same as
the outgoing port of TouchOsc on your iphone
*/
int portToListenTo = 7001; 
/*portToSendTo, port we are sending to, this should be the same as
the incomning port of Resolume 3, default it is set to 7000, so you wouldn't need to change it.
*/
int portToSendTo = 7000;
/*ipAddressToSendTo, ip address of the computer we are sending messages to (where Resolume 3 runs)
*/
String ipAddressToSendTo = "localhost";

OscP5 oscP5;
NetAddress myRemoteLocation;
OscBundle myBundle;
OscMessage myMessage;
//end OSC config

//Boxes
/*
Formatted like this:
{box1 x, box1 y, box1 width, box1 height},
{box2 x, box2 y, box2 width, box2 height}...
*/
int[][] boxes = {    {10,  10,  50,  50},
                     {20,  20,  40,  40},
                     {15,  15,  80,  80},
                     {25,  25,  70,  70}
                 };

int[] activated = {0, 0, 0, 0};

void setup() {
  //P3D required for syphon to work
  size(640, 480, P3D);
  String[] cameras = Capture.list();
  video = new Capture(this, 640/2, 480/2);
  opencv = new OpenCV(this, 640/2, 480/2);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  

  video.start();
  
  oscP5 = new OscP5(this,portToListenTo);
  myRemoteLocation = new NetAddress(ipAddressToSendTo, portToSendTo);  
  myBundle = new OscBundle();
  myMessage = new OscMessage("/"); 
  
  // Create syhpon server to send frames out.
  server = new SyphonServer(this, "Processing Syphon");
}

void draw() {
  scale(2);
  opencv.loadImage(video);
  image(video, 0, 0 );

  
  updateBoxStates();
  sendBoxStates();

  server.sendImage(video);
}

void captureEvent(Capture c) {
  c.read();
}

void OscSend(int v){
  myMessage.setAddrPattern("/activeclip/video/position/direction");
  myMessage.add(v);
  myBundle.add(myMessage);
  oscP5.send(myBundle, myRemoteLocation);
  myMessage.clear(); 
  myBundle.clear();
  print("sending: ");
  println(myMessage);
  println("done sending");
}

//0 = backwards, 1 = forwards
void playDirection(int dir){
  myMessage.setAddrPattern("/activeclip/video/position/direction");
  myMessage.add(dir);
  myBundle.add(myMessage);
  oscP5.send(myBundle, myRemoteLocation);
  myMessage.clear(); 
  myBundle.clear();
  print("sending: ");
  println(myMessage);
  println("done sending");
}


void pickClip(int layer, int clip){
  println("Start pickClip");
  myMessage.setAddrPattern("/layer" + layer + "/clip" + clip + "/connect");
  myMessage.add(1);
  myBundle.add(myMessage);
  oscP5.send(myBundle, myRemoteLocation);
  myMessage.clear(); 
  myBundle.clear();
  print("sending: ");
  println(myMessage);
  println("Done pickClip");
}

void updateBoxStates(){
  activated = {0, 0, 0, 0};
  for(int i = 0; i < faces.length; i++){
    int[] nose = findNose(i);
    checkBoxes(nose);
  }
}

int[] findNose(int i){
  int[] nose = new int[2];
  nose[0] = faces[i].x + faces[i].width/2;
  nose[1] = faces[i].y + faces[i].height/2;
  return nose;
}

void checkBoxes(int[] nose){
  for(int i = 0; i < 4; i++){
    int xNose = nose[0];
    int yNose = nose[1];
    int x = boxes[i][0];
    int y = boxes[i][1];
    int w = boxes[i][2];
    int h = boxes[i][3];
    
    //If nose coords are inside the box
    //Could maybe break here since nose cannot be inside two boxes
    if(xNose > x && xNose < x+w && yNose > y && yNose < y+h){
      activated[i] = 1;
    }
  }
}

void sendBoxStates(){
  for(int i = 0; i < activated.length; i++){
    //adding 1 so the array index matches the chosen layer which start from layer 2
    pickClip(i+2, 1);
    playDirection(activated[i]);
  }
}

void drawBoxes(){
  noFill();
  stroke(0, 255, 0);
  strokeWeight(3);
  Rectangle[] faces = opencv.detect();
  println(faces.length);

  for (int i = 0; i < faces.length; i++) {
    println(faces[i].x + "," + faces[i].y);
    rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
  }
  
  if(faces.length > 0){
    int nosex = faces[0].x + faces[0].width/2;
    int nosey = faces[0].y + faces[0].height/2;
    
    fill(255, 0, 0);
    noStroke();
    rect(nosex, nosey, 4, 4);
    rect(width/4, height/4, 4, 4);
    
  }
}

