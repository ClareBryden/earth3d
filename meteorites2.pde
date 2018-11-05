import java.util.Comparator;
import peasy.*;
import processing.sound.*;

float skyRadius = 3000;
PShape sky;
PImage skyTexture;

float earthRadius = 30;
PShape earth;
PImage earthTexture;

float moonRadius = 15;
PShape moon;
PImage moonTexture;

ArrayList<meteorRecord> meteorRecords;
int numMeteors;

PeasyCam camera;
PFont titleFont;
PFont captionFont;
SoundFile boomFile;

void setup() {
  size(900, 900, P3D);
  camera = new PeasyCam(this, 100);
  camera.setMinimumDistance(30);
  camera.setMaximumDistance(300);

  float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
  perspective(PI/3.0, width/height, cameraZ/3000.0, cameraZ*10.0);

  stroke(0);
  strokeWeight(0);
  titleFont = loadFont("NotoSans-Bold-30.vlw");
  captionFont = loadFont("NotoSans-20.vlw");
  boomFile = new SoundFile(this, "boom.mp3");

  sky = createShape(SPHERE, skyRadius);
  skyTexture = loadImage("starmap_8k.jpg");
  sky.setTexture(skyTexture);  

  earth = createShape(SPHERE, earthRadius);
  earthTexture = loadImage("albedo.jpg");
  earth.setTexture(earthTexture);  

  moon = createShape(SPHERE, moonRadius);
  moonTexture = loadImage("8k_moon.jpg");
  moon.setTexture(moonTexture);  

  /*
  meteorRecords = GetMeteorRecords();
   numMeteors = meteorRecords.size();
   println("numMeteors ", numMeteors);
   */

  meteorRecords = GetMeteorRecordsCSV();
  numMeteors = meteorRecords.size();
  println("numMeteors ", numMeteors);
} // end setup


void draw() {

  background(0);

  // Earth and axis
  fill(255, 0, 0);
  box(0.2, (earthRadius+5)*2, 0.2);
  shape(earth);

  // Sky
  shape(sky);

  // Moon
  pushMatrix();
  translate(200, 200);
  shape(moon);
  popMatrix();

  camera.beginHUD();
  fill(255);
  textFont(titleFont, 30);
  text("Meteorite Landings", 40, 60);
  textFont(captionFont, 20);
  text("Source: https://data.nasa.gov/Space-Science/Meteorite-Landings/gh4g-9sfh", 40, height-40);
  camera.endHUD();

  // Test co-ordinate coding!
  // PVector c = convertLatLongToXYZ(40.7128, -74.0060); // New York
  // PVector c = convertLatLongToXYZ(50.7184, -3.5339); // Exeter
  // PVector c = convertLatLongToXYZ(0, 0); // GMT@Equator
  // PVector c = convertLatLongToXYZ(0, 90); // ~Java
  // PVector c = convertLatLongToXYZ(90, 0); // N Pole
  // PVector c = convertLatLongToXYZ(-90, 0); // S Pole
  // translate(-c.x, -c.z, c.y);
  // sphere(1);

  int interval = 6;         // number of frames between meteors
  int incomingFrames = 30;   // number of frames meteor travelling through atmosphere
  int boomFrames = 60;       // number of frames of explosion
  int numShown = int( (incomingFrames+boomFrames)/interval );
  int lastShown;

  // end with which meteor?
  lastShown = int( (frameCount-1)/interval ) % numMeteors;
  numShown = min(lastShown+1, numShown);

  for (int i = 0; i < numShown; i++) {

    // which meteor? get the record
    int meteorNum = i + (lastShown-numShown+1);
    meteorRecord meteor = meteorRecords.get(meteorNum);
    // println(meteorNum, meteor.year, meteor.name, meteor.latitude, meteor.longitude, meteor.mass);

    // how far has it got?
    int meteorFrame = (frameCount - meteorNum*interval) % numMeteors;

    // default meteor characteristics
    float meteorRadius = 0.3;     // size, depends on mass given in data
    int red = 255;                // meteor/explosion colours
    int green = 255;
    int blue = 255;
    int opacity = 255;
    float scaling = 1;            // distance of meteor from Earth's centre / Earth's radius 

    // set up the meteor characteristics
    if ( meteorFrame < incomingFrames ) {   // meteor is still incoming
      // blue -= int( 255*meteorFrame/incomingFrames );
      scaling *= (earthRadius + (incomingFrames-meteorFrame))/earthRadius;
    } else {                                // meteor has hit... BOOM!!
      meteorRadius = meteor.mass * (meteorFrame-incomingFrames)/boomFrames;
      green -= int( 255*(meteorFrame-incomingFrames)/boomFrames );
      blue = 0;
      opacity -= int( 255*(meteorFrame-incomingFrames)/boomFrames );
    }

    // Check algorithms!
    /* if (meteorNum > 144 && meteorNum < 161) {
     println("frameCount: ", frameCount,
     "   lastShown: ", lastShown,
     "   numShown: ", numShown,
     "   i: ", i,
     "   meteorNum: ", meteorNum,
     "   meteorFrame: ", meteorFrame,
     "   scaling: ", scaling,
     "   meteorRadius: ", meteorRadius,
     "   RGBA: ", red, green, blue, opacity);
     } */

    // plot the meteor
    pushMatrix();
    translate(-meteor.xyz.x*scaling, -meteor.xyz.z*scaling, meteor.xyz.y*scaling);
    fill(red, green, blue, opacity);
    sphere(meteorRadius);
    popMatrix();

    // make a noise when meteor hits
    if ( interval >=30 && meteorFrame == incomingFrames ) {
      boomFile.play();
    }

    // and display a caption
    if ( meteorFrame >= incomingFrames && meteorFrame < incomingFrames+interval ) {
      camera.beginHUD();
      fill(255, opacity);
      text(meteor.name, 40, 90);
      text(meteor.year, 40, 120);
      camera.endHUD();
    }
  } // end loop over meteors

  // save each frame to make a movie and rotate automatically
  // saveFrame("movie/boom-######.jpg");
  // camera.rotateY(-0.01);
  // camera.rotateX(0.005);
  // camera.rotateZ(0);
} // end Draw


