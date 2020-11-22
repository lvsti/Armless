//
//  SystemInfo.h
//  Mostly ARMless
//
//  Created by Tamas Lustyik on 2020. 11. 22..
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CPUType) {
    kCPUTypeX86_64 NS_SWIFT_NAME(x86_64),
    kCPUTypeARM64 NS_SWIFT_NAME(arm64),
    kCPUTypeUnknown
};

@interface SystemInfo : NSObject

@property (nonatomic, class, readonly, assign) CPUType cpuType;

@end

NS_ASSUME_NONNULL_END
