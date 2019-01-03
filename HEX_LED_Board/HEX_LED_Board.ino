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

bool countDown = false;
bool fadingColors = false;
bool changeColor = true;
double fadeCounter = 255;

bool movingRainbow = false;

bool gradualFill = false;
bool hasConnected = false;

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
  delay(750);
  for(int i = 0; i < NUM_LEDS; i++){
    leds[i].setRGB(0,0,255);
  }
  FastLED.show();
}

void loop() {
  if(hasConnected == false){
  searchForConnection();
  FastLED.show();
  if(countDown == false){
    fadeCounter -= 2;
    Serial.println(fadeCounter);
    if (fadeCounter < 50) {
        countDown = true;
      }
  }else {
      fadeCounter += 2;
      if (fadeCounter > 250) {
        countDown = false;
      }
      Serial.println("countung up");
    }
  }
  recvWithEndMarker();
  if(fadingColors){
    fadeColors(6);
  }
  if(movingRainbow){
    MoveRainbow();
  }
  if(gradualFill){
    Gradual();
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
      hasConnected = true;
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
      gradualFill = false;
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
        
        if(sat > 1){
          sat = 255;
        }else if(sat < 1 && sat > 0.7){
          sat = 190;
        }else if(sat < 0.7 && sat > 0.4){
          sat = 100;
        }else{
          sat = 0;
        }
        vib = vib*255;
        leds[ledNum].setHSV(hue,sat, vib); 
        if(hue > 165 && hue < 175){
          leds[ledNum].setRGB(0,0,255);
        }    
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
        if(String(receivedChars[2]) == "2"){ // GradualFill
          gradualFill = true;
        }
      }else if(String(receivedChars[0]) == "F"){ //Using fill bucket and fills whole screen
      repeatSteps();
        int ledNum = atoi(strings[0]);
        float hue = strtod(strings[1],NULL);
        float sat = atof(strings[2]);
        float vib = strtod(strings[3],NULL);
        hue = hue*255;
        if(sat > 1){
          sat = 255;
        }else if(sat < 1 && sat > 0.7){
          sat = 190;
        }else if(sat < 0.7 && sat > 0.4){
          sat = 100;
        }else{
          sat = 0;
        }
        vib = vib*255;
        for(int i = 0; i < NUM_LEDS; i++){
        leds[i].setHSV(hue,sat, vib);
        }
        if(hue > 165 && hue < 175){
          for(int i = 0; i < NUM_LEDS; i++){ // blue color broken so manually set blue with rgb
        leds[i].setRGB(0,0,255);
        }
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
void Gradual() {
  uint8_t starthue = beatsin8(5, 0, 255);
  uint8_t endhue = beatsin8(7, 0, 255);

  if (starthue < endhue) {
    fill_gradient(leds, NUM_LEDS, CHSV(starthue, 255, 255), CHSV(endhue, 255, 255), FORWARD_HUES); // If we don't have this, the colour fill will flip around.
  } else {
    fill_gradient(leds, NUM_LEDS, CHSV(starthue, 255, 255), CHSV(endhue, 255, 255), BACKWARD_HUES);
  }
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

void searchForConnection(){
  leds[13].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[14].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[15].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[16].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[17].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[18].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[19].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[20].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[24].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[28].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[31].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[35].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[39].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[42].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[46].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[50].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[53].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[57].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[61].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[64].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[69].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[70].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[71].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[73].setRGB(20, round(fadeCounter), round(fadeCounter));
  leds[74].setRGB(20, round(fadeCounter), round(fadeCounter));
}

