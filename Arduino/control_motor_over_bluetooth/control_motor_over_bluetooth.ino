//arduino reads commands through bluetooth and operates the motor
//command in format of "sxxx" where xxx is speed and can be negative (backwards)

//#define BT_HWS
#define BT_SS //one, other or none
#define BT_SPD /*19200*/38400

//hardware serial (usb) available for debugging
#define USB_DBG
#define USB_SPD 57600

//motor pwm
//#define USE_SPWM1
//#define MY_PWM
//#define USE_PWM3A
#define USE_PWM3B

// 16800 rpm motor is 16800/60=280 rotations per second aka herz
#define MOTOR_HZ (16800/60)
// three pulses (for three coils) per full rotation 280*3=840*3=2520hz
#define PWM_HZ (MOTOR_HZ*3*3) //softpwm1 cant handle over 0.5khz
// max pulse width 1000/840=1.190 millis=1190 microsec
//#define MPW_MS (1000/PWM_HZ)
//#define MPW_US (1000*1000/PWM_HZ)
//#define MPW_MS 10

#ifdef USE_SPWM1
//#define __DEBUG_SOFTPWM__ 1
#include <SoftPWM1.h>
#endif

#if (defined USE_PWM3A) || (defined USE_PWM3B)
#include <PWM.h>
#endif

#ifdef BT_SS
#include <SoftwareSerial.h> 
#endif

// timer1 pins
#define MOTA_PINA 9  // (pwm) pin 9 connected to pin A-IA 
#define MOTA_PINB 10  // (pwm) pin 10 connected to pin A-IB 

#define SS_RX 3 // software serial pins if used
#define SS_TX 4

// dont know whats wrong with pin11 on arduino nano
#define LED1_PIN 6
#define LED2_PIN 5 // pin 2,4,7,8,12,13 pwm dont work with led
#define LED3_PIN 11 //3 is reserved for software serial for bt
#define LED_INIT 5
#define LED_MAX 200
#define LED_HZ 500

#ifdef USE_SPWM1
SOFTPWM_DEFINE_CHANNEL( 0, DDRB, PORTB, PORTB1 ); // pin d9, motor1 pin1
SOFTPWM_DEFINE_CHANNEL( 1, DDRB, PORTB, PORTB2 ); // pin d10, motor1 pin2
//SOFTPWM_DEFINE_CHANNEL( 2, DDRB, PORTB, PORTB3 ); // pin d8, led
SOFTPWM_DEFINE_OBJECT( 2 ); // of x channels
#endif //USE_SPWM1

#ifdef MY_PWM
class Motor {
  public:
  Motor() {
  }
  void init() {
    pinMode(MOTA_PINA, OUTPUT);
    pinMode(MOTA_PINB, OUTPUT);
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
      digitalWrite(MOTA_PINA, HIGH); // constant HIGH - full power
    } else {
      analogWrite(MOTA_PINA, val1); // PWM - not full power
    }
    if (250<val2) {
      digitalWrite(MOTA_PINB, HIGH); // constant HIGH - full power
    } else {
      analogWrite(MOTA_PINB, val2); // PWM - not full power
    }
  }
};
Motor m();
#endif //MY_PWM

#ifdef BT_SS
SoftwareSerial ss(SS_RX,SS_TX);
#endif

// intialise BT serial
void initBtSer() {
#ifdef BT_HWS
  Serial.begin(BT_SPD);
#endif //BT_HWS

#ifdef BT_SS
  ss.begin(BT_SPD);
#endif //BT_SS
}

// initialise USB/debug serial
void initDbgSer() {
#ifdef USB_DBG
  Serial.begin(USB_SPD);//115200);
#endif //USB_DBG
}

