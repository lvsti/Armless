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
    NSMutableDictionary* _slices;
}

- (instancetype)initWithURL:(NSURL*)url {
    self = [super init];

    FILE* macho = fopen(url.path.fileSystemRepresentation, "rb");
    if (!macho) {
        return nil;
    }

    uint32_t magic = 0;
    if (fread(&magic, 1, sizeof(uint32_t), macho) != sizeof(uint32_t)) {
        fclose(macho);
        return nil;
    }

    fseek(macho, 0, SEEK_SET);

    _slices = [NSMutableDictionary dictionary];

    BOOL success = NO;
    switch (magic) {
        case FAT_MAGIC:
        case FAT_CIGAM:
            _isFatBinary = YES;
            success = [self parseFatHeader:macho is64Bit:NO];
            break;
        case FAT_MAGIC_64:
        case FAT_CIGAM_64:
            _isFatBinary = YES;
            success = [self parseFatHeader:macho is64Bit:YES];
            break;
        case MH_MAGIC:
        case MH_CIGAM:
            success = [self parseMachHeader:macho is64Bit:NO];
            break;
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            success = [self parseMachHeader:macho is64Bit:YES];
            break;
        default: break;
    }

    fclose(macho);

    if (!success) {
        return nil;
    }

    return self;
}

- (BOOL)isFatBinary {
    return _isFatBinary;
}

- (NSDictionary<NSNumber *,NSNumber *> *)slices {
    return _slices;
}

- (BOOL)parseFatHeader:(FILE*)macho is64Bit:(BOOL)is64Bit {
    char buf[64];
    if (fread(buf, 1, sizeof(struct fat_header), macho) != sizeof(struct fat_header)) {
        return NO;
    }

    struct fat_header* fatHeader = (struct fat_header*)buf;
    int numArch = OSSwapInt32(fatHeader->nfat_arch);

    for (int i = 0; i < numArch; i++) {
        if (is64Bit) {
            if (fread(buf, 1, sizeof(struct fat_arch_64), macho) != sizeof(struct fat_arch_64)) {
                return NO;
            }

            struct fat_arch_64* arch = (struct fat_arch_64*)buf;
            [self updateSlicesWithCPUType:OSSwapInt32(arch->cputype) subtype:OSSwapInt32(arch->cpusubtype) size:OSSwapInt64(arch->size)];
        }
        else {
            if (fread(buf, 1, sizeof(struct fat_arch), macho) != sizeof(struct fat_arch)) {
                return NO;
            }

            struct fat_arch* arch = (struct fat_arch*)buf;
            [self updateSlicesWithCPUType:OSSwapInt32(arch->cputype) subtype:OSSwapInt32(arch->cpusubtype) size:OSSwapInt32(arch->size)];
        }
    }
    
    return YES;
}

- (BOOL)parseMachHeader:(FILE*)macho is64Bit:(BOOL)is64Bit {
    char buf[64];

    cpu_type_t cpuType;
    cpu_subtype_t cpuSubtype;
    if (is64Bit) {
        if (fread(buf, 1, sizeof(struct mach_header_64), macho) != sizeof(struct mach_header_64)) {
            return NO;
        }
        struct mach_header_64* mh = (struct mach_header_64*)buf;
        cpuType = mh->cputype;
        cpuSubtype = mh->cpusubtype;
    }
    else {
        if (fread(buf, 1, sizeof(struct mach_header), macho) != sizeof(struct mach_header)) {
            return NO;
        }
        struct mach_header* mh = (struct mach_header*)buf;
        cpuType = mh->cputype;
        cpuSubtype = mh->cpusubtype;
    }
    fseek(macho, 0, SEEK_END);
    uint64_t size = ftell(macho);
    [self updateSlicesWithCPUType:cpuType subtype:cpuSubtype size:size];

    return YES;
}

- (void)updateSlicesWithCPUType:(cpu_type_t)cpuType subtype:(cpu_subtype_t)cpuSubtype size:(uint64_t)size {
    SliceType sliceType = kSliceTypeUnknown;

    switch (cpuType) {
        case CPU_TYPE_POWERPC: sliceType = kSliceTypePPC; break;
        case CPU_TYPE_POWERPC64: sliceType = kSliceTypePPC64; break;
        case CPU_TYPE_I386: sliceType = kSliceTypeI386; break;
        case CPU_TYPE_X86_64: sliceType = kSliceTypeX86_64; break;
        case CPU_TYPE_ARM64: sliceType = kSliceTypeARM64; break;
        default:
            if (cpuType & CPU_TYPE_ARM) {
                if (cpuSubtype & CPU_SUBTYPE_ARM_V6) {
                    sliceType = kSliceTypeARMv6;
                }
                else if (cpuSubtype & CPU_SUBTYPE_ARM_V7) {
                    sliceType = kSliceTypeARMv7;
                }
                else if (cpuSubtype & CPU_SUBTYPE_ARM_V7S) {
                    sliceType = kSliceTypeARMv7s;
                }
            }
            break;
    }

    if (sliceType == kSliceTypeUnknown && _slices[@(sliceType)]) {
        _slices[@(sliceType)] = @([_slices[@(sliceType)] unsignedLongLongValue] + size);
    }
    else {
        _slices[@(sliceType)] = @(size);
    }
}

@end
