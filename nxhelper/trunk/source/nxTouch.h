/*
 * nxHelper - Tcl extension for nxTools.
 * Copyright (c) 2005 neoxed
 *
 * File Name:
 *   nxTouch.h
 *
 * Author:
 *   neoxed (neoxed@gmail.com) May 22, 2005
 *
 * Abstract:
 *   Touch command definitions.
 */

#ifndef __NXTOUCH_H__
#define __NXTOUCH_H__

#define TOUCH_FLAG_ATIME     0x0001
#define TOUCH_FLAG_MTIME     0x0002
#define TOUCH_FLAG_CTIME     0x0004
#define TOUCH_FLAG_ISDIR     0x0008
#define TOUCH_FLAG_RECURSE   0x0010

int TouchObjCmd(ClientData dummy, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);

#endif /* __NXTOUCH_H__ */