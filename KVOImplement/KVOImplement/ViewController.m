//
//  ViewController.m
//  KVOImplement
//
//  Created by 莫晓卉 on 2018/4/22.
//  Copyright © 2018年 莫晓卉. All rights reserved.
//
// 1. 定义观察回调block(观察者, 观察键值, 旧值, 新值)
// 2. 声明添加观察者方法(观察者, 观察键值, block)
// 3. 声明删除观察者方法(观察者, 观察键值)
// 4. 创建观察model: 观察者, 观察键值, block
// 5. 实现添加观察者方法:
    //1> 获取系统自动生成的setter方法(没有则抛出异常)
    //2> 获取当前类和类名
    //3> 创建子类 "MMKVOClassPrefix_(className)", 实现class方法, 向runtime注册该类
    //4> 为之类实现setter方法 (动态绑定)
        // 1) 获取oldValue
        // 2) 调用父类的setter方法 对属性赋值
        // 3) 遍历观测者数组
        // 4) 找到与observer和key对应的model
        // 5) 调用其block, 传入(self, getterName, oldValue, newValue)
    //5> 创建观察model, 存入observer key block
    //6> 获取self的关联属性observers数组, 并将新model加入
// 6. 实现移除观察者方法:
    //1> 获取self的关联属性observers数组
    //2> 找到与observer和key对应的model, remove

#import "ViewController.h"
#import "NSObject+KVO.h"

@interface Message : NSObject
@property (nonatomic, copy) NSString *name;
@end

@implementation Message
@end

@interface ViewController ()
@property (nonatomic, strong) Message *message;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.message = [[Message alloc] init];
    [self.message mm_addObserver:self forKey:@"name" withBlock:^(id observer, NSString *observedKey, id oldValue, id newValue) {
        NSLog(@"old:%@ new:%@", oldValue, newValue);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    static int n = 0;
    self.message.name = [NSString stringWithFormat:@"%d", n++];
}


@end
