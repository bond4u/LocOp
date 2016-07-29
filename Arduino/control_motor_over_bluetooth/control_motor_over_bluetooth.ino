//arduino reads commands through bluetooth and operates the motor
//command in format of "sxxx" where xxx is speed and can be negative (backwards)

//#define BT_HWS
#define USB_DBG
#define BT_SPD 19200//38400
#define USE_SPWM
// 16800 rpm motor is 16800/60=280 rotations per second aka herz
#define MOTOR_HZ (16800/60)
// three pulses (for three coils) per full rotation 280*3=840
#define PWM_HZ (MOTOR_HZ*3)
// max pulse width 1000/840=1.190 millis=1190 microsec
//#define MPW_MS (1000/PWM_HZ)
//#define MPW_US (1000*1000/PWM_HZ)
//#define MPW_MS 10
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

const int LED_PIN = 11;//A5;
const int LED_VALUE = 5;

#ifdef USE_SPWM
SOFTPWM_DEFINE_CHANNEL( 0, DDRB, PORTB, PORTB1 ); // pin d9, motor1 pin1
SOFTPWM_DEFINE_CHANNEL( 1, DDRB, PORTB, PORTB2 ); // pin d10, motor1 pin2
//SOFTPWM_DEFINE_CHANNEL( 2, DDRB, PORTB, PORTB3 ); // pin d8, led
SOFTPWM_DEFINE_OBJECT( 2 ); // of x channels
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

// intialise BT serial
void initBtSer() {
#ifdef BT_HWS
  Serial.begin(BT_SPD);
#else
  ss.begin(BT_SPD);
#endif
}

// initialise USB/debug serial
void initDbgSer() {
#ifndef BT_HWS
#ifdef USB_DBG
  Serial.begin(57600);//115200);
#endif
#endif
}

void setup() {
  initBtSer();
  initDbgSer();
#ifdef USE_SPWM
  //SoftPWM.begin(1000 / MPW_MS); //1000(ms)/10(ms)=100hz
  SoftPWM.begin(PWM_HZ); // 16800/60=280hz*3=840hz
#ifdef USB_DBG
  SoftPWM.printInterruptLoad();
#endif
#else
  m.init();
#endif
  pinMode(LED_PIN, OUTPUT);
  analogWrite(LED_PIN, LED_VALUE);
#ifdef USB_DBG
  Serial.println("Ready");
#endif
}
// is there something to read from BT serial?
boolean btSerAvail() {
#ifdef BT_HWS
  return Serial.available();
#else
  return ss.available();
#endif
}

// read String from BT serial
String btSerRead() {
#ifdef BT_HWS
  return Serial.readString();
#else
  return ss.readString();
#endif
}

// is there something to read from USB/debug ?
boolean dbgSerAvail() {
#ifdef BT_HWS
  return false;
#else
#ifdef USB_DBG
  return Serial.available();
#else
  return false;
#endif
#endif
}

// read String from USB/debug serial
String dbgSerRead() {
#ifdef BT_HWS
  return "";
#else
#ifdef USB_DBG
  return Serial.readString();
#else
  return "";
#endif
#endif
}

// debug print of string
#ifndef BT_HWS
#ifdef USB_DBG
#define PRINT_STR(s) { \
  Serial.print("str: "); \
  Serial.println(s); \
}
#endif // USB_DBG
#endif // BT_HWS
#ifndef PRINT_STR
#define PRINT_STR(s) {}
#endif // PRINT_STR

// debug print of int
#ifndef BT_HWS
#ifdef USB_DBG
#define PRINT_INT(i) { \
  Serial.print("int: "); \
  Serial.println(i); \
}
#endif // USB_DBG
#endif // BT_HWS
#ifndef PRINT_INT
#define PRINT_INT(i) {}
#endif // PRINT_INT

void loop() {
  String s;
  if (btSerAvail()) {
    s = btSerRead();
    PRINT_STR(s);
  } else if (dbgSerAvail()) {
    s = dbgSerRead();
    PRINT_STR(s);
  }
  if (s.startsWith("s")) {
    s = s.substring(1);
    int i = s.toInt();
    PRINT_INT(i);
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
  } else if (s.startsWith("l")) {
    s = s.substring(1);
    int i = s.toInt();
    if (0 > i || 200 < i) { // clamped
      i = 0;
    }
    PRINT_INT(i);
    analogWrite(LED_PIN, i);
    //SoftPWM.set(2, i);
  } // else ignore
}

