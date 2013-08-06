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

NSString* getSelectorName(SEL selector, id classOrInstance, bool isMock, bool isGlobal)
{
	NSString *isMockString = (isMock) ? @"mock" : @"original";
	NSString *isGlobalString = (isGlobal) ? NSStringFromClass([classOrInstance class]) : [NSString stringWithFormat:@"%p", classOrInstance];
	
	return [NSString stringWithFormat:@"%@-%@-%@", isMockString, isGlobalString, NSStringFromSelector(selector)];
}

void performCallWithMethodInterceptorInfo(MethodInterceptorInfo *info, id self, SEL _cmd)
{
	SEL originalSelector = NSSelectorFromString(getSelectorName(_cmd, self, false, true));
	
	if (!info)
	{
		objc_msgSend(self, originalSelector);
		return;
	}
	
	switch (info.blockExecutionType)
	{
		case BlockExecutionTypeOverrideOriginalCall:
			info.completionBlock(self);
			break;
			
		case BlockExecutionTypeAfterOriginalCall:
			objc_msgSend(self, originalSelector);
			info.completionBlock(self);
			break;
			
		case BlockExecutionTypeBeforeOriginalCall:
			info.completionBlock(self);
			objc_msgSend(self, originalSelector);
			break;
	}
}

void swizzledMethod(id self, SEL _cmd)
{
	MethodInterceptorInfo *globalInfo = [methodInterceptorInfoDictionary objectForKey:getSelectorName(_cmd, self, true, true)];
	performCallWithMethodInterceptorInfo(globalInfo, self, _cmd);
	
	MethodInterceptorInfo *instanceInfo = [methodInterceptorInfoDictionary objectForKey:getSelectorName(_cmd, self, true, false)];
	performCallWithMethodInterceptorInfo(instanceInfo, self, _cmd);
}

- (void)interceptMethod:(SEL)selector withExecuteBlock:(InstanceMethodInterceptorCompletion)block andExecutionType:(BlockExecutionType)executionType
{	
	MethodInterceptorInfo *info = [[MethodInterceptorInfo alloc] init];
    info.completionBlock = block;
	info.blockExecutionType = executionType;
	
	NSString *mockSelectorName = getSelectorName(selector, self, true, false);
	SEL mockSelector = NSSelectorFromString(mockSelectorName);
	
	NSString *originalSelectorName = getSelectorName(selector, self, false, false);
	SEL originalSelector = NSSelectorFromString(originalSelectorName);
	IMP implementation = [self methodForSelector:selector];
	
	if (!methodInterceptorInfoDictionary)
		methodInterceptorInfoDictionary = [NSMutableDictionary dictionary];
	
	[methodInterceptorInfoDictionary setObject:info forKey:mockSelectorName];
	
	if (![self respondsToSelector:originalSelector] && ![self respondsToSelector:mockSelector])
	{
		class_addMethod([self class], mockSelector, (IMP)swizzledMethod, "v@:@");
		class_addMethod([self class], originalSelector, implementation, "v@:@");
		
		Method originalMethod = class_getInstanceMethod([self class], selector);
		Method swizzleMethod = class_getInstanceMethod([self class], mockSelector);
		method_exchangeImplementations(originalMethod, swizzleMethod);
	}
}

+ (void)interceptAllMethod:(SEL)selector withExecuteBlock:(InstanceMethodInterceptorCompletion)block andExecutionType:(BlockExecutionType)executionType
{
	MethodInterceptorInfo *info = [[MethodInterceptorInfo alloc] init];
    info.completionBlock = block;
	info.blockExecutionType = executionType;
	
	NSString *mockSelectorName = getSelectorName(selector, self, true, true);
	SEL mockSelector = NSSelectorFromString(mockSelectorName);
	
	NSString *originalSelectorName = getSelectorName(selector, self, false, true);
	SEL originalSelector = NSSelectorFromString(originalSelectorName);
	IMP implementation = [self methodForSelector:selector];
	
	if (!methodInterceptorInfoDictionary)
		methodInterceptorInfoDictionary = [NSMutableDictionary dictionary];
	
	[methodInterceptorInfoDictionary setObject:info forKey:mockSelectorName];
	
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
