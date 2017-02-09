//
//  KVRouter.h
//  KVRouterTest
//
//  Created by kevin on 2017/2/7.
//  Copyright © 2017年 kevin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 该路由器可以做到项目界面间的充分解耦，不需要像传统做法一样在推出下个界面前需要引入下个界面的头文件，使用该路由器，除非一些必须的耦合（例如使用协议代理），不然不用引入头文件，提供了各种API，灵活度比较高，方便开发，后续将会继续完善，谢谢支持。
 */
#define kvrouter_main_scheme @"kv://"   //项目的协议名称，用于外部APP或者服务器返回的链接标识
/**
 内部创建界面后返回出去的回调，用于外部做一些设置代理以及其他操作

 @param object 回调出去一个界面实例
 */
typedef void(^KVRouterComplete)(UIViewController * object);

/**
 用于弹出界面时返回需要包装的导航控制器

 @param object 创建完成的界面实例
 @return 返回一个外部创建的导航控制器
 */
typedef UINavigationController*(^KVRouterPresentComplete)(UIViewController * object);

/**
 自定义的界面创建回调，用于某些特殊界面的创建方式不是内部默认的init

 @return 返回一个界面实例，可以自定义创建方法，也可以对界面实例进行初步赋值等操作
 */
typedef UIViewController*(^KVRouterCreateBlock)(void);

@interface KVRouter : NSObject

/**
 初始化路由器

 @return 返回路由实例
 */
+ (instancetype)initRouter;

#pragma mark - 注册界面
/**
 注册自定义的界面创建方法，用于某些界面的创建不是通过init的方法进行创建的情况，例如tableViewController等
 注意：这个方法只用于url已经被注册进plist文件中
 
 @param targetClass 注册界面的class
 @param handler 创建回调block，返回一个创建好的界面示例
 */
+ (void)registerClass:(Class)targetClass toHandler:(KVRouterCreateBlock)handler;

/**
 注册自定义的界面创建方法，用于某些界面的创建不是通过init的方法进行创建的情况，例如tableViewController等
 注意：这个方法可用于url没有被注册进plist文件中，如果url没有被注册进plist文件中，会自动将url注册，用于灵活使用路由器，避免在开发中忘记注册的情况，建议提前注册url，避免过多的使用该API去注册url，可以避免过多的注册会影响程序启动时间
 
 @param url 链接url
 @param handler 创建回调block，返回一个创建好的界面示例
 */
+ (void)registerUrl:(NSString*)url toHandler:(KVRouterCreateBlock)handler;

/**
 通过类获取对应的链接url

 @param targetClass 想要查询的class
 @return 返回链接url，没有则返回nil
 */
+ (NSString*)getUrlWithClass:(Class)targetClass;

/**
 通过类名获取对应的链接url

 @param className 想要查询的类的名
 @return 返回链接url，没有则返回nil
 */
+ (NSString*)getUrlWithClassName:(NSString*)className;

#pragma mark - push形式推出界面的方法
/**
 根据url跳转界面（简单跳转，没有参数）push
 默认使用项目中的导航控制器推出

 @param url 链接url
 */
+ (void)openUrl:(NSString*)url;

/**
 根据url跳转界面（简单跳转，没有参数）push
 需要传入一个导航控制器，用于推出

 @param url 链接url
 @param nav 用于推出界面的导航控制器
 */
+ (void)openUrl:(NSString *)url withNavigationController:(UINavigationController*)nav;

/**
 拥有回调的跳转方法

 @param url 链接url
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 */
+ (void)openUrl:(NSString*)url complete:(KVRouterComplete)complete;

/**
 拥有回调的跳转方法

 @param url 链接url
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 @param nav 需要传入一个导航控制器，用于推出
 */
+ (void)openUrl:(NSString*)url complete:(KVRouterComplete)complete withNavigationController:(UINavigationController*)nav;

/**
 可以传参的跳转方法

 @param url 链接url
 @param parameter 需要传递的参数字典
 */
+ (void)openUrl:(NSString*)url parameter:(NSDictionary*)parameter;

/**
 可以传参的跳转方法

 @param url 链接url
 @param parameter 需要传递的参数字典
 @param nav 需要传入一个导航控制器，用于推出
 */
+ (void)openUrl:(NSString*)url parameter:(NSDictionary*)parameter withNavigationController:(UINavigationController*)nav;

/**
 可以传参，并且回调的跳转方法

 @param url 链接url
 @param parameter 需要传递的参数字典
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 */
+ (void)openUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterComplete)complete;

