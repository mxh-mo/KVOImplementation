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
  ```Objective-C
 - (void)mm_removeObserver:(NSObject *)observer forKey:(NSString *)key;
 ```
 >4. 创建观察`model`: 观察者, 观察键值, `block`<br>
 ```Objective-C
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
 ```
 >5. 实现添加观察者方法:<br>
 ```Objective-C
 - (void)mm_addObserver:(NSObject *)observer
                forKey:(NSString *)key
             withBlock:(MMObservingBlock)block {
             // ....
 }
 ```
 >>1> 获取系统自动生成的`setter`方法(没有则抛出异常)<br>
  ```Objective-C
  SEL setterSelector = NSSelectorFromString(setterForGetter(key));
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if (!setterMethod) {
        // 没有相应的 setter 方法。如果没有抛出异常；
    }
  ```
 >>2> 获取当前类和类名<br>
  ```Objective-C
  Class clazz = object_getClass(self);
    NSString *clazzName = NSStringFromClass(clazz);
  ```
 >>3> 创建子类 `"MMKVOClassPrefix_(className)"`, 实现`class`方法, 向`runtime`注册该类<br>
  ```Objective-C
  if (![clazzName hasPrefix:kMMKVOClassPrefix]) {
        clazz = [self makeKvoClassWithOriginalClassName:clazzName];
        object_setClass(self, clazz);   // 将self设置为 MMKVOClassPrefix_NSObject 类 !!!
    }
  ```
 >>4> 为之类实现`setter`方法 (动态绑定)<br>
  ```Objective-C
  if (![self hasSelector:setterSelector]) {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(clazz, setterSelector, (IMP)kvo_setter, types);
    }
  ```
 >>>1) 获取`oldValue`<br>
  ```Objective-C
 typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
 ```
 >>>2) 调用父类的`setter`方法 对属性赋值<br>
  ```Objective-C
 typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
 ```
 >>>3) 遍历观测者数组<br>
  ```Objective-C
 typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
 ```
 >>>4) 找到与`observer`和`key`对应的`model`<br>
  ```Objective-C
 typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
 ```
 >>>5) 调用其`block`, 传入`(self, getterName, oldValue, newValue)`<br>
  ```Objective-C
 typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
 ```
 >>5> 创建观察 `model`, 存入`observer key block`<br>
  ```Objective-C
 typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
 ```
 >>6> 获取`self`的关联属性`observers`数组, 并将新`model`加入<br>
  ```Objective-C
 typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
 ```
 >6. 实现移除观察者方法:<br>
  ```Objective-C
 typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
 ```
 >>1> 获取`self`的关联属性`observers`数组<br>
  ```Objective-C
 typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
 ```
 >>2> 找到与`observer`和`key`对应的`model`, `remove`<br>
  ```Objective-C
 typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
 ```
