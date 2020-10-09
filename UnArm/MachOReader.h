//
//  MachOReader.h
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 02..
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SliceType) {
    kSliceTypePPC,
    kSliceTypePPC64,
    kSliceTypeI386,
    kSliceTypeX86_64,
    kSliceTypeARMv6,
    kSliceTypeARMv7,
    kSliceTypeARMv7s,
    kSliceTypeARM64,
    kSliceTypeUnknown
};

@interface MachOReader : NSObject

@property (nonatomic, readonly, assign) BOOL isFatBinary;
@property (nonatomic, readonly) NSDictionary<NSNumber*, NSNumber*>* slices;

- (instancetype _Nullable)initWithURL:(NSURL*)url;

@end

NS_ASSUME_NONNULL_END