/**
 可以传参，并且回调的跳转方法

 @param url 链接url
 @param parameter 需要传递的参数字典
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 @param nav 需要传入一个导航控制器，用于推出
 */
+ (void)openUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterComplete)complete withNavigationController:(UINavigationController*)nav;

#pragma mark - present形式弹出界面，需要注意，弹出源控制器，可传可不传，不传，默认使用APP的根控制器弹出
/**
 为弹出界面包装一层导航控制器
 一般的项目，这个方法比较常用，一般弹出界面的时候都需要包装一层导航控制器
 说明：如果不传导航控制器，那么使用内部默认的导航控制器进行包装，使用者可以自行修改默认的导航控制器包装代码
 
 @param url 链接url
 @param parameter 需要传递的参数字典
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作，并且需要返回一个导航控制器，如果返回nil或者设置回调为nil，那么使用内部默认导航控制器进行包装
 @param sourceViewController 需要传入一个根控制器，用于弹出，如果传入nil，那么默认使用根控制器弹出
 */
+ (void)presentNavigationWithUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterPresentComplete)complete withSourceViewController:(UIViewController*)sourceViewController;

/**
 根据url跳转界面（简单跳转，没有参数）present

 @param url 链接url
 */
+ (void)presentUrl:(NSString*)url;

/**
 根据url跳转界面（简单跳转，没有参数）present

 @param url 链接url
 @param sourceViewController 需要传入一个根控制器，用于弹出，如果传入nil，那么默认使用根控制器弹出
 */
+ (void)presentUrl:(NSString *)url withSourceViewController:(UIViewController*)sourceViewController;

/**
 拥有回调的跳转方法

 @param url 链接url
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 */
+ (void)presentUrl:(NSString*)url complete:(KVRouterComplete)complete;

/**
 拥有回调的跳转方法

 @param url 链接url
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 @param sourceViewController 需要传入一个根控制器，用于弹出，如果传入nil，那么默认使用根控制器弹出
 */
+ (void)presentUrl:(NSString*)url complete:(KVRouterComplete)complete withSourceViewController:(UIViewController*)sourceViewController;

/**
 可以传参的跳转方法

 @param url 链接url
 @param parameter 需要传递的参数字典
 */
+ (void)presentUrl:(NSString*)url parameter:(NSDictionary*)parameter;

/**
 可以传参的跳转方法

 @param url 链接url
 @param parameter 需要传递的参数字典
 @param sourceViewController 需要传入一个根控制器，用于弹出，如果传入nil，那么默认使用根控制器弹出
 */
+ (void)presentUrl:(NSString*)url parameter:(NSDictionary*)parameter withSourceViewController:(UIViewController*)sourceViewController;

/**
 可以传参，并且回调的跳转方法

 @param url 链接url
 @param parameter 需要传递的参数字典
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 */
+ (void)presentUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterComplete)complete;

/**
 可以传参，并且回调的跳转方法

 @param url 链接url
 @param parameter 需要传递的参数字典
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 @param sourceViewController 需要传入一个根控制器，用于弹出，如果传入nil，那么默认使用根控制器弹出
 */
+ (void)presentUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterComplete)complete withSourceViewController:(UIViewController*)sourceViewController;

/**
 是否可以跳转该url

 @param url 链接url
 @return 返回布尔值
 */
+ (BOOL)canOpenUrl:(NSString*)url;

@end

/**
 *  路由跳转请求
 */

typedef NS_ENUM(NSInteger, KVRouterOpenType) {
    KVRouterPush = 0,    //推出
    KVRouterPresent,    //简单弹出
    KVRouterPresentWithNavgation    //弹出，并且包装一个导航控制器
};

@interface KVRouterRequest : NSObject

@property (nonatomic, copy) NSString * url; //跳转的url
@property (nonatomic, strong) NSDictionary * parameter; //携带参数
@property (nonatomic, copy) KVRouterComplete complete;  //完成回调，将控制器回调出去
@property (nonatomic, copy) KVRouterPresentComplete presentComplete;    //用于返回需要包装的导航控制器
@property (nonatomic, assign) KVRouterOpenType openType;    //界面打开方式
@property (nonatomic, weak) UIViewController * sourceViewController;    //用于推出或者弹出界面的源控制器

+ (instancetype)handleDataWithUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterComplete)complete;

@end

@interface NSObject (KVRouter)

/**
 用于传参的分类方法
 使用方法：
 在控制器内部重写这个方法，如果有传参，那么会调用这个方法

 @param router 路由器
 @param parameter 传递的参数
 */
- (void)router:(KVRouter *)router getParameter:(NSDictionary *)parameter;

@end