// set up
void setup() {
  initBtSer();
  initDbgSer();

#ifdef USE_SPWM1
  //SoftPWM.begin(1000 / MPW_MS); //1000(ms)/10(ms)=100hz
  SoftPWM.begin(PWM_HZ); // 16800/60=280hz*3=840hz
#ifdef USB_DBG
  //SoftPWM.printInterruptLoad();
#endif //USB_DBG
#endif //USE_SPWM1

#if (defined USE_PWM3A) || (defined USE_PWM3B)
  Serial.print("timer 1 freq = ");
  Serial.println(Timer1_GetFrequency());
#endif //USE_PWM3

#ifdef USE_PWM3A
  bool ok = Timer1_SetFrequency(PWM_HZ);
  if (!ok) {
    Serial.println("Pwm.set1Freq failed!");
  }
#endif //USE_PWM3A

#ifdef USE_PWM3B
  InitTimersSafe();
  bool ok = SetPinFrequencySafe(MOTA_PINA, PWM_HZ);
  if (!ok) {
    Serial.println("Pwm.set1Freq failed!");
  }
  ok = SetPinFrequencySafe(MOTA_PINB, PWM_HZ);
  if (!ok) {
    Serial.println("Pwm.set2Freq failed!");
  }
  //Serial.print("led ping freq = ");
  //Serial.println(GetPinFrequency(LED_PIN));
/*  ok = SetPinFrequency(LED2_PIN, LED_HZ);
  if (!ok) {
    Serial.println("Pwm.set3Freq failed!");
  }
  pwmWrite(LED2_PIN, LED_INIT);*/
#endif //USE_PWM3B

#if (defined USE_PWM3A) || (defined USE_PWM3B)
  pinMode(MOTA_PINA, OUTPUT);
  pinMode(MOTA_PINB, OUTPUT);
  pwmWrite(MOTA_PINA, 0);
  pwmWrite(MOTA_PINB, 0);
#endif //USE_PWM3
  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);
  pinMode(LED3_PIN, OUTPUT);
  analogWrite(LED1_PIN, LED_INIT);
  analogWrite(LED2_PIN, LED_INIT);
  analogWrite(LED3_PIN, LED_INIT);

#ifdef MY_PWM
  m.init();
#endif //MY_PWM

#ifdef USB_DBG
  Serial.println("Ready");
#endif //USB_DBG
}

// is there something to read from BT serial?
boolean btSerAvail() {
#ifdef BT_HWS
  return Serial.available();
#else
#ifdef BT_SS
  return ss.available();
#else
  return false;
#endif //BT_SS
#endif //BT_HWS
}

// read String from BT serial
String btSerRead() {
#ifdef BT_HWS
  return Serial.readString();
#else
#ifdef BT_SS
  return ss.readString();
#else
  return "";
#endif //BT_SS
#endif //BT_HWS
}

// is there something to read from USB/debug ?
boolean dbgSerAvail() {
#ifdef USB_DBG
  return Serial.available();
#else
  return false;
#endif //USB_DBG
}

// read String from USB/debug serial
String dbgSerRead() {
#ifdef USB_DBG
  return Serial.readString();
#else
  return "";
#endif //USB_DBG
}

// debug print of string
#ifdef USB_DBG
#define PRINT_STR(s) { \
  Serial.print("str: "); \
  Serial.println(s); \
}
#endif // USB_DBG

#ifndef PRINT_STR
#define PRINT_STR(s) {}
#endif // PRINT_STR

// debug print of int
#ifdef USB_DBG
#define PRINT_INT(i) { \
  Serial.print("int: "); \
  Serial.println(i); \
}
#endif // USB_DBG

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
#ifdef USE_SPWM1
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
#endif //USE_SPWM1
#if (defined USE_PWM3A) || (defined USE_PWM3B)
    if (0 < i) {
      pwmWrite(MOTA_PINB, 0);
      pwmWrite(MOTA_PINA, i);
    } else if (0 > i) {
      pwmWrite(MOTA_PINA, 0);
      pwmWrite(MOTA_PINB, -i);
    } else  {
      pwmWrite(MOTA_PINA, 0);
      pwmWrite(MOTA_PINB, 0);
    }
#endif

#ifdef MY_PWM
    m.go(i);
#endif //MY_PWM
  } else if (s.startsWith("l")) {
    s = s.substring(1);
    int led=-1;
    if (s.startsWith("a")) { //LED1
      led = LED1_PIN;
    } else if (s.startsWith("b")) { //LED2
      led = LED2_PIN;
    } else if (s.startsWith("c")) { //LED3
      led = LED3_PIN;
    }
    if (-1 != led) { // got led
      s = s.substring(1);
      int i = s.toInt();
      if (0 > i || LED_MAX < i) { // clamped
        i = 0;
      }
      PRINT_INT(i);
#if (defined USE_PWM3A) || (define USE_PWM3B)
/*      if (LED2_PIN == led) {
        pwmWrite(led, i);
      } else*/
#else
      {
        analogWrite(led, i);
      }
#endif
      //SoftPWM.set(2, i);
    } //else unknown led
  } // else ignore
}

