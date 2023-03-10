
import processing.serial.*;
import java.nio.charset.StandardCharsets;

Serial myPort;  // The serial port
int activeSerialPort = -1;

//Times
PFont TimesNewRomanItalic;
PFont TimesNewRoman;
PFont NotoSerif;
PFont Mono;
PFont EuphemiaBold;
PFont Euphemia;
PFont ComicSans;
PFont ComicSansBold;



//0 is default, 1 is receiving data
int menuState = 0;
//to stop the folder picker from continuously opening, BUT i'm not sure why it does that
boolean gettingFolder = false;

//path to save folders to
String outputPath;

ArrayList<String> consoleOutput = new ArrayList<String>();

//silly little button class
class Button{
  int x,y,w,h;
  String text;
  color c;
  color highlight;
  boolean mousedOver;
  boolean pressed;
  boolean state;
  boolean toggle;
  //singular buttons clear all other buttons when pressed
  boolean singular;
  int frameOfLastPress;
  //0 for round rect, 1 for normal rect, 2 for circle, 3 for box
  int style;
  int textSize;
  
  //locks a button so it's always off
  boolean locked = false;
  
  
  //constructors
  Button(){
    x = 0;
    y = 0;
    w = 100;
    h = 75;
    mousedOver = false;
    pressed = false;
    toggle = false;
    frameOfLastPress = frameCount;
  }
  
  Button(int x1, int y1, int w1, int h1, String text1, int size, color c1, color c2){
    x = x1;
    y = y1;
    w = w1;
    h = h1;
    c = c1;
    highlight = c2;
    text = text1;
    textSize = size;
    mousedOver = false;
    pressed = false;
    toggle = false;
    frameOfLastPress = frameCount;
  }
  
  boolean isMousedOver(){
    if (mouseX >= x && mouseX <= x+w && mouseY >= y && mouseY <= y+h)
      return true;
    else
      return false;
  }
  
  //update function
  boolean update(){
    mousedOver = isMousedOver();

    //only update state every 60 frames
    if((frameCount-frameOfLastPress)>60){
      if(mousedOver && mouseButton == LEFT){
        pressed = true;
        frameOfLastPress = frameCount;
      }
      else
        pressed = false;
        
      //toggle buttons
      if(toggle){
        if(pressed){
           state = !state;
        }
      }
      //normal buttons
      else{
        state = pressed;
      }
    }
    if(singular && state){
      boolean temp = state;
      clearButtons();
      state = temp;
    }
    //once the mouse comes off the button, it's unlocked
    if(!mousedOver && !pressed && locked){
      locked = false;
    }
    //if it's locked, it's always off
    if(locked)
      return false;
    else
      return state;
  }
  
  //draw function
  void drawButton(){
    //if it's moused over/pressed, draw a box around it 
    if(mousedOver || state){
      stroke(highlight);
      strokeWeight(15);
      fill(highlight);
      textFont(TimesNewRomanItalic);
      rect(x,y,w,h,10);
      fill(0);
      //for main menu emojis and the file/navigation emojis
      if(style == 0) 
        textSize(textSize+20);
      else if(style == 2)
        textSize(textSize+10);
    }
     else{
       noStroke();
       fill(c);
       textFont(TimesNewRoman);
       rect(x,y,w,h,15);
       fill(0);
       textSize(textSize);
     }
    
    //dynamically sizing
    //center the text vertically and horizontally on the button
    switch(style){
      //normal times new roman buttons
      case 0:
        text(text, x+w/2-textWidth(text)/2,y+h-textAscent()+4);
        break;
      case 1:
        text(text, x+w/2-textWidth(text)/2,y+h-textAscent()+4);
        break;
      case 2:
        text(text, x+w/2-textWidth(text)/2,y+h-textAscent()+18);
        break;
    }
  }
}

void rainbowFill(int speed){
  colorMode(HSB);
  fill(color((frameCount/speed)%255,150,255));
  colorMode(RGB);
}

PImage img;
PImage[] gif = new PImage[10];

void loadGif(int which){
  switch(which){
    //cd
    case 0:
      gif[0] = loadImage("images/cd/1.png");
      gif[1] = loadImage("images/cd/2.png");
      gif[2] = loadImage("images/cd/3.png");
      gif[3] = loadImage("images/cd/4.png");
      gif[4] = loadImage("images/cd/5.png");
      gif[5] = loadImage("images/cd/6.png");
      gif[6] = loadImage("images/cd/7.png");
      gif[7] = loadImage("images/cd/8.png");
      gif[8] = loadImage("images/cd/9.png");
      gif[9] = loadImage("images/cd/10.png");
      break;    
  }
}

