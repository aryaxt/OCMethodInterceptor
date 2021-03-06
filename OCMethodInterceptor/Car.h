//
//  Car.h
//  MethodInterceptor
//
//  Created by Aryan Gh on 8/5/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Engine.h"

@interface Car : NSObject

@property (nonatomic, strong) Engine *engine;

- (NSString *)startEngine;
- (void)stopEngine;

@end
