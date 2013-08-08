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

void perform_objc_msgSend(id self, SEL _cmd, id *result)
{
	char returnType[1];
	Method originalMethod = class_getInstanceMethod([self class], _cmd);
	method_getReturnType(originalMethod, returnType, 1);
	
	if (returnType[0] == 'v')
		objc_msgSend(self, _cmd);
	else
		*result = objc_msgSend(self, _cmd);
}

id swizzledMethod(id self, SEL _cmd)
{
	id originalMethodResult;
	SEL originalSelector = NSSelectorFromString(getSelectorName(_cmd, [self class], false));
	MethodInterceptorInfo *instanceInfo = [methodInterceptorInfoDictionary objectForKey:[NSString stringWithFormat:@"%p", self]];
	
	BOOL isVoidMethod = NO;
	Method originalMethod = class_getInstanceMethod([self class], _cmd);
	char returnType[1];
	method_getReturnType(originalMethod, returnType, 1);
	
	if (returnType[0] == 'v')
		isVoidMethod = YES;
		
	if (instanceInfo)
	{
		switch (instanceInfo.blockExecutionType)
		{
			case BlockExecutionTypeOverrideOriginalCall:
				instanceInfo.completionBlock(self);
				break;
				
			case BlockExecutionTypeAfterOriginalCall:
				perform_objc_msgSend(self, originalSelector, &originalMethodResult);
				instanceInfo.completionBlock(self);
				break;
				
			case BlockExecutionTypeBeforeOriginalCall:
				instanceInfo.completionBlock(self);
				perform_objc_msgSend(self, originalSelector, &originalMethodResult);
				break;
				
			default:
				break;
		}
	}
	else
	{
		perform_objc_msgSend(self, originalSelector, &originalMethodResult);
	}
	
	return originalMethodResult;
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
		Method originalMethod = class_getInstanceMethod([self class], selector);
		class_addMethod([self class], originalSelector, implementation, method_getTypeEncoding(originalMethod));
		
		class_addMethod([self class], mockSelector, (IMP)swizzledMethod, "v@:@");
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
