//
//  NSObject+KVO.h
//  01_KVO实现原理
//
//  Created by 莫晓卉 on 2018/4/16.
//  Copyright © 2018年 莫晓卉. All rights reserved.
//

#import <Foundation/Foundation.h>

// 1. 定义观察回调block(观察者, 观察键值, 旧值, 新值)
typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);

@interface NSObject (KVO)

// 2. 声明添加观察者方法(观察者, 观察键值, block)
- (void)mm_addObserver:(NSObject *)observer
                forKey:(NSString *)key
             withBlock:(MMObservingBlock)block;

// 3. 声明删除观察者方法(观察者, 观察键值)
- (void)mm_removeObserver:(NSObject *)observer forKey:(NSString *)key;

@end
