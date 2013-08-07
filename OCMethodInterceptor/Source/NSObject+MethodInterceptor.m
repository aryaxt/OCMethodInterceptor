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

bool performCallWithMethodInterceptorInfo(MethodInterceptorInfo *info, id self, SEL _cmd)
{
	SEL originalSelector = NSSelectorFromString(getSelectorName(_cmd, [self class], false));
	
	if (!info)
	{
		return false;
	}
	
	switch (info.blockExecutionType)
	{
		case BlockExecutionTypeOverrideOriginalCall:
			info.completionBlock(self);
			return true;
			
		case BlockExecutionTypeAfterOriginalCall:
			objc_msgSend(self, originalSelector);
			info.completionBlock(self);
			return true;
			
		case BlockExecutionTypeBeforeOriginalCall:
			info.completionBlock(self);
			objc_msgSend(self, originalSelector);
			return true;
			
		default:
			return false;
	}
}

void swizzledMethod(id self, SEL _cmd)
{
	BOOL madeOriginalCall = NO;
	
	MethodInterceptorInfo *instanceInfo = [methodInterceptorInfoDictionary objectForKey:[NSString stringWithFormat:@"%p", self]];
	madeOriginalCall = performCallWithMethodInterceptorInfo(instanceInfo, self, _cmd);
	
	//MethodInterceptorInfo *globalInfo = [methodInterceptorInfoDictionary objectForKey:NSStringFromClass([self class])];
	//performCallWithMethodInterceptorInfo(globalInfo, self, _cmd);
	
	SEL originalSelector = NSSelectorFromString(getSelectorName(_cmd, [self class], false));
	
	if (!madeOriginalCall)
		objc_msgSend(self, originalSelector);
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