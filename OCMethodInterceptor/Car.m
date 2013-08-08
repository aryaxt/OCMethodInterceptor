//
//  Car.m
//  MethodInterceptor
//
//  Created by Aryan Gh on 8/5/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "Car.h"

@implementation Car

- (NSString *)start
{
	NSLog(@"Car Start");
	return @"YAY";
}

- (void)stop
{
	NSLog(@"Car Stop");
}

@end
