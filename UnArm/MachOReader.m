//
//  MachOReader.m
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 02..
//

#import "MachOReader.h"

#include <mach-o/loader.h>
#include <mach-o/fat.h>

@implementation MachOReader {
    BOOL _isFatBinary;
    BOOL _hasX86_64;
    BOOL _hasARM64;
}

- (instancetype)initWithURL:(NSURL*)url {
    self = [super init];

    FILE* macho = fopen(url.path.fileSystemRepresentation, "rb");
    if (!macho) {
        return nil;
    }

    char buf[64];
    if (fread(buf, 1, sizeof(struct fat_header), macho) != sizeof(struct fat_header)) {
        fclose(macho);
        return nil;
    }

    struct fat_header* fatHeader = (struct fat_header*)buf;
    fatHeader->magic = OSSwapInt32(fatHeader->magic);
    fatHeader->nfat_arch = OSSwapInt32(fatHeader->nfat_arch);

    if (fatHeader->magic == FAT_MAGIC) {
        _isFatBinary = YES;
        for (int i = 0; i < fatHeader->nfat_arch; i++) {
            if (fread(buf, 1, sizeof(struct fat_arch), macho) != sizeof(struct fat_arch)) {
                fclose(macho);
                return nil;
            }
            struct fat_arch* arch = (struct fat_arch*)buf;
            if (arch->cputype == OSSwapInt32(CPU_TYPE_ARM64)) {
                _hasARM64 = YES;
                _arm64Size = OSSwapInt32(arch->size);
            }
            else if (arch->cputype == OSSwapInt32(CPU_TYPE_X86_64)) {
                _hasX86_64 = YES;
            }
        }
    }
    else if (fatHeader->magic == FAT_MAGIC_64) {
        _isFatBinary = YES;
        if (fread(buf, 1, sizeof(struct fat_arch_64), macho) != sizeof(struct fat_arch_64)) {
            fclose(macho);
            return nil;
        }
        struct fat_arch_64* arch = (struct fat_arch_64*)buf;
        if (arch->cputype == OSSwapInt32(CPU_TYPE_ARM64)) {
            _hasARM64 = YES;
            _arm64Size = OSSwapInt64(arch->size);
        }
        else if (arch->cputype == OSSwapInt32(CPU_TYPE_X86_64)) {
            _hasX86_64 = YES;
        }
    }
    else {
        // check if it is a mach-o binary at all
        struct mach_header* machHeader = (struct mach_header*)buf;
        machHeader->magic = OSSwapInt32(machHeader->magic);
        if (machHeader->magic != MH_MAGIC && machHeader->magic != MH_MAGIC_64) {
            fclose(macho);
            return nil;
        }
    }

    fclose(macho);

    return self;
}

- (BOOL)isFatBinary {
    return _isFatBinary;
}

- (BOOL)hasX86_64 {
    return _hasX86_64;
}

- (BOOL)hasARM64 {
    return _hasARM64;
}

@end
