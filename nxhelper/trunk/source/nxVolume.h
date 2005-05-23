/*
 * Infernus Library - Tcl extension for the Infernus sitebot.
 * Copyright (c) 2005 Infernus Development Team
 *
 * File Name:
 *   nxVolume.h
 *
 * Author:
 *   neoxed (neoxed@gmail.com) May 22, 2005
 *
 * Abstract:
 *   Volume command definitions.
 */

#ifndef __NXVOLUME_H__
#define __NXVOLUME_H__

/* Buffer size constants. */
#define VOLUME_NAME_BUFFER  MAX_PATH
#define VOLUME_FS_BUFFER    128

typedef struct {
    ULONG     serial;
    ULONG     length;
    ULONG     flags;
    UINT      type;
    ULONGLONG bytesFree;
    ULONGLONG bytesTotal;
    TCHAR     fs[VOLUME_FS_BUFFER];
    TCHAR     name[VOLUME_NAME_BUFFER];
} VolumeInfo;

int VolumeObjCmd(ClientData dummy, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);

#endif /* __NXVOLUME_H__ */
