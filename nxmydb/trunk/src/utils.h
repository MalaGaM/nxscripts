/*

nxMyDB - MySQL Database for ioFTPD
Copyright (c) 2006 neoxed

Module Name:
    Utilities

Author:
    neoxed (neoxed@gmail.com) Jun 3, 2006

Abstract:
    Miscellaneous utilities.

*/

#ifndef _UTIL_H_
#define _UTIL_H_

void
DebugPrint(
    const char *format,
    ...
    );

#ifndef DEBUG
#   define DebugPrint
#endif

#endif // _UTIL_H_
