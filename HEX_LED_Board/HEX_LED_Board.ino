#include <FastLED.h>
FASTLED_USING_NAMESPACE
#define NUM_LEDS 88
#define DATA_PIN 3             
CRGB leds[NUM_LEDS];
const byte maxChars = 150;
char receivedChars[maxChars];
String h;
String s;
String v;
String r;
String b;
String g;

bool fadingColors = false;
bool changeColor = true;
double fadeCounter = 255;

bool movingRainbow = false;

boolean newData = false;
String PlayAnimation = "";
char *strings[4];
byte index = 0;

char *ptr = NULL;

void setup() {
  Serial.begin(9600);
  Serial.println("Working!!");
  LEDS.addLeds<WS2812B, DATA_PIN, GRB>(leds, NUM_LEDS);
  FastLED.setBrightness(255);
}

void loop() {
  recvWithEndMarker();
  if(fadingColors){
    fadeColors(6);
  }
  if(movingRainbow){
    MoveRainbow();
  }
  showNewData();
}
void recvWithEndMarker() {
  static byte letter = 0;
  char endMarker = '\n';
  char rc;
  if (Serial.available() > 0) {
    rc = Serial.read();
    if (rc != endMarker) {
      receivedChars[letter] = rc;
      letter++;
      if (letter >= maxChars) {
        letter = maxChars - 1;
      }
    } else {
      receivedChars[letter] = '\0'; // terminate the string
      for ( int i = 0; i < sizeof(receivedChars);  ++i ) {
        Serial.print(String(receivedChars[i]));
      }
      Serial.println("");
      letter = 0;
      fadingColors = false;
      movingRainbow = false;
      if (String(receivedChars[0]) == "z") {
        for(int i = 0; i < NUM_LEDS; i++){
          leds[i].setRGB(0,0,0);
        }
        FastLED.show();
        
        Serial.println("Cleared!");
        memset(receivedChars, 0, sizeof(receivedChars));
        memset(strings, 0, sizeof(strings));
        index = 0;
      }
      if (String(receivedChars[0]) == "P") { //if first two letters equal f(fade color)
        repeatSteps();
        int ledNum = atoi(strings[0]);
        float hue = strtod(strings[1],NULL);
        float sat = atof(strings[2]);
        float vib = strtod(strings[3],NULL);

        hue = hue*255;
        sat = sat*255;
        vib = vib*255;
        
        leds[ledNum].setHSV(hue,sat, vib);     
        FastLED.show();
        showNewData();
        Serial.println("Done!");
        memset(receivedChars, 0, sizeof(receivedChars));
        memset(strings, 0, sizeof(strings));
        index = 0;
      } else if(String(receivedChars[0]) == "A"){ // A stands for Animation
        if(String(receivedChars[2]) == "0"){ // Finds row clicked on tableView and does the animation (Fade Random Colors)
          fadeCounter = 255;
          changeColor = true;
          Serial.println("Fading");
          fadingColors = true;
        }
        if(String(receivedChars[2]) == "1"){ // Moving Rainbow
          movingRainbow = true;
        }
      }else if(String(receivedChars[0]) == "F"){ //Using fill bucket and fills whole screen
      repeatSteps();
        int ledNum = atoi(strings[0]);
        float hue = strtod(strings[1],NULL);
        float sat = atof(strings[2]);
        float vib = strtod(strings[3],NULL);
        hue = hue*255;
        sat = sat*255;
        vib = vib*255;
        for(int i = 0; i < NUM_LEDS; i++){
        leds[i].setHSV(hue,sat, vib);
        }     
        FastLED.show();
        showNewData();
        memset(receivedChars, 0, sizeof(receivedChars));
        memset(strings, 0, sizeof(strings));
        index = 0;
    }
  }
}
}
bool countDown = false;
void fadeColors(double secs) {
  if(changeColor){
  r = random(255);
  g = random(255);
  b = random(255);
  changeColor = false;
  }
  for (int i = 0; i < NUM_LEDS; i++) {
    leds[i].setRGB( r.toInt(),g.toInt(), b.toInt());
  }
  FastLED.setBrightness(fadeCounter);
  FastLED.show();
  if(countDown == false){
    fadeCounter -= (1 / (secs));
    if (fadeCounter < 1) {
        changeColor = true;
        countDown = true;
      }
  }else {
      fadeCounter += (1 / (secs));
      if (fadeCounter > 254) {
        countDown = false;
      }
    }
}
void MoveRainbow() {
  uint8_t beatA = beatsin8(17, 0, 255);                        // Starting hue
  uint8_t beatB = beatsin8(13, 0, 255);
  fill_rainbow(leds, NUM_LEDS, (beatA + beatB) / 2, 8);
  FastLED.show();
}

void showNewData() {
  if (newData == true) {
    for ( int i = 0; i < sizeof(receivedChars);  ++i ) {
      receivedChars[i] = (char)0;
    }
    newData = false;
  }
}
void repeatSteps() {
  ptr = NULL;
  ptr = strtok(receivedChars, ",;");  // takes a list of delimiters
  fadingColors = false;
  while (ptr != NULL)
  {
    if (index > 0) {
      strings[index - 1] = ptr;
    }
    index++;
    ptr = strtok(NULL, ",;");  // takes a list of delimiters
  }
}
