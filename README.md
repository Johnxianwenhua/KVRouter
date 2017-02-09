# KVRouter
这是一个灵活的界面跳转路由，提供多种API，方便定制。

#### 1，与其他路由一样，使用url的形式实现界面跳转；
#### 2，在耦合性不高的界面之间不需要引入头文件即可完成界面跳转；
#### 3，针对传参进行了优化，不仅可以解析url的自带参数，还可以使用API向下传参；
#### 4，使用回调将创建完成后的界面回调回第一个界面，方便设置代理；
#### 5，界面跳转的API设计灵活度高，使用者可以直接使用，另外也可以在代码内部的提示部位进行自定制；
#### 6，获取参数的方法相对于其他路由更加简单，只需要在界面内部重写一个方法即可；
#### 7，使用配置文件进行url注册，对于项目的改动很小，不需要每个界面都去注册url，另外，对于某些自定义程度高的界面也可以主动代码注册，自定义创建界面。
#### 8，对于没有在配置文件中注册的界面，也可以通过API进行动态注册

### 使用方法
首先需要在提供的配置文件中进行界面注册，使用者也可以根据自己的项目对配置文件以及解析方式进行修改。


![配置文件](https://raw.githubusercontent.com/kevin930119/KVRouter/master/peizhiwenjian.png)

简单使用
```
[KVRouter openUrl:@"main/three"]; //将会使用内部默认形式推出界面
```
向下方界面传参
```
//可以在链接里面传参，也可以在参数里面传参，在这里链接加上了项目scheme，如果不加也是可以的
NSString * url = @"kv://main/one?userid=12345";
NSDictionary * parameter = @{@"id" : @"gsjdfgjhsgdhfjg"};
[KVRouter openUrl:url parameter:parameter];
```
在下方界面接收参数，只需要重写一个方法，即可完成参数接收
```
//传递过来的参数，以字典的形式，使用者不需要做其他操作，只需要在需要接收参数的地方重写这个方法即可接收到传参
- (void)router:(KVRouter *)router getParameter:(NSDictionary *)parameter {
    NSLog(@"%@", parameter);
}
```
也可以使用回调进行代理等操作
```
//可以在链接里面传参，也可以在参数里面传参，在这里链接加上了项目scheme，如果不加也是可以的
NSString * url = @"kv://main/one?userid=12345";
NSDictionary * parameter = @{@"id" : @"gsjdfgjhsgdhfjg"};
//使用默认形式推出控制器
__weak __typeof(&*self)weakSelf = self; //这里的弱引用可以使用宏定义来快速创建
/*
#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self
*/
[KVRouter openUrl:url parameter:parameter complete:^(UIViewController *object) {
    ((OneController*)object).delegate = weakSelf;
 }];
```