void drawGif(int x, int y){
  image(gif[(frameCount/6)%10],x,y);
}
//adds a tring to the console display
void addToConsole(String text){
  //if there are more than 8 lines stored, remove the first one
  while(consoleOutput.size() >= 8){
    consoleOutput.remove(0);
  }
  consoleOutput.add(text);
}

Button[] buttonList = new Button[5];

//this is called in setup
void makeButtons(){
  switch(menuState){
    //default menu
    case 0:
      Button[] temp = new Button[5];
      buttonList = temp;
      //download
      buttonList[0] = new Button(50,185,70,30,"????",15, color(255,220,150),color(255));
      //upload
      buttonList[2] = new Button(50,245,70,30,"????", 15, color(200,200,255),color(255));
      //update
      buttonList[3] = new Button(50,305,70,30,"????", 15, color(200,255,200),color(255));
      //buttonList[4] = new Button(50,365,70,30,"????", 15, color(200,255,255),color(255));
      //convert file
      buttonList[4] = new Button(50,365,70,30,"????", 15, color(200,255,255),color(255));
      //quit
      buttonList[1] = new Button(50,425,70,30,"????", 15, color(255,200,200),color(255));
      break;
    //download menu
    case 1:
      clearButtons();
      //make a new button list containing a toggle button for each serial port
      //and three extra buttons
      buttonList = new Button[Serial.list().length+3];
      for(int i = 0; i<Serial.list().length; i++){
        //make the button the length of the string
        buttonList[i] = new Button(45,120+i*(180/Serial.list().length),250,20,Serial.list()[i], 12, color(150,220,255),color(255,150,200));
        buttonList[i].toggle = true;
        buttonList[i].singular = true;
        buttonList[i].style = 1;
        if(i == activeSerialPort)
          buttonList[i].state = true;
      }
      //back button
      buttonList[buttonList.length-1] = new Button(32,450,40,20,"????", 30, color(255,150,150),color(0,50,50));
      buttonList[buttonList.length-1].style = 2;
      //select folder button
      buttonList[buttonList.length-2] = new Button(425,435,40,40,"????", 30, color(255,200,200),color(0,50,50));
      buttonList[buttonList.length-2].style = 2;
      //refresh ports button
      buttonList[buttonList.length-3] = new Button(350,435,40,40,"????",30,color(190,220,220),color(0,50,50));
      buttonList[buttonList.length-3].style = 2;

  }
}

void refreshSerial(){
  consoleOutput.clear();
  activeSerialPort = -1;
  chooseSerial();
  makeButtons();
  addToConsole("Refreshing...");
  addToConsole("Found "+Serial.list().length+" ports!");
  //print("found "+Serial.list().length+" ports");
  for(int i = 0; i<Serial.list().length; i++){
    addToConsole(Serial.list()[i]);
  }
}

void checkButtons(){
  //update buttons
  for(int i = 0; i<buttonList.length; i++){
    buttonList[i].update();
  }
  //only run button functions every x milliseconds
  switch(menuState){
    //main menu
    case 0:
      //download button
      if(buttonList[0].state){
        menuState = 1;
        clearButtons();
        makeButtons();
      }
      else if(buttonList[1].state)
        exit();
      else if(buttonList[2].state)
        menuState = 2;
      break;
    //download menu
    case 1:
      //choosing serial ports
      for(int i = 0; i<buttonList.length-3; i++){
        if(buttonList[i].state){
          //if this serial port isn't chosen, choose it
          if(activeSerialPort != i){
            activeSerialPort = i;
            chooseSerial();
          }
        }
        //if the button is off, and was corresponding to the old serial port
        else if(buttonList[i].state == false && i == activeSerialPort){
          activeSerialPort = -1;
          chooseSerial();
        }
      }
      //back button
      if(buttonList[buttonList.length-1].state){
        menuState = 0;
        clearButtons();
        makeButtons();
      }
      //choose output file button if it's pressed and not locked
      if(buttonList[buttonList.length-2].state == true && !buttonList[buttonList.length-2].locked){
        buttonList[buttonList.length-2].locked = true;

        selectFolder("Select a folder:","setOutputFolder");
      }
      //refresh button
      if(buttonList[buttonList.length-3].state){
        refreshSerial();
      }
  }
}

