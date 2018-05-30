//
//  NSObject+KVO.m
//  01_KVO实现原理
//
//  Created by 莫晓卉 on 2018/4/16.
//  Copyright © 2018年 莫晓卉. All rights reserved.
//

#import "NSObject+KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString *const kMMKVOClassPrefix = @"MMKVOClassPrefix_";
NSString *const kMMKVOAssociatedObservers = @"MMKVOAssociatedObservers";

// 4. 创建观察model: 观察者, 观察键值, block
#pragma mark - MMObservationInfo
@interface MMObserverInfoModel : NSObject
@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) MMObservingBlock block;
@end

@implementation MMObserverInfoModel
- (instancetype)initWithObserver:(NSObject *)observer Key:(NSString *)key block:(MMObservingBlock)block {
    self = [super init];
    if (self) {
        _observer = observer;
        _key = key;
        _block = block;
    }
    return self;
}
@end

@implementation NSObject (KVO)

// 5. 实现添加观察者方法:
- (void)mm_addObserver:(NSObject *)observer
                forKey:(NSString *)key
             withBlock:(MMObservingBlock)block {
    // 1> 获取系统自动生成的setter方法
    SEL setterSelector = NSSelectorFromString(setterForGetter(key));
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if (!setterMethod) {
        // 没有相应的 setter 方法。如果没有抛出异常；
    }
    // 2> 获取当前类和类名
    Class clazz = object_getClass(self);
    NSString *clazzName = NSStringFromClass(clazz);
    
    //3> 创建子类 "MMKVOClassPrefix_(className)", 实现class方法, 向runtime注册该类
    if (![clazzName hasPrefix:kMMKVOClassPrefix]) {
        clazz = [self makeKvoClassWithOriginalClassName:clazzName];
        object_setClass(self, clazz);   // 将self设置为 MMKVOClassPrefix_NSObject 类 !!!
    }
    //4> 为子类实现setter方法 (动态绑定)
    if (![self hasSelector:setterSelector]) {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(clazz, setterSelector, (IMP)kvo_setter, types);
    }
    
    
    // 5> 创建观察model, 存入observer key block
    MMObserverInfoModel *info = [[MMObserverInfoModel alloc] initWithObserver:observer Key:key block:block];
    // 6> 获取self的关联属性observers数组, 并将新model加入
    
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kMMKVOAssociatedObservers));
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void *)(kMMKVOAssociatedObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
}

#pragma mark - 移除观察者
// 6. 实现移除观察者方法:
// 1> 获取self的关联属性observers数组
// 2> 找到与observer和key对应的model, remove
- (void)mm_removeObserver:(NSObject *)observer forKey:(NSString *)key {
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kMMKVOAssociatedObservers));
    
    MMObserverInfoModel *infoToRemove;
    for (MMObserverInfoModel *info in observers) {
        if (info.observer == observer && [info.key isEqual:key]) {
            infoToRemove = info;
            break;
        }
    }
    [observers removeObject:infoToRemove];
}

#pragma mark - Overridden Methods
static void kvo_setter(id self, SEL _cmd, id newValue) {
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterForSetter(setterName);
    
    if (!getterName) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have setter %@", self, setterName];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    // 1) 获取oldValue
    id oldValue = [self valueForKey:getterName];
  
    // 2) 调用父类的setter方法 对属性赋值
    struct objc_super superclazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    // cast our pointer so the compiler won't complain
    // 在 Xcode 6 里，新的 LLVM 会对 objc_msgSendSuper 以及 objc_msgSend 做严格的类型检查，如果不做类型转换。Xcode 会抱怨有 too many arguments 的错误。
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    
    // call super's setter, which is original class's setter method
    objc_msgSendSuperCasted(&superclazz, _cmd, newValue);
    
    // look up observers and call the blocks
    // 3) 遍历观测者数组
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kMMKVOAssociatedObservers));
    for (MMObserverInfoModel *observer in observers) {
        // 4) 找到与observer和key对应的model
        if ([observer.key isEqualToString:getterName]) {
            // 5) 调用其block, 传入(self, getterName, oldValue, newValue)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                observer.block(observer.observer, getterName, oldValue, newValue);
            });
        }
    }
}

#pragma mark - 创建 "MMKVOClassPrefix_(className)" 子类
- (Class)makeKvoClassWithOriginalClassName:(NSString *)originalClazzName {
    NSString *kvoClazzName = [kMMKVOClassPrefix stringByAppendingString:originalClazzName];
    Class clazz = NSClassFromString(kvoClazzName);
    
    if (clazz) {
        return clazz;
    }
    
    // 动态创建新类 objc_allocateClassPair(父类, 类名)
    Class originalClazz = object_getClass(self);
    Class kvoClazz = objc_allocateClassPair(originalClazz, kvoClazzName.UTF8String, 0);
    
    // 获取class方法
    Method clazzMethod = class_getInstanceMethod(originalClazz, @selector(class));
    const char *types = method_getTypeEncoding(clazzMethod);
    
    // 为新类添加class方法
    class_addMethod(kvoClazz, @selector(class), (IMP)kvo_class, types);
    
    objc_registerClassPair(kvoClazz);   // 向runtime注册个类
    
    return kvoClazz;
}

static Class kvo_class(id self, SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}

#pragma mark - 该类是否实现了该方法
- (BOOL)hasSelector:(SEL)selector {
    Class clazz = object_getClass(self);
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(clazz, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector) {
            free(methodList);
            return YES;
        }
    }
    
    free(methodList);
    return NO;
}

#pragma mark - 生成setter方法名
static NSString *setterForGetter(NSString *getter) {
    if (getter.length <= 0) {
        return nil;
    }
    
    // upper case the first letter
    NSString *firstLetter = [[getter substringToIndex:1] uppercaseString];
    NSString *remainingLetters = [getter substringFromIndex:1];
    
    // add 'set' at the begining and ':' at the end
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", firstLetter, remainingLetters];
    
    return setter;
}

#pragma mark - 根据getter方法名 获取属性名
static NSString *getterForSetter(NSString *setter) {
    if (setter.length <=0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    
    // remove 'set' at the begining and ':' at the end
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    
    // lower case the first letter
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                       withString:firstLetter];
    return key;
}


@end
