//
//  YZHAsyncQueue.h
//  contact
//
//  Created by yuan on 2019/1/11.
//  Copyright © 2019年 gdtech. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YZHAsyncQueue;
typedef id(^YZHAsyncQueueExecuteBlock)(YZHAsyncQueue *asyncQueue);
typedef void(^YZHAsyncQueueExecuteCompletionBlock)(YZHAsyncQueue *asyncQueue,id result);

@interface YZHAsyncQueue : NSObject
{
    //设计为允许继承类来修改，其他不允许
@protected
    dispatch_queue_t _asyncTaskQueue;
}

-(void)addAsyncExecute:(YZHAsyncQueueExecuteBlock)executeBlock asyncCompletion:(BOOL)asyncCompletion completionBlock:(YZHAsyncQueueExecuteCompletionBlock)completionBlock;

-(BOOL)isInAsyncQueue;

@end
