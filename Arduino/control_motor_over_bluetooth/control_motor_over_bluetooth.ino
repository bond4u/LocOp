//arduino reads commands through bluetooth and operates the motor
//command in form of "sxxx" where xxx is speed and can be negative (backwards)
//command in form of "lyz" where y is led id a/b/c/d and z is brightness

//#define BT_HWS
#define BT_SS //one, other or none
#define BT_SPD /*19200*/38400

//if bt is on software serial then hw serial (usb) is available for debugging
#define USB_DBG
#define USB_SPD 57600

//motor pwm
// 16800 rpm motor is 16800/60=280 rotations per second aka herz
#define MOTOR_HZ (16800/60)
// three pulses (for three coils) per full rotation 280*3=840hz
// up that to three times 840*3=2520hz
#define PWM_HZ (MOTOR_HZ*3*3)
// max pulse width 1000/840=1.190 millis=1190 microsec
//#define MPW_MS (1000/PWM_HZ)
//#define MPW_US (1000*1000/PWM_HZ)
//#define MPW_MS 10

#include <PWM.h>

#ifdef BT_SS
#include <SoftwareSerial.h> 
#endif

// use timer1 (16bit) pins (9,10) for motor
#define MOTA_PINA 9  // (pwm) pin 9 connected to pin A-IA
#define MOTA_PINB 10  // (pwm) pin 10 connected to pin A-IB

#define SS_RX 7 // software serial pins if used
#define SS_TX 8

// use other timer(s) pins for leds
#define LED1_PIN 3
#define LED2_PIN 5 // pin 2,4,7,8,12,13 pwm dont work with led
#define LED3_PIN 6
#define LED4_PIN 11
#define LED_INIT 5 // initial brightness
#define LED_MAX 255
#define LED_HZ 500

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

#ifdef USB_DBG
/*  Serial.print("pin 9 timer = ");
  Serial.println(digitalPinToTimer(MOTA_PINA));
  Serial.print("pin 10 timer = ");
  Serial.println(digitalPinToTimer(MOTA_PINB));
  Serial.print("pin 3 timer = ");
  Serial.println(digitalPinToTimer(LED1_PIN));
  Serial.print("pin 5 timer = ");
  Serial.println(digitalPinToTimer(LED2_PIN));
  Serial.print("pin 6 timer = ");
  Serial.println(digitalPinToTimer(LED3_PIN));
  Serial.print("pin 11 timer = ");
  Serial.println(digitalPinToTimer(LED4_PIN));
  Serial.print("timer 0 freq = ");
  Serial.println(Timer0_GetFrequency());
  Serial.print("timer 1 freq = ");
  Serial.println(Timer1_GetFrequency());
  Serial.print("timer 2 freq = ");
  Serial.println(Timer2_GetFrequency());*/
#endif
  // just set timer1 freq (pins 9,10); leave others as they are
  // doesnt work well with other timers
  bool ok = Timer1_SetFrequency(PWM_HZ);
  if (!ok) {
    Serial.println("Pwm.set1Freq failed!");
  }

/*  InitTimersSafe();
  bool ok = SetPinFrequencySafe(MOTA_PINA, PWM_HZ);
  if (!ok) {
    Serial.println("MotA.PinA.setFreq failed!");
  }
  ok = SetPinFrequencySafe(MOTA_PINB, PWM_HZ);
  if (!ok) {
    Serial.println("MotA.PinB.setFreq failed!");
  }
  ok = SetPinFrequencySafe(LED1_PIN, LED_HZ);
  if (!ok) {
    Serial.println("Led1.setFreq failed!");
  }
  ok = SetPinFrequencySafe(LED2_PIN, LED_HZ);
  if (!ok) {
    Serial.println("Led2.setFreq failed!");
  }
  ok = SetPinFrequencySafe(LED3_PIN, LED_HZ);
  if (!ok) {
    Serial.println("Led3.setFreq failed!");
  }
  ok = SetPinFrequencySafe(LED4_PIN, LED_HZ);
  if (!ok) {
    Serial.println("Led4.setFreq failed!");
  }*/
#ifdef USB_DBG
/*  Serial.print("timer 0 freq = ");
  Serial.println(Timer0_GetFrequency());
  Serial.print("timer 1 freq2 = ");
  Serial.println(Timer1_GetFrequency());
  Serial.print("timer 2 freq2 = ");
  Serial.println(Timer2_GetFrequency());*/
#endif
  //motor pin frequencies set
  //pinMode(MOTA_PINA, OUTPUT);
  //pinMode(MOTA_PINB, OUTPUT);
  pwmWrite(MOTA_PINA, 0);
  pwmWrite(MOTA_PINB, 0);
  //let pin freq should remain default
  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);
  pinMode(LED3_PIN, OUTPUT);
  pinMode(LED4_PIN, OUTPUT);
  analogWrite(LED1_PIN, LED_INIT);
  analogWrite(LED2_PIN, LED_INIT);
  analogWrite(LED3_PIN, LED_INIT);
  analogWrite(LED4_PIN, LED_INIT);

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
//or no print
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
//or no print
#ifndef PRINT_INT
#define PRINT_INT(i) {}
#endif // PRINT_INT

void loop() {
  String s;
  if (btSerAvail()) {
    s = btSerRead();
    PRINT_STR(s);
  } else if (dbgSerAvail()) {
    //accept commands from usb when debugging
    s = dbgSerRead();
    PRINT_STR(s);
  }
  if (s.startsWith("s")) {
    //motor speed command
    s = s.substring(1);
    int i = s.toInt();
    PRINT_INT(i);
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
  } else if (s.startsWith("l")) {
    //led brightness command
    s = s.substring(1);
    int led = -1;
    if (s.startsWith("a")) { //LED1
      led = LED1_PIN;
    } else if (s.startsWith("b")) { //LED2
      led = LED2_PIN;
    } else if (s.startsWith("c")) { //LED3
      led = LED3_PIN;
    } else if (s.startsWith("d")) { //LED4
      led = LED4_PIN;
    }
    if (-1 != led) { // got led
      s = s.substring(1);
      int i = s.toInt();
      if (0 > i || LED_MAX < i) { // limit to 200 max
        i = 0;
      }
      PRINT_INT(i);
      analogWrite(led, i);
    } //else unknown led
  } // else unknown command
} //end loop

