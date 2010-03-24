/*

nxMyDB - MySQL Database for ioFTPD
Copyright (c) 2006-2009 neoxed

Module Name:
    Procedure Table

Author:
    neoxed (neoxed@gmail.com) Jun 3, 2006

Abstract:
    Resolve procedures exported by ioFTPD.

*/

#include <base.h>
#include <proctable.h>

#pragma warning(disable : 4152) // C4152: nonstandard extension, function/data pointer conversion in expression

// Global procedure table
PROC_TABLE procTable;

#define RESOLVE(name, func)                                                     \
{                                                                               \
    if ((func = getProc(name)) == NULL) {                                       \
        TRACE("Unable to resolve procedure \"%s\".", name);                     \
        goto failed;                                                            \
    }                                                                           \
}


/*++

ProcTableInit

    Initializes the procedure table.

Arguments:
    getProc - Pointer to ioFTPD's GetProc function.

Return Values:
    A Windows API error code.

--*/
DWORD FCALL ProcTableInit(Io_GetProc *getProc)
{
    RESOLVE("Config_GetIniFile",        procTable.pConfigGetIniFile);
    RESOLVE("Config_Get",               procTable.pConfigGet);
    RESOLVE("Config_GetBool",           procTable.pConfigGetBool);
    RESOLVE("Config_GetInt",            procTable.pConfigGetInt);
    RESOLVE("Config_GetPath",           procTable.pConfigGetPath);

    RESOLVE("GetGroups",                procTable.pGetGroups);
    RESOLVE("Gid2Group",                procTable.pGid2Group);
    RESOLVE("Group2Gid",                procTable.pGroup2Gid);
    RESOLVE("Ascii2GroupFile",          procTable.pAscii2GroupFile);
    RESOLVE("GroupFile2Ascii",          procTable.pGroupFile2Ascii);
    RESOLVE("GroupFile_Open",           procTable.pGroupFileOpen);
    RESOLVE("GroupFile_OpenPrimitive",  procTable.pGroupFileOpenPrimitive);
    RESOLVE("GroupFile_Lock",           procTable.pGroupFileLock);
    RESOLVE("GroupFile_Unlock",         procTable.pGroupFileUnlock);
    RESOLVE("GroupFile_Close",          procTable.pGroupFileClose);

    RESOLVE("GetUsers",                 procTable.pGetUsers);
    RESOLVE("Uid2User",                 procTable.pUid2User);
    RESOLVE("User2Uid",                 procTable.pUser2Uid);
    RESOLVE("Ascii2UserFile",           procTable.pAscii2UserFile);
    RESOLVE("UserFile2Ascii",           procTable.pUserFile2Ascii);
    RESOLVE("UserFile_Open",            procTable.pUserFileOpen);
    RESOLVE("UserFile_OpenPrimitive",   procTable.pUserFileOpenPrimitive);
    RESOLVE("UserFile_Lock",            procTable.pUserFileLock);
    RESOLVE("UserFile_Unlock",          procTable.pUserFileUnlock);
    RESOLVE("UserFile_Close",           procTable.pUserFileClose);

    RESOLVE("Allocate",                 procTable.pAllocate);
    RESOLVE("ReAllocate",               procTable.pReAllocate);
    RESOLVE("Free",                     procTable.pFree);

    RESOLVE("ConcatString",             procTable.pConcatString);
    RESOLVE("SplitString",              procTable.pSplitString);
    RESOLVE("GetStringIndex",           procTable.pGetStringIndex);
    RESOLVE("GetStringIndexStatic",     procTable.pGetStringIndexStatic);
    RESOLVE("GetStringRange",           procTable.pGetStringRange);
    RESOLVE("FreeString",               procTable.pFreeString);

    RESOLVE("Putlog",                   procTable.pPutlog);
    RESOLVE("QueueJob",                 procTable.pQueueJob);
    RESOLVE("StartIoTimer",             procTable.pStartIoTimer);
    RESOLVE("StopIoTimer",              procTable.pStopIoTimer);
    return ERROR_SUCCESS;

failed:
    // Unable to resolve a procedure
    ZeroMemory(&procTable, sizeof(PROC_TABLE));
    return ERROR_INVALID_FUNCTION;
}

/*++

ProcTableFinalize

    Finalizes the procedure table.

Arguments:
    None.

Return Values:
    A Windows API error code.

--*/
DWORD FCALL ProcTableFinalize(VOID)
{
    ZeroMemory(&procTable, sizeof(PROC_TABLE));
    return ERROR_SUCCESS;
}
