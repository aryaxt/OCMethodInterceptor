//
//  NSObject+MethodInterceptor.h
//  MethodInterceptor
//
//  Created by Aryan Gh on 8/5/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef void (^InstanceMethodInterceptorCompletion)(id instance);

typedef enum {
	BlockExecutionTypeOverrideOriginalCall = 1,
	BlockExecutionTypeAfterOriginalCall = 2,
	BlockExecutionTypeBeforeOriginalCall = 3
}BlockExecutionType;

@interface NSObject (MethodInterceptor)

- (void)interceptMethod:(SEL)selector withExecuteBlock:(InstanceMethodInterceptorCompletion)block andExecutionType:(BlockExecutionType)executionType;
+ (void)interceptAllMethod:(SEL)selector withExecuteBlock:(InstanceMethodInterceptorCompletion)block andExecutionType:(BlockExecutionType)executionType;

@end

@interface MethodInterceptorInfo : NSObject
@property (nonatomic, strong) InstanceMethodInterceptorCompletion completionBlock;
@property (nonatomic, assign) BlockExecutionType blockExecutionType;
@end

