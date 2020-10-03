//
//  MachOReader.h
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 02..
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MachOReader : NSObject

@property (nonatomic, readonly, assign) BOOL isFatBinary;
@property (nonatomic, readonly, assign) BOOL hasX86_64;
@property (nonatomic, readonly, assign) BOOL hasARM64;
@property (nonatomic, readonly, assign) uint64_t arm64Size;

- (instancetype _Nullable)initWithURL:(NSURL*)url;

@end

NS_ASSUME_NONNULL_END
