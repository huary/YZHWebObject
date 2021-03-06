//
//  UIImage+YZHCoding.m
//  contact
//
//  Created by yuan on 2019/1/14.
//  Copyright © 2019年 gdtech. All rights reserved.
//

#import "UIImage+YZHCoding.h"
#import <objc/runtime.h>

@implementation UIImage (YZHCoding)

-(void)setEncodeBlock:(YZHDiskCacheEncodeBlock)encodeBlock
{
    objc_setAssociatedObject(self, @selector(encodeBlock), encodeBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(YZHDiskCacheEncodeBlock)encodeBlock
{
    YZHDiskCacheEncodeBlock encode = objc_getAssociatedObject(self, _cmd);
    if (encode == nil) {
        encode = ^NSData*(YZHDiskCache *cache, id object) {
            if (object) {
                return UIImagePNGRepresentation(object);
            }
            return nil;
        };
        self.encodeBlock = encode;
    }
    return encode;
}

//-(void)setDecodeBlock:(YZHDiskCacheDecodeBlock)decodeBlock
//{
//    objc_setAssociatedObject(self, @selector(decodeBlock), decodeBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
//}
//
//-(YZHDiskCacheDecodeBlock)decodeBlock
//{
//    YZHDiskCacheDecodeBlock decode = objc_getAssociatedObject(self, _cmd);
//    if (decode) {
//        decode = ^id(YZHDiskCache *cache, NSData *data) {
//            return data;
//        };
//        self.decodeBlock = decode;
//    }
//    return decode;
//}


@end
