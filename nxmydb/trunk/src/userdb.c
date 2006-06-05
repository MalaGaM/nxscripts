/*

nxMyDB - MySQL Database for ioFTPD
Copyright (c) 2006 neoxed

Module Name:
    User Database Backend

Author:
    neoxed (neoxed@gmail.com) Jun 5, 2006

Abstract:
    User database storage backend.

*/

#include "mydb.h"

BOOL
DbUserCreate(
    char *userName,
    INT32 userId,
    USERFILE *userFile
    )
{
    return TRUE;
}

BOOL
DbUserRename(
    char *userName,
    INT32 userId,
    char *newName
    )
{
    return TRUE;
}

BOOL
DbUserDelete(
    char *userName,
    INT32 userId
    )
{
    return TRUE;
}

BOOL
DbUserLock(
    USERFILE *userFile
    )
{
    return TRUE;
}

BOOL
DbUserUnlock(
    USERFILE *userFile
    )
{
    return TRUE;
}

BOOL
DbUserOpen(
    char *userName,
    USERFILE *userFile
    )
{
    return TRUE;
}

BOOL
DbUserWrite(
    USERFILE *userFile
    )
{
    return TRUE;
}

BOOL
DbUserClose(
    INT_CONTEXT *context
    )
{
    return TRUE;
}
