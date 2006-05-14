/*++

nxSDK - ioFTPD Software Development Kit
Copyright (c) 2006 neoxed

Module Name:
    Public Defintions

Author:
    neoxed (neoxed@gmail.com) May 13, 2006

Abstract:
    Include file for public use.

--*/

#ifndef _NXSDK_H_
#define _NXSDK_H_

// ioFTPD includes
#include <ServerLimits.h>
#include <UserFile.h>
#include <GroupFile.h>
#include <WinMessages.h>
#include <DataCopy.h>

#ifdef _MSC_VER
#   define STDCALL __stdcall
#else
#   define STDCALL
#endif


/*++

IO_SESSION

    Shared memory session structure.

Members:
    messageWnd      - Handle to ioFTPD's message window.

    currentProcId   - Current process ID.

    remoteProcId    - ioFTPD's process ID.

--*/
typedef struct {
    HWND  messageWnd;
    DWORD currentProcId;
    DWORD remoteProcId;
} IO_SESSION;

/*++

IO_MEMORY

    Shared memory block structure.

Members:
    block   - Block of mapped memory, allocated in the local process.

    message - Data-copy message structure.

    remote  - Remote handle, used by ioFTPD.

    bytes   - Size of the mapped memory block, in bytes.

    event   - Event signaled when the request is complete.

    mapping - Handle to the mapped memory.

--*/
typedef struct {
    void       *block;
    DC_MESSAGE *message;
    void       *remote;
    DWORD      bytes;
    HANDLE     event;
    HANDLE     mapping;
} IO_MEMORY;

/*++

IO_VFS

    Virtual file system ownership and permission.

Members:
    userId      - User identifier.

    groupId     - Group identifier.

    fileMode    - Octal value of chmod-style permissions.

--*/
typedef struct {
    UINT32 userId;
    UINT32 groupId;
    DWORD  fileMode;
} IO_VFS;


//
// Shared memory functions
//

BOOL
STDCALL
Io_ShmInit(
    const char *window,
    IO_SESSION *session
    );

IO_MEMORY *
STDCALL
Io_ShmAlloc(
    IO_SESSION *session,
    DWORD bytes
    );

void
STDCALL
Io_ShmFree(
    IO_SESSION *session,
    IO_MEMORY *memory
    );

DWORD
STDCALL
Io_ShmQuery(
    IO_SESSION *session,
    IO_MEMORY *memory,
    DWORD queryId,
    DWORD timeOut
    );


//
// Utility functions
//

BOOL
STDCALL
Io_GetBinaryPath(
    IO_SESSION *session,
    char *path,
    DWORD pathLength
    );

BOOL
STDCALL
Io_GetStartTime(
    IO_SESSION *session,
    FILETIME *startTime
    );


//
// User functions
//

BOOL
STDCALL
Io_UserCreate(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const char *userName,
    int *userId
    );

BOOL
STDCALL
Io_UserRename(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const char *userName,
    const char *newName
    );

BOOL
STDCALL
Io_UserDelete(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const char *userName
    );

BOOL
STDCALL
Io_UserGetFile(
    IO_SESSION *session,
    IO_MEMORY *memory,
    int userId,
    USERFILE *userFile
    );

BOOL
STDCALL
Io_UserSetFile(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const USERFILE *userFile
    );

BOOL
STDCALL
Io_UserIdToName(
    IO_SESSION *session,
    IO_MEMORY *memory,
    int userId,
    char *userName
    );

BOOL
STDCALL
Io_UserNameToId(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const char *userName,
    int *userId
    );


//
// Group functions
//

BOOL
STDCALL
Io_GroupCreate(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const char *groupName,
    int *groupId
    );

BOOL
STDCALL
Io_GroupRename(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const char *groupName,
    const char *newName
    );

BOOL
STDCALL
Io_GroupDelete(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const char *groupName
    );

BOOL
STDCALL
Io_GroupGetFile(
    IO_SESSION *session,
    IO_MEMORY *memory,
    int groupId,
    GROUPFILE *groupFile
    );

BOOL
STDCALL
Io_GroupSetFile(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const GROUPFILE *groupFile
    );

BOOL
STDCALL
Io_GroupIdToName(
    IO_SESSION *session,
    IO_MEMORY *memory,
    int groupId,
    char *groupName
    );

BOOL
STDCALL
Io_GroupNameToId(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const char *groupName,
    int *groupId
    );


//
// Online data functions
//

typedef BOOL (STDCALL ONLINEDATA_ROUTINE)(
    IO_SESSION *session,
    int connId,
    ONLINEDATA *onlineData,
    void *opaque
    );

void
STDCALL
Io_GetOnlineData(
    IO_SESSION *session,
    IO_MEMORY *memory,
    ONLINEDATA_ROUTINE *routine,
    void *opaque
    );

void
STDCALL
Io_KickConnId(
    IO_SESSION *session,
    int connId
    );

void
STDCALL
Io_KickUserId(
    IO_SESSION *session,
    int userId
    );


//
// VFS functions
//

BOOL
STDCALL
Io_VfsFlush(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const char *dirPath
    );

BOOL
STDCALL
Io_VfsRead(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const char *path,
    IO_VFS *vfs
    );

BOOL
STDCALL
Io_VfsWrite(
    IO_SESSION *session,
    IO_MEMORY *memory,
    const char *path,
    const IO_VFS *vfs
    );

#endif // _NXSDK_H_
