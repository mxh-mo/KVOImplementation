# KVOImplementation
KVO的实现

 >1. 定义观察回调`block`(观察者, 观察键值, 旧值, 新值)<br>
 ```Objective-C
 typedef void(^MMObservingBlock)(id observer, NSString *observedKey, id oldValue, id newValue);
 ```
 >2. 声明添加观察者方法(观察者, 观察键值, `block`)<br>
 >3. 声明删除观察者方法(观察者, 观察键值)<br>
 >4. 创建观察`model`: 观察者, 观察键值, `block`<br>
 >5. 实现添加观察者方法:<br>
 >>1> 获取系统自动生成的`setter`方法(没有则抛出异常)<br>
 >>2> 获取当前类和类名<br>
 >>3> 创建子类 `"MMKVOClassPrefix_(className)"`, 实现`class`方法, 向`runtime`注册该类<br>
 >>4> 为之类实现`setter`方法 (动态绑定)<br>
 >>>1) 获取`oldValue`<br>
 >>>2) 调用父类的`setter`方法 对属性赋值<br>
 >>>3) 遍历观测者数组<br>
 >>>4) 找到与`observer`和`key`对应的`model`<br>
 >>>5) 调用其`block`, 传入`(self, getterName, oldValue, newValue)`<br>
 >>5> 创建观察 `model`, 存入`observer key block`<br>
 >>6> 获取`self`的关联属性`observers`数组, 并将新`model`加入<br>
 >6. 实现移除观察者方法:<br>
 >>1> 获取`self`的关联属性`observers`数组<br>
 >>2> 找到与`observer`和`key`对应的`model`, `remove`<br>
