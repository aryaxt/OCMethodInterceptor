//
//  OCMethodInterceptorTests.m
//  OCMethodInterceptorTests
//
//  Created by Aryan Gh on 8/5/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "OCMethodInterceptorTests.h"

@implementation OCMethodInterceptorTests

#pragma mark - Setup & TearDown -

- (void)setUp
{
    [super setUp];
    
	self.car = [[Car alloc] init];
	[self resetEngineMock];
}

- (void)tearDown
{
    self.car = nil;
	self.engine = nil;
    
    [super tearDown];
}

#pragma mark - Tests -

- (void)testBlockShouldGetCalledForBlockExecutionTypeAfterOriginalCall
{
	__block BOOL blockGotcalled = NO;
	
	[self.car interceptMethod:@selector(startEngine) withExecuteBlock:^(id instance){
		blockGotcalled = YES;
	}andExecutionType:BlockExecutionTypeAfterOriginalCall];
	
	[self.car startEngine];
	STAssertTrue(blockGotcalled, @"block didnt get called");
}

- (void)testBlockShouldGetCalledForBlockExecutionTypeBeforeOriginalCall
{
	__block BOOL blockGotcalled = NO;
	
	[self.car interceptMethod:@selector(startEngine) withExecuteBlock:^(id instance){
		blockGotcalled = YES;
	}andExecutionType:BlockExecutionTypeBeforeOriginalCall];
	
	[self.car startEngine];
	STAssertTrue(blockGotcalled, @"block didnt get called");
}

- (void)testBlockShouldGetCalledForBlockExecutionTypeOverrideOriginalCall
{
	__block BOOL blockGotcalled = NO;
	
	[self.car interceptMethod:@selector(startEngine) withExecuteBlock:^(id instance){
		blockGotcalled = YES;
	}andExecutionType:BlockExecutionTypeOverrideOriginalCall];
	
	[self.car startEngine];
	STAssertTrue(blockGotcalled, @"block didnt get called");
}

- (void)testBlockShouldGetCalledBeforeOriginalCall
{
	[[self.engine reject] stopEngine];
	
	[self.car interceptMethod:@selector(stopEngine) withExecuteBlock:^(id instance){
		// Verify that it didnt get called before block
		[self.engine verify];
		[self resetEngineMock];
		
		// we expect this call after this block
		[[self.engine expect] stopEngine];
	}andExecutionType:BlockExecutionTypeBeforeOriginalCall];
	
	[self.car stopEngine];
	
	// This should get called after block is executed
	[self.engine verify];
}

- (void)testBlockShouldGetCalledAfterOriginalCall
{
	[[self.engine expect] stopEngine];
	
	[self.car interceptMethod:@selector(stopEngine) withExecuteBlock:^(id instance){
		// Verify that it didnt get called before block
		[self.engine verify];
	}andExecutionType:BlockExecutionTypeAfterOriginalCall];
	
	[self.car stopEngine];
	[self.engine verify];
}

- (void)testOriginalCallShouldBeAvoided
{
	[[self.engine reject] stopEngine];
	
	[self.car interceptMethod:@selector(stopEngine) withExecuteBlock:^(id instance){
		// Verify that it didnt get called before block
		[self.engine verify];
	}andExecutionType:BlockExecutionTypeOverrideOriginalCall];
	
	[self.car stopEngine];
	[self.engine verify];
}

#pragma mark - Helpers -

- (void)resetEngineMock
{
	self.engine = [OCMockObject niceMockForClass:[Engine class]];
	self.car.engine = (Engine *)self.engine;
}

@end