PVector convertLatLongToXYZ(float latitude, float longitude) {

  latitude = radians(latitude);
  longitude = radians(longitude);

  PVector coords = new PVector(0, 0, 0);
  coords.x = earthRadius * cos(latitude) * cos(longitude);
  coords.y = earthRadius * cos(latitude) * sin(longitude);
  coords.z = earthRadius * sin(latitude);

  return coords;
} // end convertLatLongToXYZ


ArrayList<meteorRecord> GetMeteorRecordsCSV() {
  ArrayList<meteorRecord> strikeArrayList = new ArrayList<meteorRecord>();

  Table csvRecords = loadTable("Meteorite_Landings.csv", "header");

  /* csv header row and sample line
   0  name         Aachen
   1  id           1
   2  nametype     Valid
   3  recclass     L5
   4  mass (g)     21
   5  fall         Fell
   6  year         01/01/1880 12:00:00 AM
   7  reclat       50.775000
   8  reclong      6.083330
   9  GeoLocation  "(50.775000,6.083330)"
   */

  // sort the meteors by year or mass; default is name A-Z
  // csvRecords.sort("name");
  // csvRecords.sort("mass (g)");
  // csvRecords.sort("year");

  int numRecords = csvRecords.getRowCount();
  float strikeImpact = 0.5;
  int strikeYear = -9999;

  for (TableRow row : csvRecords.rows()) {

    String strikeName = row.getString("name");
    String strikeId = row.getString("id");
    String strikeMass = row.getString("mass (g)");
    String strikeDate = row.getString("year");
    String strikeGeoLoc = row.getString("GeoLocation");
    // println(strikeName, strikeId, strikeMass, strikeDate, strikeGeoLoc);

    if (strikeGeoLoc.length() != 0) {
      if (strikeMass.length() != 0) {
        // strikeImpact = float(strikeMass)/10000.0;
        strikeImpact = constrain(log(float(strikeMass))/2, 0.5, 10);
      }
      if (strikeDate.length() != 0) {
        strikeYear = Integer.parseInt(split(split(strikeDate, " ")[0], "/")[2]);
      }
      float strikeLat = row.getFloat("reclat");
      float strikeLong = row.getFloat("reclong");
      strikeArrayList.add(new meteorRecord(
        strikeYear, 
        strikeName, 
        strikeLat, 
        strikeLong, 
        convertLatLongToXYZ(strikeLat, strikeLong), 
        strikeImpact)
        );
    } else {
      println(strikeId, "     ", strikeYear, "     ", strikeName);
    }
  } // end loop over csv

  println("numRecords ", numRecords); 

  // sort the meteors by year or mass; default is name A-Z
  strikeArrayList.sort(new YearComparatorAsc());
  // strikeArrayList.sort(new YearComparatorDesc());
  // strikeArrayList.sort(new MassComparatorAsc());
  // strikeArrayList.sort(new MassComparatorDesc());

  return strikeArrayList;
} // end GetMeteorRecordsCSV

