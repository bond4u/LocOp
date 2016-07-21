//arduino reads commands through bluetooth and operates the motor
//command in format of "sxxx" where xxx is speed and can be negative (backwards)

#define BT_HWS
//#define USB_DBG
#define BT_SPD 38400

#ifndef BT_HWS
#include <SoftwareSerial.h> 
#endif

// timer1 pins
const int MOTA_PINA = 9;  // (pwm) pin 9 connected to pin A-IA 
const int MOTA_PINB = 10;  // (pwm) pin 10 connected to pin A-IB 

const int SS_RX = 3; // software serial pins if used
const int SS_TX = 4;

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

#ifndef BT_HWS
SoftwareSerial ss(SS_RX,SS_TX);
#endif
Motor m(MOTA_PINA, MOTA_PINB);

/**
 * Divides a given PWM pin frequency by a divisor.
 * 
 * The resulting frequency is equal to the base frequency divided by
 * the given divisor:
 *   - Base frequencies:
 *      o The base frequency for pins 3, 9, 10, and 11 is 31250 Hz.
 *      o The base frequency for pins 5 and 6 is 62500 Hz.
 *   - Divisors:
 *      o The divisors available on pins 5, 6, 9 and 10 are: 1, 8, 64,
 *        256, and 1024.
 *      o The divisors available on pins 3 and 11 are: 1, 8, 32, 64,
 *        128, 256, and 1024.
 * 
 * PWM frequencies are tied together in pairs of pins. If one in a
 * pair is changed, the other is also changed to match:
 *   - Pins 5 and 6 are paired on timer0
 *   - Pins 9 and 10 are paired on timer1
 *   - Pins 3 and 11 are paired on timer2
 * 
 * Note that this function will have side effects on anything else
 * that uses timers:
 *   - Changes on pins 3, 5, 6, or 11 may cause the delay() and
 *     millis() functions to stop working. Other timing-related
 *     functions may also be affected.
 *   - Changes on pins 9 or 10 will cause the Servo library to function
 *     incorrectly.
 * 
 * Thanks to macegr of the Arduino forums for his documentation of the
 * PWM frequency divisors. His post can be viewed at:
 *   http://forum.arduino.cc/index.php?topic=16612#msg121031
 */
void setPwmFrequency(int pin, int divisor) {
  byte mode;
  if(pin == 5 || pin == 6 || pin == 9 || pin == 10) {
    switch(divisor) {
      case 1: mode = 0x01; break;
      case 8: mode = 0x02; break;
      case 64: mode = 0x03; break;
      case 256: mode = 0x04; break;
      case 1024: mode = 0x05; break;
      default: return;
    }
    if(pin == 5 || pin == 6) {
      TCCR0B = TCCR0B & 0b11111000 | mode;
    } else {
      TCCR1B = TCCR1B & 0b11111000 | mode;
    }
  } else if(pin == 3 || pin == 11) {
    switch(divisor) {
      case 1: mode = 0x01; break;
      case 8: mode = 0x02; break;
      case 32: mode = 0x03; break;
      case 64: mode = 0x04; break;
      case 128: mode = 0x05; break;
      case 256: mode = 0x06; break;
      case 1024: mode = 0x7; break;
      default: return;
    }
    TCCR2B = TCCR2B & 0b11111000 | mode;
  }
}

void setup() {
#ifdef BT_HWS
  Serial.begin(BT_SPD);
#else
#ifdef USB_DBG
  Serial.begin(57600);//115200);
#endif
  ss.begin(BT_SPD);
#endif
  m.init();
  setPwmFrequency(9,64); // timer1:31250/8=3902(default) 31250/64=488
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
    Serial.print("in: ");
    Serial.println(s);
#endif
#endif
    if (s.startsWith("s")) {
      s = s.substring(1);
      int i = s.toInt();
#ifndef BT_HWS
#ifdef USB_DBG
    Serial.print("speed: ");
    Serial.println(s);
#endif
#endif
      m.go(i);
    }
  }
}

