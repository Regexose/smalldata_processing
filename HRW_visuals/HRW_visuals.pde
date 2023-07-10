import java.util.Timer; 
import java.util.TimerTask;
import java.util.Map;
import java.util.List;
import java.util.Iterator; 
import geomerative.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress loc;

final Timer timer = new Timer();
ArrayList<DisplayTD> utts = new ArrayList<DisplayTD>(); // list with all the Text Objects
SurfaceBase vignetteSurf;
Article articleSurf;
Rauschen rauschSurf;
Info infoSurf, areaSurf;
Sculpture sculptureSurf;
VisibilityMachine visibilityMachine; // class to make Surfaces visible
ArrayList<SurfaceBase> surfs;
DisplayTD incomingUtt;
DisplayTD currentUtt;
Areas areas;
TextCalculations tc;
String[] fontlist;
String[] cats = {"praise", "dissent", "insinuation", "concession", "lecture"};
StringList matchedUtts;
PFont messageFont, infoFont, areaFont;
JSONObject TD; // TrainingData is stored here
JSONObject oscTextIn, category_counter, ip_config; 
String incomingText, incomingCat, moderation, currentPart; // a mock for incoming OSC text
color currentCol;
boolean messageIn = false; // background reset
boolean updateUtts = false;
boolean activeTimer, vector;
StringDict shapeMapping = new StringDict(); // mapping to attribute categories to SVG filenames
int maxUtts = 1;
int cat_limit, cat_counts, noiseStart, noiseLimit, noiseInc;
float prgIncrement;
int uttCount = 0; 
Table article;
PImage vignette;

void setup() {
  //fullScreen();
  size(1000, 560);
  noCursor();
  ip_config = loadJSONObject("../ip_config.json");
  TD = loadJSONObject("TrainingDataPelle01.json");
  String ip = ip_config.getString("audience");
  article = loadTable("Moderation.tsv", "header");
  fontlist = PFont.list();
  messageFont = createFont(fontlist[39], width/30, true);
  infoFont = createFont(fontlist[39], width/50, true);
  areaFont = createFont("Courier New Bold Italic.ttf", height/20, true);
  buildSurfaces();
  visibilityMachine = new VisibilityMachine();
  oscP5 = new OscP5(this, 5040); //Audience Port
  loc = new NetAddress(ip, 5040); // send to self
  RG.init(this);
  RG.ignoreStyles(true);
  RG.setPolygonizer(RG.ADAPTATIVE);
  vector = true;
  areas = new Areas(cats);
  buildUtts(480);
  prgIncrement = 1.2;
  noiseInc = 5; // put in DisplayTD
  noiseStart = 0;// put in DisplayTD
  noiseLimit = noiseInc;// put in DisplayTD
  moderation = "moderation";
  incomingCat = "praise";
  vignette = loadImage("M1_vignette2.png");
  matchedUtts = new StringList();
}

void draw() {
  if (frameCount%30 == 0) {
    // pickIncoming(); //automatische messages werden ausgesucht
    for (SculptElement e : sculptureSurf.elements) {
      e.changeAlpha();
    }
  } 

  if (messageIn) {
    rauschSurf.clearBackground();
    messageIn = !messageIn;
    //sculptureSurf.visible = true;
  }

  for (int x=noiseStart; x<noiseLimit; x++) {
    DisplayTD utt = utts.get(x);
    utt.update();
  }

  visibilityMachine.update();

  sculptureSurf.updateSculpture();
  for (int i=0; i<surfs.size(); i++) {
    SurfaceBase surf = surfs.get(i);
    if (surf.visible) {
      surf.display();
    }
  }

  if (noiseLimit <= utts.size() - noiseInc) {
    noiseStart = noiseLimit;
    noiseLimit += noiseInc;
  } else if (noiseLimit > utts.size() - noiseInc ) {
    noiseStart = 0;
    noiseLimit = noiseInc;
  }
    image(vignette, 0, 0, width, height);
}

void buildUtts(int amount) {
  shapeMapping.set("praise", "knacks01.svg");
  shapeMapping.set("dissent", "knacks02.svg");
  shapeMapping.set("insinuation", "knacks03.svg");
  shapeMapping.set("concession", "knacks04.svg");
  shapeMapping.set("lecture", "knacks05.svg");
  for (int i=0; i<amount; i++) {
    // int index = int(random(TD.size()));
    JSONObject row = TD.getJSONObject(str(i));
    String utterance = row.getString("utterance");
    String category = cats[i%5];
    String user = row.getString("user");
    PShape shape = loadShape(shapeMapping.get(category));
    shape.setFill(findColor(category));
    DisplayTD utt = new DisplayTD(i, utterance, category, user, shape, 5, false);
    utts.add(utt);
  }
}

void visibility(char k) {

  switch(k) {

  case '1':
    rauschSurf.visible = !rauschSurf.visible;
    break;
  case '2':
    mockIncome("concession");
  case '3':
    infoSurf.visible = !infoSurf.visible;
    break;
  case '4':
    for (Area a : areas.areas) {
      areaSurf.displayName(a);
    } 
    break;
  case '5':
    sculptureSurf.visible = !sculptureSurf.visible;
    break;
  case 'm':
    moderation = "moderation";
    break;
  case 'a':
    moderation = "article";
    break;

  case 'q':
    vector = !vector;
    rauschSurf.surf.beginDraw();
    rauschSurf.surf.background(222);
    rauschSurf.surf.endDraw();
    break;

  case 'r' :
    for (SurfaceBase s : surfs) {
      s.clearBackground();
    }
  }
}

void keyReleased() {
  visibility(key);
}
