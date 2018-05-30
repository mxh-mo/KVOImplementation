# KVOImplementation
KVO的实现

>1. 定义观察回调`block`(观察者, 观察键值, 旧值, 新值)<br>
```Objective-C
typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
```
>2. 声明添加观察者方法(观察者, 观察键值, `block`)<br>
```Objective-C
- (void)mm_addObserver:(NSObject *)observer
                forKey:(NSString *)key
             withBlock:(MMObservingBlock)block;
```
>3. 声明删除观察者方法(观察者, 观察键值)<br>
>5. 实现添加观察者方法:<br>
>>1> 获取系统自动生成的`setter`方法(没有则抛出异常)<br>
>>2> 获取当前类和类名<br>
>>3> *创建子类 `"MMKVOClassPrefix_(className)"`, 实现`class`方法, 向`runtime`注册该类<br>

>>4> * 重写子类实现`setter`方法 (实现观察)<br>
>>>1) 获取`oldValue`<br>
>>>2) 调用父类的`setter`方法 对属性赋值<br>
>>>3) 遍历观测者数组<br>
>>>4) 找到与`observer`和`key`对应的`model`<br>
>>>5) 调用其`block`, 传入`(self, getterName, oldValue, newValue)`<br>

>>5> * 创建观察 `model`, 存入`observer key block`<br>
>>6> 获取`self`的关联属性`observers`数组, 并将新`model`加入<br>

>6. 实现移除观察者方法:<br>
>>1> 获取`self`的关联属性`observers`数组<br>
>>2> 找到与`observer`和`key`对应的`model`, `remove`<br>


>>3> 创建子类 `"MMKVOClassPrefix_(className)"`, 实现`class`方法, 向`runtime`注册该类<br>
```Objective-C
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
```
>>5> * 创建观察 `model`, 存入`observer key block`<br>
添加观察者时 为子类动态绑定观察者数组
```Objective-C
// 5> 创建观察model, 存入observer key block
MMObserverInfoModel *info = [[MMObserverInfoModel alloc] initWithObserver:observer Key:key block:block];
// 6> 获取self的关联属性observers数组, 并将新model加入

NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kMMKVOAssociatedObservers));
if (!observers) {
    observers = [NSMutableArray array];
    objc_setAssociatedObject(self, (__bridge const void *)(kMMKVOAssociatedObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
[observers addObject:info];
```
>>4> * 重写子类实现`setter`方法 (实现观察)<br>
子类重写'setter'方法, 从观察者数组中找到观察该属性观察者, 调用其观察block
```Objective-C
#pragma mark - Overridden Methods
static void kvo_setter(id self, SEL _cmd, id newValue) {
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterForSetter(setterName);
    
    // 1) 获取oldValue
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superclazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    
    // 2) 调用父类的setter方法 对属性赋值
    objc_msgSendSuperCasted(&superclazz, _cmd, newValue);
    
    // 3) 遍历观测者数组
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kMMKVOAssociatedObservers));
    for (MMObserverInfoModel *each in observers) {
        // 4) 找到与observer和key对应的model
        if ([each.key isEqualToString:getterName]) {
            // 5) 调用其block, 传入(self, getterName, oldValue, newValue)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                each.block(self, getterName, oldValue, newValue);
            });
        }
    }
}
```
