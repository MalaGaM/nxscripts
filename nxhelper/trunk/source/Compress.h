#ifndef __COMPRESS_H__
#define __COMPRESS_H__

INT TclDeflateCmd(ClientData dummy, Tcl_Interp *interp, INT objc, Tcl_Obj *CONST objv[]);
INT TclInflateCmd(ClientData dummy, Tcl_Interp *interp, INT objc, Tcl_Obj *CONST objv[]);
static VOID TclZlibError(Tcl_Interp *interp, PCHAR Message, LONG ErrorNum);

#endif // __COMPRESS_H__