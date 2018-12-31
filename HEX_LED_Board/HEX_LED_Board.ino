#include <FastLED.h>
FASTLED_USING_NAMESPACE
#define NUM_LEDS 88
#define DATA_PIN 3             //6 on orange box
CRGB leds[NUM_LEDS];
const byte maxChars = 150;
char receivedChars[maxChars];
String h;
String s;
String v;
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
        Serial.print("NUM of LED: ");
        int ledNum = atoi(strings[0]);
        Serial.println(ledNum);
        float hue = strtod(strings[1],NULL);
        float sat = atof(strings[2]);
        float vib = strtod(strings[3],NULL);

        hue = hue*255;
        sat = sat*255;
        vib = vib*255;

        Serial.println("RANDOM STRINGS 123::");
        Serial.println(strings[1]);
        Serial.println(strings[2]);
        Serial.println(strings[3]);
        Serial.print("HUE: ");
        Serial.println(hue); 
        Serial.print("Sat: ");
        Serial.println(sat); 
        Serial.print("BRI: ");
        Serial.println(vib);
        
        leds[ledNum].setHSV(hue,sat, vib);     
//        FastLED.setBrightness(255);
        FastLED.show();
//        setPixel(strings[1],strings[2],strings[3], strings[0]);
        showNewData();
        Serial.println("Done!");
        memset(receivedChars, 0, sizeof(receivedChars));
        memset(strings, 0, sizeof(strings));
        index = 0;
      }
    }
  }
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
  while (ptr != NULL)
  {
    if (index > 0) {
      strings[index - 1] = ptr;
    }
    index++;
    ptr = strtok(NULL, ",;");  // takes a list of delimiters
  }
}
