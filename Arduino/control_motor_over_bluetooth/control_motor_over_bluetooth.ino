//arduino reads commands through bluetooth and operates the motor
//command in format of "sxxx" where xxx is speed and can be negative (backwards)

#include <SoftwareSerial.h> 

//#define BT_HWS

const int MOTA_PINA = 6;  // (pwm) pin 5 connected to pin A-IA 
const int MOTA_PINB = 7;  // (pwm) pin 6 connected to pin A-IB 

const int SS_RX=3;
const int SS_TX=4;

class Motor {
  private:
    int pin1;
    int pin2;
  public:
  Motor(int pin1, int pin2) {
    this->pin1 = pin1;
    this->pin2 = pin2;
  }
  void init() {
    pinMode(pin1, OUTPUT);
    pinMode(pin2, OUTPUT);
  }
  void go(int speed) {
    byte val1 = 0;
    byte val2 = 0;
    if (0==speed) {
      // stop - both low
    } else if (0<speed) {
      // forwards
      val1 = speed;
    } else if (0>speed) {
      // backwards
      val2 = -speed;
    }
    analogWrite(pin1, val1);
    analogWrite(pin2, val2);
  }
};

#ifndef BT_HWS
SoftwareSerial ss(SS_RX,SS_TX);
#endif
Motor m(MOTA_PINA, MOTA_PINB);

void setup() {
#ifdef BT_HWS
  Serial.begin(9600);
#else
  Serial.begin(57600);//115200);
  ss.begin(9600);
#endif
  m.init();
}

void loop() {
#ifdef BT_HWS
  if (Serial.available()) {
#else
  if (ss.available()) {
#endif
    String s =
#ifdef BT_HWS
    Serial.readString();
#else
    ss.readString();
#endif    
#ifndef BT_HWS
    Serial.println(s);
#endif
    if (s.startsWith("s")) {
      s = s.substring(1);
      int i = s.toInt();
#ifndef BT_HWS
    Serial.println(s);
#endif
      m.go(i);
    }
  }
}

