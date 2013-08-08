OCMethodInterceptor
===================

NSObject category to intercept methods.
Allows intercepting before or after original method calls, or it gives an option to completely override the original call.

Examples
-------------------------
```objective-c
  Car *car = [[Car alloc] init];

  [car interceptMethod:@selector(startEngine) withExecuteBlock:^(id instance){
				NSLog("Intercepted startEngine method");
	}andExecutionType:BlockExecutionTypeBeforeOriginalCall];
  
  [car startEngine];
```