void setOutputFolder(File selection){
  if(selection == null){
    addToConsole("Error getting folder :(");
    addToConsole("Try again pls");
    outputPath = null;
  }
  else{
    outputPath = selection.getAbsolutePath();
    addToConsole("Outputting files to "+outputPath);
  }
}

void drawButtons(){
  for(int i = 0; i<buttonList.length; i++){
    buttonList[i].drawButton();
  }
}

void clearButtons(){
  for(int i = 0; i<buttonList.length; i++){
    buttonList[i].pressed = false;
    buttonList[i].state = false;
  }
}

void drawChildOS(int x, int y, boolean vs){
  
  int offset = frameCount/10;
  
  rainbowFill(5);
  textFont(TimesNewRomanItalic);
  textSize(80);
  text("OS",x+110,y-10);
  
  textFont(ComicSansBold);
  textSize(60);
  fill(255);
  text("c",x,y+3*sin(offset));
  text("h",x+33,y+3*sin(offset+5));
  text("i",x+70,y+3*sin(offset+10));
  text("l",x+90,y+3*sin(offset+15));
  text("d",x+110,y+3*sin(offset+20));
 
  
  textSize(10);
  fill(255);
  textFont(TimesNewRomanItalic);
  //if(vs)
    //text("version 0.1",x+10,y+25);
  textSize(20);
  fill(255);
}

void mousePressed(){
  checkButtons();
}
String[] mainMenuText = new String[5];



void drawInfoText(int x, int y){
  switch(menuState){
    //main menu
    case 0:
      mainMenuText[0] = "Download files from the stepchild";
      mainMenuText[1] = "Quit the program";
      mainMenuText[2] = "Upload files to the stepchild";
      mainMenuText[3] = "Flash firmware update";
      mainMenuText[4] = "Convert .stpchld files to MIDI files";
      textFont(Euphemia);
      textSize(12);
      for(int i = 0; i<buttonList.length; i++){
        if(buttonList[i].mousedOver){
          fill(255);
          text(mainMenuText[i],x,y);
        }
      }
      break;
  }
}

color getRainbow(int speed){
  colorMode(HSB);
  color c = color((frameCount/speed)%255,255,200);
  colorMode(RGB);
  return c;
}

ArrayList <String> filenames = new ArrayList<String>();

void drawConsole(int x, int y, int w, int h){
  strokeWeight(1);
  stroke(255);
  fill(0);
  rect(x,y,w,h,10);
  fill(255);
  textFont(ComicSans);
  textSize(12);
  for(int i = 0; i<consoleOutput.size(); i++){
    text(consoleOutput.get(i),x+10,y+15+i*(h-10)/8);
  }
}

//downloads a file and writes it to the sketch folder
void downloadFileData(){
  if(activeSerialPort != -1){
    textSize(20);
    textFont(TimesNewRomanItalic);
    if(myPort.available()>0){
      int inByte = myPort.read();
      //if it's a \n, then you know you're about to get the filename
      if(inByte == '\n'){
        //read in the filename
        String filename = readFilename();
        addToConsole("received "+filename);
        
        //read in the file size
        int numberOfBytesToRead = readFileSize();
        
        addToConsole("reading "+numberOfBytesToRead+" bytes");
        //if the user specified a path, append that to the front of the filname
        if(outputPath != "Invalid folder")
          filename = outputPath+"/"+filename;
        //read in the data
        saveBytes(filename,readData(numberOfBytesToRead));
        
        //draw visual confirmation
        //text("Received "+filename,10,40);
        //text("bytes: "+numberOfBytesToRead,10,140);
        addToConsole("bytes left in the buffer: "+myPort.available());
      }
      else{
        //print("found a bad/weird character:"+inByte);
        addToConsole("found a weird character :(");
        addToConsole("Clearing the buffer.");
        myPort.clear();
      }
      delay(100);
    }
  }
}

//file size is 2 bytes
int readFileSize(){
  int size = 0;
  
  //building the 32-bit value from 4 bytes
  size += myPort.read()<<24;
  size += myPort.read()<<16;
  size += myPort.read()<<8;
  size += myPort.read();
  return size;
}
  
