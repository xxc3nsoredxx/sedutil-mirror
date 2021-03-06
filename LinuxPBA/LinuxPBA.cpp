/* C:B**************************************************************************
This software is Copyright 2014-2017 Bright Plaza Inc. <drivetrust@drivetrust.com>
Copyright 2020-2021 xxc3nsoredxx

This file is part of sedutil.

sedutil is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

sedutil is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with sedutil.  If not, see <http://www.gnu.org/licenses/>.

* C:E********************************************************************** */
#include "config.h"

#include <cstring>
#include <iostream>

#include <unistd.h>

#include <sys/reboot.h>

#include "Common/log.h"
#include "LinuxPBA/GetPassPhrase.h"
#include "LinuxPBA/UnlockSEDs.h"

/* Default to output that includes timestamps and goes to stderr*/
sedutiloutput outputFormat = sedutilNormal;

// Pass in "boot" as arg 1 when running through init
int main (int argc, char *argv []) {
    // DEBUG_LEVEL_INT is from config.h, set by --enable-debug[=LEVEL]
    CLog::Level() = CLog::FromInt(DEBUG_LEVEL_INT);
    RCLog::Level() = RCLog::FromInt(DEBUG_LEVEL_INT);
    LOG(D4) << "Legacy PBA start" << std::endl;
    std::string p = GetPassPhrase("Boot Authorization Key: ");
    UnlockSEDs((char *)p.c_str());
    if (argc > 1 && !strcmp(argv[1], "boot")) {
        printf("Access granted. Starting the system...\n");
        sync();
        reboot(RB_AUTOBOOT);
    }
    return 0;
}
