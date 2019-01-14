//
//  YZHDiskCache.m
//  YZHURLSessionTaskOperation
//
//  Created by yuan on 2019/1/5.
//  Copyright © 2019年 yuan. All rights reserved.
//

#import "YZHDiskCache.h"
//#import "YZHUtil.h"
#import "NSData+YZHCoding.h"
#import "UIImage+YZHCoding.h"

static const void *const dispatchIOQueueSpecificKey =&dispatchIOQueueSpecificKey;
static const void *const dispatchCompletionQueueSpecificKey = &dispatchCompletionQueueSpecificKey;

@interface YZHDiskCache ()
/* <#注释#> */
@property (nonatomic, strong) NSString *cacheDirectory;

/* <#注释#> */
@property (nonatomic, strong) NSString *fullPath;

/* <#注释#> */
@property (nonatomic, strong) dispatch_queue_t IOQueue;

/* <#注释#> */
@property (nonatomic, strong) dispatch_queue_t completionQueue;

@end

@implementation YZHDiskCache

-(instancetype)init
{
    return [self initWithName:nil directory:nil];
}

-(instancetype)initWithName:(NSString*)name
{
    return [self initWithName:name directory:nil];
}

-(instancetype)initWithName:(NSString *)name directory:(NSString*)directory
{
    self = [super init];
    if (self) {
        if (!IS_AVAILABLE_NSSTRNG(name)) {
            name = @"com.YZHDiskCache";
        }
        if (!IS_AVAILABLE_NSSTRNG(directory)) {
            directory = [YZHUtil applicationCachesDirectory:nil];
        }
        _name = name;
        self.cacheDirectory = [directory stringByStandardizingPath];
        [self _setupDefault];
    }
    return self;
}

-(NSString*)_fullCachePath
{
    return [[self.cacheDirectory stringByAppendingPathComponent:self.name] stringByStandardizingPath];
}

-(void)_setupDefault
{
    self.fullPath = [self _fullCachePath];
    self.completionQueue = dispatch_get_main_queue();
}

-(dispatch_queue_t)IOQueue
{
    if (_IOQueue == nil) {
        _IOQueue = dispatch_queue_create("com.YZHDiskCache.ioQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_IOQueue, dispatchIOQueueSpecificKey, (__bridge void *)self, NULL);
    }
    return _IOQueue;
}

-(NSString*)fullCacheDirectory
{
    return self.fullPath;
}

-(void)createCacheDirectory
{
    NSString *path = self.fullPath;
    dispatch_async(self.IOQueue, ^{
        [YZHUtil checkAndCreateDirectory:path];
    });
}

-(void)_writeData:(NSData*)data toPath:(NSString*)path
{
    NSAssert(dispatch_get_specific(dispatchIOQueueSpecificKey) == (__bridge void *)self, @"must is IOQueue");
    NSString *directory = [path stringByDeletingLastPathComponent];
    [YZHUtil checkAndCreateDirectory:directory];
    [data writeToFile:path atomically:NO];
}

-(NSString*)_saveFileNameForFileName:(NSString*)fileName
{
    NSString *key = fileName;
    if (fileName.length >= 256) {
        NSString *ext = [fileName pathExtension];
        key = [[YZHUtil MD5ForText:fileName lowercase:YES] stringByAppendingPathExtension:ext];
    }
    return key;
}


-(void)saveObject:(id)object forFileName:(NSString*)fileName completion:(YZHDiskCacheSaveCompletionBlock)completion
{
    [self saveObject:object data:nil forFileName:fileName completion:completion];
}

-(void)saveObject:(id)object data:(NSData*)data forFileName:(NSString*)fileName completion:(YZHDiskCacheSaveCompletionBlock)completion
{
    NSString *key = [self _saveFileNameForFileName:fileName];
    NSString *path = [self.fullPath stringByAppendingPathComponent:key];
    
    dispatch_async(self.IOQueue, ^{
        NSData *encodeData = data;
        if (encodeData == nil) {
            //encode
            if ([object conformsToProtocol:@protocol(YZHDiskCacheObjectCodingProtocol)]) {
                id<YZHDiskCacheObjectCodingProtocol> tmp = object;
                if (tmp.encodeBlock) {
                    encodeData = tmp.encodeBlock(self, tmp);
                }
            }
            else if ([object conformsToProtocol:@protocol(NSCoding)]) {
                encodeData = [YZHUtil encodeObject:object forKey:key];
            }
        }
        
        [self _writeData:encodeData toPath:path];
        
        if (self.syncDoCompletion) {
            if (completion) {
                completion(self,object);
            }
        }
        else {
            dispatch_async(self.completionQueue, ^{
                if (completion) {
                    completion(self,object);
                }
            });
        }
    });
}

-(void)moveItemAtPath:(NSString*)path toPath:(NSString*)toPath
{
    dispatch_async(self.IOQueue, ^{
        [[NSFileManager defaultManager] moveItemAtURL:NSURL_FROM_FILE_PATH(path) toURL:NSURL_FROM_FILE_PATH(toPath) error:NULL];
    });
}

//可以cancel
-(NSOperation*)loadObjectForFileName:(NSString*)fileName decode:(YZHDiskCacheDecodeBlock)decode completion:(YZHDiskCacheLoadCompletionBlock)completion
{
    NSString *key = [self _saveFileNameForFileName:fileName];
    NSString *path = [self.fullPath stringByAppendingPathComponent:key];

    NSOperation *operation = [NSOperation new];
    dispatch_async(self.IOQueue, ^{
        if (operation.isCancelled) {
            return ;
        }
        NSData *data = [NSData dataWithContentsOfFile:path];
        //decode
        id object = nil;
        if (decode ) {
            object = decode(self, data);
        }
        if (object == nil) {
            object = [YZHUtil decodeObjectForData:data forKey:key];
        }
        
        if (self.syncDoCompletion) {
            if (completion) {
                completion(self, data, object);
            }
        }
        else {
            dispatch_async(self.completionQueue, ^{
                if (operation.isCancelled) {
                    return;
                }
                if (completion) {
                    completion(self, data, object);
                }
            });
        }
    });
    
    return operation;
}

-(NSOperation*)removeObjectForFileName:(NSString*)fileName completion:(YZHDiskCacheRemoveCompletionBlock)completion
{
    NSString *key = [self _saveFileNameForFileName:fileName];
    NSString *path = [self.fullPath stringByAppendingPathComponent:key];
    
    NSOperation *operation = [NSOperation new];
    dispatch_async(self.IOQueue, ^{
        if (operation.isCancelled) {
            return ;
        }
        if ([YZHUtil checkFileExistsAtPath:path]) {
            [YZHUtil removeFileItemAtPath:path];
        }
        if (self.syncDoCompletion) {
            if (completion) {
                completion(self, path);
            }
        }
        else {
            dispatch_async(self.completionQueue, ^{
                if (completion) {
                    completion(self, path);
                }
            });
        }
    });
    return operation;
}

@end
