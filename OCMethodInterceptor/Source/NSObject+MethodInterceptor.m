//
//  NSObject+MethodInterceptor.m
//  MethodInterceptor
//
//  Created by Aryan Gh on 8/5/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "NSObject+MethodInterceptor.h"

@implementation MethodInterceptorInfo
@end

@implementation NSObject (MethodInterceptor)

static NSMutableDictionary *methodInterceptorInfoDictionary;

NSString* getSelectorName(SEL selector, Class class, bool isMock)
{
	NSString *isMockString = (isMock) ? @"mock" : @"original";
	
	return [NSString stringWithFormat:@"%@-%@-%@", isMockString, NSStringFromClass(class), NSStringFromSelector(selector)];
}

id swizzledMethod(id self, SEL _cmd)
{
	id methodResult = nil;
	SEL originalSelector = NSSelectorFromString(getSelectorName(_cmd, [self class], false));
	MethodInterceptorInfo *instanceInfo = [methodInterceptorInfoDictionary objectForKey:[NSString stringWithFormat:@"%p", self]];
	
	if (instanceInfo)
	{
		switch (instanceInfo.blockExecutionType)
		{
			case BlockExecutionTypeOverrideOriginalCall:
				instanceInfo.completionBlock(self);
				break;
				
			case BlockExecutionTypeAfterOriginalCall:
				methodResult = objc_msgSend(self, originalSelector);
				instanceInfo.completionBlock(self);
				break;
				
			case BlockExecutionTypeBeforeOriginalCall:
				instanceInfo.completionBlock(self);
				methodResult = objc_msgSend(self, originalSelector);
				break;
				
			default:
				break;
		}
	}
	else
	{
		methodResult = objc_msgSend(self, originalSelector);
	}
	
	return methodResult;
}

- (void)interceptMethod:(SEL)selector withExecuteBlock:(InstanceMethodInterceptorCompletion)block andExecutionType:(BlockExecutionType)executionType
{
	MethodInterceptorInfo *info = [[MethodInterceptorInfo alloc] init];
    info.completionBlock = block;
	info.blockExecutionType = executionType;
	
	NSString *mockSelectorName = getSelectorName(selector, [self class], true);
	SEL mockSelector = NSSelectorFromString(mockSelectorName);
	
	NSString *originalSelectorName = getSelectorName(selector, [self class], false);
	SEL originalSelector = NSSelectorFromString(originalSelectorName);
	IMP implementation = [self methodForSelector:selector];
	
	if (!methodInterceptorInfoDictionary)
		methodInterceptorInfoDictionary = [NSMutableDictionary dictionary];
	
	[methodInterceptorInfoDictionary setObject:info forKey:[NSString stringWithFormat:@"%p", self]];
	
	if (![self respondsToSelector:originalSelector] && ![self respondsToSelector:mockSelector])
	{
		class_addMethod([self class], mockSelector, (IMP)swizzledMethod, "v@:@");
		class_addMethod([self class], originalSelector, implementation, "v@:@");
		
		Method originalMethod = class_getInstanceMethod([self class], selector);
		Method swizzleMethod = class_getInstanceMethod([self class], mockSelector);
		method_exchangeImplementations(originalMethod, swizzleMethod);
	}
}

/*
 // Use this to resuse logic
 class_isMetaClass(object_getClass(class));
 */

+ (void)interceptAllMethod:(SEL)selector withExecuteBlock:(InstanceMethodInterceptorCompletion)block andExecutionType:(BlockExecutionType)executionType
{
	MethodInterceptorInfo *info = [[MethodInterceptorInfo alloc] init];
    info.completionBlock = block;
	info.blockExecutionType = executionType;
	
	NSString *mockSelectorName = getSelectorName(selector, self, true);
	SEL mockSelector = NSSelectorFromString(mockSelectorName);
	
	NSString *originalSelectorName = getSelectorName(selector, self, false);
	SEL originalSelector = NSSelectorFromString(originalSelectorName);
	IMP implementation = [self methodForSelector:selector];
	
	if (!methodInterceptorInfoDictionary)
		methodInterceptorInfoDictionary = [NSMutableDictionary dictionary];
	
	[methodInterceptorInfoDictionary setObject:info forKey:NSStringFromClass(self)];
	
	// If not already swizzled
	if (![self respondsToSelector:originalSelector] && ![self respondsToSelector:mockSelector])
	{
		class_addMethod(self, originalSelector, implementation, "v@:@");
		class_addMethod(self, mockSelector, (IMP)swizzledMethod, "v@:@");
		
		Method originalMethod = class_getInstanceMethod(self, selector);
		Method swizzleMethod = class_getInstanceMethod([self class], mockSelector);
		method_exchangeImplementations(originalMethod, swizzleMethod);
	}
}

@end
