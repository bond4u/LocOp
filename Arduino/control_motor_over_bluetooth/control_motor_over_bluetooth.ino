//arduino reads commands through bluetooth and operates the motor
//command in format of "sxxx" where xxx is speed and can be negative (backwards)

//#define BT_HWS
//#define USB_DBG
#define BT_SPD /*19200*/38400
#define USE_SPWM
#define MPW_MS 10
//#define __DEBUG_SOFTPWM__ 1

#ifdef USE_SPWM
#include <SoftPWM.h>
#endif

#ifndef BT_HWS
#include <SoftwareSerial.h> 
#endif

// timer1 pins
const int MOTA_PINA = 9;  // (pwm) pin 9 connected to pin A-IA 
const int MOTA_PINB = 10;  // (pwm) pin 10 connected to pin A-IB 

const int SS_RX = 3; // software serial pins if used
const int SS_TX = 4;

#ifdef USE_SPWM
SOFTPWM_DEFINE_CHANNEL( 0, DDRB, PORTB, PORTB1 );
SOFTPWM_DEFINE_CHANNEL( 1, DDRB, PORTB, PORTB2 );
SOFTPWM_DEFINE_OBJECT( 2 );
#else
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
      // forward
      val1 = speed;
    } else if (0>speed) {
      // backwards
      val2 = -speed; //convert to positive value
    }
    if (250<val1) {
      digitalWrite(pin1, HIGH); // constant HIGH - full power
    } else {
      analogWrite(pin1, val1); // PWM - not full power
    }
    if (250<val2) {
      digitalWrite(pin2, HIGH); // constant HIGH - full power
    } else {
      analogWrite(pin2, val2); // PWM - not full power
    }
  }
};
Motor m(MOTA_PINA, MOTA_PINB);
#endif

#ifndef BT_HWS
SoftwareSerial ss(SS_RX,SS_TX);
#endif

void setup() {
#ifdef BT_HWS
  Serial.begin(BT_SPD);
#else
#ifdef USB_DBG
  Serial.begin(57600);//115200);
#endif
  ss.begin(BT_SPD);
#endif
#ifdef USE_SPWM
  SoftPWM.begin(1000 / MPW_MS); //1000(ms)/10(ms)=100hz
#ifdef USE_DBG
  SoftPWM.printInterruptLoad();
#endif
#else
  m.init();
#endif
#ifdef USE_DBG
  Serial.println("Ready");
#endif
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
#ifdef USB_DBG
    Serial.print("str: ");
    Serial.println(s);
#endif
#endif
    if (s.startsWith("s")) {
      s = s.substring(1);
      int i = s.toInt();
#ifndef BT_HWS
#ifdef USB_DBG
      Serial.print("int: ");
      Serial.println(i);
#endif
#endif
#ifdef USE_SPWM
      if (0 < i) {
        SoftPWM.set(1, 0);
        SoftPWM.set(0, i);
      } else if (0 > i) {
        SoftPWM.set(0, 0);
        SoftPWM.set(1, -i);
      } else {
        SoftPWM.set(0, 0);
        SoftPWM.set(1, 0);
      }
#else
      m.go(i);
#endif
    } // else ignore
  }
}