/*
ArrayList<meteorRecord> GetMeteorRecords() {
 ArrayList<meteorRecord> strikeArrayList = new ArrayList<meteorRecord>();
 
 // JSONArray jsonBlob = loadJSONArray("https://data.nasa.gov/resource/gh4g-9sfh.json");
 JSONArray jsonBlob = loadJSONArray("gh4g-9sfh.json");
 
/* sample json record
 "fall" : "Fell",
 "year" : "1880-01-01T00:00:00",
 "nametype" : "Valid",
 "mass" : "21",
 "name" : "Aachen",
 "recclass" : "L5",
 "reclat" : "50.775000",
 "reclong" : "6.083330",
 "id" : "1",
 "geolocation" : {
 "latitude" : "50.775",
 "needs_recoding" : false,
 "longitude" : "6.08333"
 }
 
 
 int numRecords = jsonBlob.size();
 float strikeImpact = 0.5;
 
 for (int i = 0; i < numRecords; i++) {
 JSONObject strike = jsonBlob.getJSONObject(i);
 JSONObject strikeGeoLoc = strike.getJSONObject("geolocation");
 String meteorMass = strike.getString("mass");
 
 if (strikeGeoLoc != null) {
 if (meteorMass != null) {
 // strikeImpact = float(meteorMass)/10000.0;
 strikeImpact = constrain(log(float(meteorMass))/2, 0.5, 10);
 }
 float strikeLat = strikeGeoLoc.getFloat("latitude");
 float strikeLong = strikeGeoLoc.getFloat("longitude");
 strikeArrayList.add(new meteorRecord(
 strike.getString("year"), 
 strike.getString("name"), 
 strikeLat, 
 strikeLong, 
 convertLatLongToXYZ(strikeLat, strikeLong), 
 strikeImpact)
 );
 } else {
 println(i, "     ", 
 strike.getString("year"), "     ", 
 strike.getString("name"));
 }
 } // end loop over json
 
 println("numRecords ", numRecords); 
 
 // sort the meteors by year or mass; default is name A-Z
 strikeArrayList.sort(new YearComparatorAsc());
 // strikeArrayList.sort(new YearComparatorDesc());
 // strikeArrayList.sort(new MassComparatorAsc());
 // strikeArrayList.sort(new MassComparatorDesc());
 
 return strikeArrayList;
 } // end GetMeteorRecords
 */


class meteorRecord {
  // public Date timestamp;
  public int year;
  public String name;
  public float latitude;
  public float longitude;
  public PVector xyz;
  public float mass;

  // public meteorRecord(String _timestamp, String _name, 
  public meteorRecord(int _timestamp, String _name, 
    float _latitude, float _longitude, PVector _xyz, float _mass) {

    // year = Integer.parseInt(split(_timestamp,"-")[0]);
    year = _timestamp;
    name = _name;
    latitude = _latitude; 
    longitude = _longitude;
    xyz = _xyz;
    mass = _mass;
  }
}


public class YearComparatorAsc implements Comparator<meteorRecord> {
  @Override
    public int compare(meteorRecord a, meteorRecord b) {
    return a.year < b.year ? -1 : a.year == b.year ? 0 : 1;
  }
}

public class YearComparatorDesc implements Comparator<meteorRecord> {
  @Override
    public int compare(meteorRecord a, meteorRecord b) {
    return a.year > b.year ? -1 : a.year == b.year ? 0 : 1;
  }
}

public class MassComparatorAsc implements Comparator<meteorRecord> {
  @Override
    public int compare(meteorRecord a, meteorRecord b) {
    return a.mass < b.mass ? -1 : a.mass == b.mass ? 0 : 1;
  }
}

public class MassComparatorDesc implements Comparator<meteorRecord> {
  @Override
    public int compare(meteorRecord a, meteorRecord b) {
    return a.mass > b.mass ? -1 : a.mass == b.mass ? 0 : 1;
  }
}
