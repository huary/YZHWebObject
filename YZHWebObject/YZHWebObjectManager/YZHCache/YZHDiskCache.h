//
//  YZHDiskCache.h
//  YZHURLSessionTaskOperation
//
//  Created by yuan on 2019/1/5.
//  Copyright © 2019年 yuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YZHDiskCache;

typedef NSData*(^YZHDiskCacheEncodeBlock)(YZHDiskCache *cache, id object);
typedef id(^YZHDiskCacheDecodeBlock)(YZHDiskCache *cache, NSData *data);

typedef void(^YZHDiskCacheSaveCompletionBlock)(YZHDiskCache *cache, id object);
typedef void(^YZHDiskCacheLoadCompletionBlock)(YZHDiskCache *cache, NSData *data, id object);
typedef void(^YZHDiskCacheRemoveCompletionBlock)(YZHDiskCache *cache, NSString *path);
typedef void(^YZHDiskCacheDirectoryEnumeratorBlock)(YZHDiskCache *cache, NSDirectoryEnumerator *directoryEnumerator);
typedef void(^YZHDiskCacheCheckExistsCompletionBlock)(YZHDiskCache *cache, NSString *path, BOOL exists);

@protocol YZHDiskCacheObjectCodingProtocol <NSObject>

/* <#注释#> */
@property (nonatomic, copy) YZHDiskCacheEncodeBlock encodeBlock;

/* <#注释#> */
@property (nonatomic, copy) YZHDiskCacheDecodeBlock decodeBlock;

@end

@interface YZHDiskCache : NSObject

-(instancetype)initWithName:(NSString*)name;

-(instancetype)initWithName:(NSString *)name directory:(NSString*)directory;

/* <#注释#> */
@property (nonatomic, strong, readonly) NSString *name;

/* <#name#> */
@property (nonatomic, assign) BOOL syncDoCompletion;

-(NSString*)fullCacheDirectory;

-(void)createCacheDirectory;

-(void)saveObject:(id)object forFileName:(NSString*)fileName completion:(YZHDiskCacheSaveCompletionBlock)completion;

-(void)saveObject:(id)object data:(NSData*)data forFileName:(NSString*)fileName completion:(YZHDiskCacheSaveCompletionBlock)completion;

-(void)moveItemAtPath:(NSString*)path toPath:(NSString*)toPath;

//可以cancel
-(NSOperation*)loadObjectForFileName:(NSString*)fileName decode:(YZHDiskCacheDecodeBlock)decode completion:(YZHDiskCacheLoadCompletionBlock)completion;

//可以cancel
-(NSOperation*)removeObjectForFileName:(NSString*)fileName completion:(YZHDiskCacheRemoveCompletionBlock)completion;

@end
