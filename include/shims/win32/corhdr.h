#ifndef ROSETTE_SHIMS_WIN32_CORHDR_H
#define ROSETTE_SHIMS_WIN32_CORHDR_H

#include "windows.h"

#ifndef IMAGE_DATA_DIRECTORY_DEFINED
#define IMAGE_DATA_DIRECTORY_DEFINED
typedef struct _IMAGE_DATA_DIRECTORY {
    DWORD   VirtualAddress;
    DWORD   Size;
} IMAGE_DATA_DIRECTORY, *PIMAGE_DATA_DIRECTORY;
#endif

/* COR20 header types — minimal definitions for mscoree compilation. */

#define COMIMAGE_FLAGS_ILONLY            0x00000001
#define COMIMAGE_FLAGS_32BITREQUIRED     0x00000002
#define COMIMAGE_FLAGS_IL_LIBRARY        0x00000004
#define COMIMAGE_FLAGS_STRONGNAMESIGNED  0x00000008
#define COMIMAGE_FLAGS_NATIVE_ENTRYPOINT 0x00000010
#define COMIMAGE_FLAGS_TRACKDEBUGDATA    0x00010000
#define COMIMAGE_FLAGS_32BITPREFERRED    0x00020000

#define COR_VERSION_MAJOR_V2             2
#define COR_VERSION_MINOR_V2             0
#define COR_VERSION_MAJOR                2
#define COR_VERSION_MINOR                5

typedef struct IMAGE_COR20_HEADER {
    DWORD                   cb;
    WORD                    MajorRuntimeVersion;
    WORD                    MinorRuntimeVersion;
    IMAGE_DATA_DIRECTORY    MetaData;
    DWORD                   Flags;
    union {
        DWORD               EntryPointToken;
        DWORD               EntryPointRVA;
    };
    IMAGE_DATA_DIRECTORY    Resources;
    IMAGE_DATA_DIRECTORY    StrongNameSignature;
    IMAGE_DATA_DIRECTORY    CodeManagerTable;
    IMAGE_DATA_DIRECTORY    VTableFixups;
    IMAGE_DATA_DIRECTORY    ExportAddressTableJumps;
    IMAGE_DATA_DIRECTORY    ManagedNativeHeader;
} IMAGE_COR20_HEADER, *PIMAGE_COR20_HEADER;

#endif
