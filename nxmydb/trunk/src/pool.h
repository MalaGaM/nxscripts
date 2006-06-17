/*

nxMyDB - MySQL Database for ioFTPD
Copyright (c) 2006 neoxed

Module Name:
    Pool

Author:
    neoxed (neoxed@gmail.com) Jun 14, 2006

Abstract:
    Resource pool declarations.

*/

#ifndef _POOL_H_
#define _POOL_H_

/*++

POOL_CONSTRUCTOR_PROC

    Creates a resource.

Arguments:
    opaque  - Opaque argument passed to PoolInit().

    data    - Opaque data set by this callback.

Return Values:
    If the resource was created successfully, the return must be nonzero (true).

    If the resource was not created, the return must be zero (false).

Remarks:
    The system error code must be set on failure.

--*/
typedef BOOL (POOL_CONSTRUCTOR_PROC)(
    void *opaque,
    void **data
    );

/*++

POOL_VALIDATOR_PROC

    Validates a resource.

Arguments:
    opaque  - Opaque argument passed to PoolInit().

    data    - Opaque data set by the constructor callback.

Return Values:
    If the resource is valid, the return must be nonzero (true).

    If the resource is invalid, the return must be zero (false).

Remarks:
    The system error code must be set if invalid.

--*/
typedef BOOL (POOL_VALIDATOR_PROC)(
    void *opaque,
    void *data
    );

/*++

POOL_DESTRUCTOR_PROC

    Destroys a resource.

Arguments:
    opaque  - Opaque argument passed to PoolInit().

    data    - Opaque data set by the constructor callback.

Return Values:
    None.

--*/
typedef void (POOL_DESTRUCTOR_PROC)(
    void *opaque,
    void *data
    );

//
// Pool resource
//

struct POOL_RESOURCE {
    UINT64 used;                        // Time when the resource was last used
    void *data;                         // Opaque data set by the constructor callback
    TAILQ_ENTRY(POOL_RESOURCE) link;    // Link to the previous and next resources
};
typedef struct POOL_RESOURCE POOL_RESOURCE;

//
// Pool structure
//

TAILQ_HEAD(POOL_TAIL_QUEUE, POOL_RESOURCE);
typedef struct POOL_TAIL_QUEUE POOL_TAIL_QUEUE;

typedef struct {
    DWORD                 idle;         // Number of idle resources
    DWORD                 total;        // Total number of resources
    DWORD                 minimum;      // Minimum number of resources to have available
    DWORD                 average;      // Average number of resources to have available
    DWORD                 maximum;      // Maximum number of resources to have available
    DWORD                 timeout;      // Milliseconds to wait for a resource to become available
    UINT64                expiration;   // 100nsec intervals (FILETIME) until a resource expires
    UINT64                validate;     // 100nsec intervals (FILETIME) until a resource is validated
    POOL_CONSTRUCTOR_PROC *constructor; // Procedure called when a resource is created
    POOL_VALIDATOR_PROC   *validator;   // Procedure called when a resource requires validation
    POOL_DESTRUCTOR_PROC  *destructor;  // Procedure called when a resource is destroyed
    void                  *opaque;      // Opaque argument passed to the constructor and destructor
    POOL_TAIL_QUEUE       resQueue;     // Queue of resources
    POOL_TAIL_QUEUE       conQueue;     // Queue of containers
    CONDITION_VARIABLE    availCond;    // Signaled once a used resource becomes available
    CRITICAL_SECTION      queueLock;    // Synchronize access to the tail queues
} POOL;

//
// Pool functions
//

BOOL
PoolInit(
    POOL *pool,
    DWORD minimum,
    DWORD average,
    DWORD maximum,
    DWORD timeout,
    DWORD expiration,
    DWORD validate,
    POOL_CONSTRUCTOR_PROC *constructor,
    POOL_VALIDATOR_PROC *validator,
    POOL_DESTRUCTOR_PROC *destructor,
    void *opaque
    );

void
PoolDestroy(
    POOL *pool
    );

BOOL
PoolAcquire(
    POOL *pool,
    void **data
    );

BOOL
PoolRelease(
    POOL *pool,
    void *data
    );

BOOL
PoolValidate(
    POOL *pool,
    void *data
    );

#endif // _POOL_H_
