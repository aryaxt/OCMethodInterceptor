//
//  Car.m
//  MethodInterceptor
//
//  Created by Aryan Gh on 8/5/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "Car.h"

@implementation Car

- (NSString *)startEngine
{
	return [self.engine startEngine];
}

- (void)stopEngine
{
	[self.engine stopEngine];
}

@end
