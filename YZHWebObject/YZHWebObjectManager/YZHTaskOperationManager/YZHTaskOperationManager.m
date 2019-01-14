//
//  YZHTaskOperationManager.m
//  YZHURLSessionTaskOperation
//
//  Created by yuan on 2019/1/7.
//  Copyright © 2019年 yuan. All rights reserved.
//

#import "YZHTaskOperationManager.h"
#import "YZHTaskOperation.h"

@interface YZHTaskOperationManager ()

@property (nonatomic, strong) dispatch_semaphore_t lock;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@property (nonatomic, weak) YZHTaskOperation *lastTaskOperation;

@property (nonatomic, strong) NSMapTable<id,YZHTaskOperation*> *taskOperationMapTable;

@end

@implementation YZHTaskOperationManager


-(instancetype)initWithExecutionOrder:(YZHTaskOperationExecutionOrder)executionOrder
{
    self = [super init];
    if (self) {
        [self _setupDefault];
        _executionOrder = executionOrder;
    }
    return self;
}

-(void)_setupDefault
{
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.maxConcurrentOperationCount = 1;
    self.lock = dispatch_semaphore_create(1);
}

-(NSMapTable<id,YZHTaskOperation*>*)taskOperationMapTable
{
    if (_taskOperationMapTable == nil) {
        _taskOperationMapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory];
    }
    return _taskOperationMapTable;
}

-(YZHTaskOperation*)_firstLIFOTaskOperation
{
    if (self.executionOrder != self.executionOrder == YZHTaskOperationExecutionOrderLIFO) {
        return nil;
    }
    YZHTaskOperation *firstLIFOTaskOperation = [[YZHTaskOperation alloc] init];
    firstLIFOTaskOperation.key = @"helloFirstNull";
    firstLIFOTaskOperation.startBlock = ^(YZHTaskOperation *taskOperation) {
        [taskOperation finishExecuting];
    };
    [self.operationQueue addOperation:firstLIFOTaskOperation];
    return firstLIFOTaskOperation;
}


-(void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount
{
    _maxConcurrentOperationCount = maxConcurrentOperationCount;
    if (self.executionOrder == YZHTaskOperationExecutionOrderNone) {
        self.operationQueue.maxConcurrentOperationCount = maxConcurrentOperationCount;        
    }
}

-(YZHTaskOperation*)addTaskOperation:(YZHTaskOperationBlock)taskBlock completion:(YZHTaskOperationCompletionBlock)completion forKey:(id)key
{
    return [self addTaskOperation:taskBlock completion:completion forKey:key addToQueue:YES];
}

-(YZHTaskOperation*)addTaskOperation:(YZHTaskOperationBlock)taskBlock completion:(YZHTaskOperationCompletionBlock)completion forKey:(id)key addToQueue:(BOOL)addToQueue
{
    YZHTaskOperation *taskOperation = [[YZHTaskOperation alloc] init];
    taskOperation.key = key;
    
    WEAK_SELF(weakSelf);
    taskOperation.startBlock = ^(YZHTaskOperation *taskOperation) {
        NSLog(@"%@-beginStart.operationCnt=%ld,operations=%@",taskOperation.key,self.operationQueue.operationCount,self.operationQueue.operations);
        [weakSelf _willStartAction:key];
        if (taskBlock) {
            taskBlock(weakSelf, taskOperation);
        }
    };
    
    taskOperation.didFinishBlock = ^(YZHTaskOperation *taskOperation) {
        [weakSelf _didFinishAction:key];
        if (completion) {
            completion(weakSelf, taskOperation);
        }
    };
    
    sync_lock(self.lock, ^{
        if (self.executionOrder == YZHTaskOperationExecutionOrderLIFO) {
            YZHTaskOperation *lastTaskOperation = self.lastTaskOperation ? self.lastTaskOperation : [self _firstLIFOTaskOperation];
            [lastTaskOperation addDependency:taskOperation];
        }
        else if (self.executionOrder == YZHTaskOperationExecutionOrderFIFO) {
            if (self.lastTaskOperation) {
                [taskOperation addDependency:self.lastTaskOperation];
            }
        }
        else {
        }
        if (addToQueue) {
            [self.operationQueue addOperation:taskOperation];            
            [self.taskOperationMapTable setObject:taskOperation forKey:key];
        }
        self.lastTaskOperation = taskOperation;
    });
    
    return taskOperation;
}

-(YZHTaskOperation*)taskOperationForKey:(id)key
{
    __block YZHTaskOperation *taskOperation = nil;
    sync_lock(self.lock, ^{
        taskOperation = [self.taskOperationMapTable objectForKey:key];
    });
    return taskOperation;
}

-(void)addTaskOperationIntoQueue:(YZHTaskOperation*)taskOperation forKey:(id)key
{
    sync_lock(self.lock, ^{
        taskOperation.key = key;
        [self.operationQueue addOperation:taskOperation];
        [self.taskOperationMapTable setObject:taskOperation forKey:key];
    });
}

-(void)cancelTaskOperationForKey:(id)key
{
    YZHTaskOperation *taskOperation = [self.taskOperationMapTable objectForKey:key];
    [taskOperation cancel];
}

-(void)printAllTaskOparations
{
    NSLog(@"allINQueus=%@,cnt=%ld",self.operationQueue.operations,self.operationQueue.operationCount);
}

#pragma mark private
-(void)_willStartAction:(id)key
{
}

-(void)_didFinishAction:(id)key
{
    sync_lock(self.lock, ^{
        NSLog(@"%@-didFinish.operationCnt=%ld,operations=%@",key,self.operationQueue.operationCount,self.operationQueue.operations);
        
        [self.taskOperationMapTable removeObjectForKey:key];
    });
}

@end
