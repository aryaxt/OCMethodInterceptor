//
//  OCMethodInterceptorTests.h
//  OCMethodInterceptorTests
//
//  Created by Aryan Gh on 8/5/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "NSObject+MethodInterceptor.h"
#import "OCMock.h"
#import "Car.h"

@interface OCMethodInterceptorTests : SenTestCase

@property (nonatomic, strong) Car *car;
@property (nonatomic, strong) OCMockObject *engine;

@end
