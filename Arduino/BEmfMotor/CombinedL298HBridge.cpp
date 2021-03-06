/*

 Copyright (c) by Emil Valkov,
 All rights reserved.

 License: http://www.opensource.org/licenses/bsd-license.php
*/

//#include "Arduino.h"
#include "CombinedL298HBridge.h"

void CombinedL298HBridge::Initialize(int pin1, int pin2) {
	fControl[0].Initialize(pin1);
	fControl[1].Initialize(pin2);

	FreeBothPins();
}
