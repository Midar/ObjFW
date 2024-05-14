/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFGameController.h"
#import "OFArray.h"

const OFGameControllerButton OFGameControllerNorthButton = @"North";
const OFGameControllerButton OFGameControllerSouthButton = @"South";
const OFGameControllerButton OFGameControllerWestButton = @"West";
const OFGameControllerButton OFGameControllerEastButton = @"East";
const OFGameControllerButton OFGameControllerLeftTriggerButton =
    @"Left Trigger";
const OFGameControllerButton OFGameControllerRightTriggerButton =
    @"Right Trigger";
const OFGameControllerButton OFGameControllerLeftShoulderButton =
    @"Left Shoulder";
const OFGameControllerButton OFGameControllerRightShoulderButton =
    @"Right Shoulder";
const OFGameControllerButton OFGameControllerLeftStickButton = @"Left Stick";
const OFGameControllerButton OFGameControllerRightStickButton = @"Right Stick";
const OFGameControllerButton OFGameControllerDPadUpButton = @"D-Pad Up";
const OFGameControllerButton OFGameControllerDPadDownButton = @"D-Pad Down";
const OFGameControllerButton OFGameControllerDPadLeftButton = @"D-Pad Left";
const OFGameControllerButton OFGameControllerDPadRightButton = @"D-Pad Right";
const OFGameControllerButton OFGameControllerStartButton = @"Start";
const OFGameControllerButton OFGameControllerSelectButton = @"Select";
const OFGameControllerButton OFGameControllerHomeButton = @"Home";
const OFGameControllerButton OFGameControllerCaptureButton = @"Capture";
const OFGameControllerButton OFGameControllerAButton = @"A";
const OFGameControllerButton OFGameControllerBButton = @"B";
const OFGameControllerButton OFGameControllerCButton = @"C";
const OFGameControllerButton OFGameControllerXButton = @"X";
const OFGameControllerButton OFGameControllerYButton = @"Y";
const OFGameControllerButton OFGameControllerZButton = @"Z";
const OFGameControllerButton OFGameControllerCPadUpButton = @"C-Pad Up";
const OFGameControllerButton OFGameControllerCPadDownButton = @"C-Pad Down";
const OFGameControllerButton OFGameControllerCPadLeftButton = @"C-Pad Left";
const OFGameControllerButton OFGameControllerCPadRightButton = @"C-Pad Right";
const OFGameControllerButton OFGameControllerPlusButton = @"+";
const OFGameControllerButton OFGameControllerMinusButton = @"-";
const OFGameControllerButton OFGameControllerSLButton = @"SL";
const OFGameControllerButton OFGameControllerSRButton = @"SR";
const OFGameControllerButton OFGameControllerModeButton = @"Mode";

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include "platform/Linux/OFGameController.m"
#elif defined(OF_WINDOWS)
# include "platform/Windows/OFGameController.m"
#elif defined(OF_NINTENDO_DS)
# include "platform/NintendoDS/OFGameController.m"
#elif defined(OF_NINTENDO_3DS)
# include "platform/Nintendo3DS/OFGameController.m"
#else
@implementation OFGameController
@dynamic name, buttons, pressedButtons, hasLeftAnalogStick;
@dynamic leftAnalogStickPosition, hasRightAnalogStick, rightAnalogStickPosition;

+ (OFArray OF_GENERIC(OFGameController *) *)controllers
{
	return [OFArray array];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (OFNumber *)vendorID
{
	return nil;
}

- (OFNumber *)productID
{
	return nil;
}

- (void)retrieveState
{
}

- (float)pressureForButton: (OFGameControllerButton)button
{
	return 0;
}
@end
#endif