//filename is read until you find an endline
String readFilename(){
  String filename = "";
  while(true){
    //wait for more bytes if none are available
    while(myPort.available()<1){
      delay(1);
    }
    char newByte = myPort.readChar();
    if(newByte == '\n'){
      filename = filename.substring(0,filename.length());
      return filename;
    }
    else{
      filename+=newByte;
    }
  }
}

//reads in data from Serial port
byte[] readData(int numBytes){
  //create a byte buffer to store the file
  byte[] byteBuffer = new byte[numBytes];
  //wait for enough bytes to be sent
  while(myPort.available()<numBytes){
    delay(1);
  }
  //read the correct number of bytes into the buffer
  myPort.readBytes(byteBuffer);
  return byteBuffer;
}

void chooseSerial(){
  println(activeSerialPort);
  if(activeSerialPort != -1){
    if(myPort != null){
      myPort.clear();
      myPort.stop();
    }
    myPort = new Serial(this,Serial.list()[activeSerialPort], 9600);
    myPort.clear();
  }
  else if(myPort != null){
    myPort.clear();
    myPort.stop();
    myPort = null;
  }
  if(activeSerialPort != -1){
    addToConsole("Connected to port "+activeSerialPort+".");
    addToConsole("Listening...");
  }
  else{
    addToConsole("Serial disconnected!");
  }
}

void keyPressed(){
  exit();
}

void setup() {
  // List all the available serial ports
  //printArray(Serial.list());
  chooseSerial();
  
  //graphics 
  size(500,500);
  surface.setTitle("childOS Interface");
  background(100,0,100);
  frameRate(100);
  loadGif(0);
  noSmooth();
  
  TimesNewRomanItalic = createFont("TimesNewRomanPS-ItalicMT",16,false); // TimesNewRoman, 16 point, anti-aliasing on
  TimesNewRoman = createFont("TimesNewRomanPSMT",16,false); // TimesNewRoman, 16 point, anti-aliasing on
  NotoSerif = createFont("NotoSerifMyanmar-Regular",16,false); // TimesNewRoman, 16 point, anti-aliasing on
  Mono = createFont("PTMono-Regular",16,false); // TimesNewRoman, 16 point, anti-aliasing on
  EuphemiaBold = createFont("EuphemiaUCAS-Bold",16,false); // TimesNewRoman, 16 point, anti-aliasing on
  Euphemia = createFont("EuphemiaUCAS",16,false); // TimesNewRoman, 16 point, anti-aliasing on
  ComicSans = createFont("ComicSansMS",16,false); // TimesNewRoman, 16 point, anti-aliasing on
  ComicSansBold = createFont("ComicSansMS-Bold",16,false); // TimesNewRoman, 16 point, anti-aliasing on

  //print(PFont.list());
  
  makeButtons();
  drawGif(180,140);
}

void mainMenu(){
  //background(200,150,220);
  background(0);
  drawChildOS(40,80,true);
  drawButtons();
  drawGif(180,140);
  drawInfoText(50,130);
  //buttonList[0] = new Button(50,185,70,30,"Download",color(255,220,150),color(255));
  //buttonList[2] = new Button(50,245,70,30,"Upload",color(200,200,255),color(255));
  //buttonList[3] = new Button(50,305,70,30,"Settings",color(200,255,200),color(255));
  //buttonList[4] = new Button(50,365,70,30,"update",color(200,255,255),color(255));
  //buttonList[1] = new Button(50,425,70,30,"Quit",color(255,200,200),color(255));
  
  checkButtons();
}

//hyperlink to website
void uploadMenu(){
  
}

void downloadMenu(){
  background(0);
  drawChildOS(40,80,false);
  checkButtons();
  drawGif(240,20);
  //fill(255);
  textFont(TimesNewRoman);
  //fill(0);
  //stroke(getRainbow(5));
  stroke(255,255,200);
  strokeWeight(1);
  //rect(32,135,250+25,buttonList[buttonList.length-4].y - 100, 10);
  drawConsole(32,317,300,120);
  drawButtons();
  fill(255);
  textFont(Euphemia);
  textSize(12);
  text("choose a port, child.",48,110);
  downloadFileData();
}
void draw() {
  switch(menuState){
    case 0:
      mainMenu();
      break;
    //download mode
    case 1:
      downloadMenu();
      break;
  }
}
