# KVOImplementation
KVO的实现
实现步骤如下:
1. 定义观察回调block(观察者, 观察键值, 旧值, 新值)
2. 声明添加观察者方法(观察者, 观察键值, block)
3. 声明删除观察者方法(观察者, 观察键值)
4. 创建观察model: 观察者, 观察键值, block
5. 实现添加观察者方法:
  1> 获取系统自动生成的setter方法(没有则抛出异常)\n
  2> 获取当前类和类名\n
  3> 创建子类 "MMKVOClassPrefix_(className)", 实现class方法, 向runtime注册该类\n
  4> 为之类实现setter方法 (动态绑定)\n
    1) 获取oldValue\n
    2) 调用父类的setter方法 对属性赋值\n
    3) 遍历观测者数组\n
    4) 找到与observer和key对应的model\n
    5) 调用其block, 传入(self, getterName, oldValue, newValue)\n
  5> 创建观察model, 存入observer key block\n
  6> 获取self的关联属性observers数组, 并将新model加入\n
6. 实现移除观察者方法:\n
  1> 获取self的关联属性observers数组\n
  2> 找到与observer和key对应的model, remove\n
