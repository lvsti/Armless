//
//  SystemInfo.m
//  Mostly ARMless
//
//  Created by Tamas Lustyik on 2020. 11. 22..
//

#import "SystemInfo.h"

#include <mach/machine.h>
#include <sys/sysctl.h>

@implementation SystemInfo

+ (CPUType)cpuType {
    uint32_t cpuType = 0;
    size_t size = sizeof(cpuType);

    if (!sysctlbyname("hw.cputype", &cpuType, &size, NULL, 0)) {
        switch (cpuType) {
            case CPU_TYPE_ARM64: return kCPUTypeARM64;
            case CPU_TYPE_X86:
            case CPU_TYPE_X86_64: return kCPUTypeX86_64;
        }
    }

    return kCPUTypeUnknown;
}

@end
