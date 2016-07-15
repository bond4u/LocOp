#include <SoftwareSerial.h>

//AT : Ceck the connection.
//AT+NAME : See default name
//AT+ADDR : see default address
//AT+VERSION : See version
//AT+UART : See baudrate
//AT+ROLE: See role of bt module(1=master/0=slave)
//AT+RESET : Reset and exit AT mode
//AT+ORGL : Restore factory settings
//AT+PSWD: see default password

//#define USE_HWS1
#ifdef USE_HWS1
#else
SoftwareSerial mySerial(3,4);//10, 11); // RX, TX
#endif
#define CMD 9 // commanding mode enable pin
#define LED 13 // led pin
unsigned long t;
boolean on=true;

void setup() {
 Serial.begin(57600);//115200);//my default
 pinMode(CMD,OUTPUT);//KEY,EN,WAKEUP=AT commanding mode pin
 pinMode(LED,OUTPUT);
 digitalWrite(CMD,HIGH);// just set it high
 digitalWrite(LED,on?HIGH:LOW);
 Serial.println("Enter AT commands:");
#ifdef USE_HWS1
 Serial2.begin(
#else
 mySerial.begin(
#endif
  //115200);
   //74880);
   //57600);
   38400);
   //19200);
   //9600);//bt default
 t=millis();
}

void loop(){
 unsigned long t2=millis();
 if (t+1000<t2) {
  t=t2;
  on = !on;
  digitalWrite(LED,on?HIGH:LOW);
 }
 if (
#ifdef USE_HWS1
  Serial2.available()
#else
  mySerial.available()
#endif
 )
 Serial.write(
#ifdef USE_HWS1
  Serial2.read()
#else
  mySerial.read()
#endif
 );
 if (Serial.available())
#ifdef USE_HWS1
  Serial2.write(
#else
  mySerial.write(
#endif
   Serial.read());
}

