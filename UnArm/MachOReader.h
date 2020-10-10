//
//  MachOReader.h
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 02..
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SliceType) {
    kSliceTypePPC NS_SWIFT_NAME(ppc),
    kSliceTypePPC64 NS_SWIFT_NAME(ppc64),
    kSliceTypeI386 NS_SWIFT_NAME(i386),
    kSliceTypeX86_64 NS_SWIFT_NAME(x86_64),
    kSliceTypeARMv6 NS_SWIFT_NAME(armV6),
    kSliceTypeARMv7 NS_SWIFT_NAME(armV7),
    kSliceTypeARMv7s NS_SWIFT_NAME(armV7s),
    kSliceTypeARM64 NS_SWIFT_NAME(arm64),
    kSliceTypeUnknown
};

@interface MachOReader : NSObject

@property (nonatomic, readonly, assign) BOOL isFatBinary;
@property (nonatomic, readonly) NSDictionary<NSNumber*, NSNumber*>* slices;

- (instancetype _Nullable)initWithURL:(NSURL*)url;

@end

NS_ASSUME_NONNULL_END
