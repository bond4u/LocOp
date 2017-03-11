/*

 Copyright (c) by Emil Valkov,
 All rights reserved.

 License: http://www.opensource.org/licenses/bsd-license.php
*/

#ifndef __CombinedL298HBridge__
#define __CombinedL298HBridge__

#include <Arduino.h>
#include "HalfHBridge.h"

class CombinedL298HBridge {
public:
	CombinedL298HBridge() {
		fDirection = 0;
	}

	void Initialize(int pin1, int pin2);

	void SetDirection(int direction) {
		fDirection = direction;
	}

	void Start(int pwm) {
		//opposite LOW
//		fControl[1-fDirection].SetDD(LOW, HIGH);
		fControl[1-fDirection].SetD(LOW);
		//direction PWM
		SetPwm(pwm);
	}

	void Start() {
		//opposite LOW
//		fControl[1-fDirection].SetDD(LOW, HIGH);
		fControl[1-fDirection].SetD(LOW);
		//direction max
		SetHigh();
	}

	void Stop() {
		//both LOW
//		fControl[0].SetDD(LOW, HIGH);
		fControl[0].SetD(LOW);
//		fControl[1].SetDD(LOW, HIGH);
		fControl[1].SetD(LOW);
	}

	void SetPwm(int pwm) {
		//direction PWM
//		fControl[fDirection].SetDA(HIGH, pwm);
		fControl[fDirection].SetA(pwm);
	}

	void SetHigh() {
		//direction max
//		fControl[fDirection].SetDD(HIGH, HIGH);
		fControl[fDirection].SetD(HIGH);
	}

	void FreeBothPins() {
		//both LOW
//		fControl[0].SetEnableD(LOW);
		fControl[0].SetD(LOW);
//		fControl[1].SetEnableD(LOW);
		fControl[1].SetD(LOW);
	}

	void FreeHighPin() {
		//direction LOW
//		fControl[fDirection].SetEnableD(LOW);
		fControl[fDirection].SetD(LOW);
	}

private:
	HalfHBridge fControl[2];
	int fDirection;
};

#endif
