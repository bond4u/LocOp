/*

 Copyright (c) by Emil Valkov,
 All rights reserved.

 License: http://www.opensource.org/licenses/bsd-license.php
*/

#ifndef __HalfHBridge__
#define __HalfHBridge__

#include "Arduino.h"

class HalfHBridge {
public:
	HalfHBridge() {
	  fPin = -1;
	}

	void Initialize(int pin) {
		fPin = pin;
//		fEnablePin = enablePin;
		pinMode(fPin, OUTPUT);
//		pinMode(fEnablePin, OUTPUT);
	}
	// first digital, second digital
/*	void SetDD(boolean value, boolean enable) {
		digitalWrite(fPin, value);
//		digitalWrite(fEnablePin, enable);
	}*/
	// first digital, second analog/PWM
/*	void SetDA(boolean value, int enable) {
		digitalWrite(fPin, value);
//		analogWrite(fEnablePin, enable);
	}*/
	// first analog/PWM, second digital
/*	void SetAD(int value, boolean enable) {
		analogWrite(fPin, value);
//		digitalWrite(fEnablePin, enable);
	}*/
	// first digital
	void SetD(boolean enable) {
		digitalWrite(fPin, enable);
	}
	// first analog/PWM
	void SetA(int value) {
		analogWrite(fPin, value);
	}

/*	void SetEnableD(boolean enable) {
		digitalWrite(fEnablePin, enable);
	}*/

/*	void SetEnableA(int value) {
		analogWrite(fEnablePin, value);
	}*/

private:
//	int fEnablePin;
	int fPin;
};

#endif
