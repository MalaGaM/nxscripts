/*

nxMyDB - MySQL Database for ioFTPD
Copyright (c) 2006 neoxed

Module Name:
    Common Header

Author:
    neoxed (neoxed@gmail.com) Jun 3, 2006

Abstract:
    Common header, used by all source files.

*/

#ifndef _MYDB_H_
#define _MYDB_H_

#undef UNICODE
#undef _UNICODE

// System headers
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#define STRSAFE_NO_CB_FUNCTIONS
#include <strsafe.h>

// Standard headers
#include <stddef.h>
#include <stdlib.h>
#include <time.h>

// ioFTPD headers
#include <ServerLimits.h>
#include <Buffer.h>
#include <Log.h>
#include <Timer.h>
#include <UserFile.h>
#include <GroupFile.h>
#include <User.h>
#include <Group.h>

// Project headers
#include "procs.h"


// Calling convention used by ioFTPD for module functions.
#define MODULE_CALL __cdecl

#endif // _MYDB_H_
