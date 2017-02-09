//
//  KVRouter.m
//  KVRouterTest
//
//  Created by kevin on 2017/2/7.
//  Copyright © 2017年 kevin. All rights reserved.
//

#import "KVRouter.h"
#import "AppDelegate.h"

@interface KVRouter ()

@property (nonatomic, assign) BOOL routerIsWorking;    //是否正在工作
@property (nonatomic, strong) NSMutableArray * requestWaitQueue;    //跳转任务队列
@property (nonatomic, strong) NSMutableDictionary * url_interface_map; //url与界面名称的映射字典
@property (nonatomic, strong) NSMutableDictionary * interface_url_map;  //界面名称与url的映射字典，用于快速通过界面名称查找到对应的url
@property (nonatomic, strong) NSMutableDictionary * url_createBlock_map;    //url与界面创建block的映射字典，用于自定义界面的创建，而不使用内部默认的init

@end

@implementation KVRouter
/**
 初始化路由器
 
 @return 返回路由实例
 */
+ (instancetype)initRouter {
    static KVRouter * kvrouter = nil;
    static dispatch_once_t kvroutertoken;
    dispatch_once(&kvroutertoken, ^{
        kvrouter = [[self alloc] init];
    });
    return kvrouter;
}

- (instancetype)init {
    if (self = [super init]) {
        self.routerIsWorking = NO;
        self.requestWaitQueue = [NSMutableArray array];
        self.url_createBlock_map = [NSMutableDictionary dictionary];
        //初始化路由，需要加载配置文件
        NSString * RIFStr = [[NSBundle mainBundle] pathForResource:@"KVRouterInterfaceConfig" ofType:@"plist"];
        NSArray * routerConfigs = [NSArray arrayWithContentsOfFile:RIFStr];
        self.url_interface_map = [NSMutableDictionary dictionary];
        self.interface_url_map = [NSMutableDictionary dictionary];
        //分模块加载
        for (NSArray * array in routerConfigs) {
            for (NSDictionary * dict in array) {
                NSString * exact_url = dict[@"native_url"];
                NSString * object = dict[@"object"];
                if ([object isKindOfClass:[NSString class]] && [exact_url isKindOfClass:[NSString class]]) {
                    //只有格式正确才添加进去
                    [self.url_interface_map setObject:object forKey:exact_url];
                    [self.interface_url_map setObject:exact_url forKey:object];
                }
            }
        }
    }
    return self;
}
#pragma mark - 注册界面
/**
 注册自定义的界面创建方法，用于某些界面的创建不是通过init的方法进行创建的情况，例如tableViewController等
 注意：这个方法只适用于url已经被注册进plist文件中
 
 @param targetClass 注册界面的class
 @param handler 创建回调block，返回一个创建好的界面示例
 */
+ (void)registerClass:(Class)targetClass toHandler:(KVRouterCreateBlock)handler{
    if (handler) {
        KVRouter * router = [KVRouter initRouter];
        NSString * url = [self getUrlWithClass:targetClass];
        if (url) {
            [router.url_createBlock_map setObject:handler forKey:url];
        }
    }
}

/**
 注册自定义的界面创建方法，用于某些界面的创建不是通过init的方法进行创建的情况，例如tableViewController等
 注意：这个方法可用于url没有被注册进plist文件中，如果url没有被注册进plist文件中，会自动将url注册，用于灵活使用路由器，避免在开发中忘记注册的情况，建议提前注册url，避免过多的使用该API去注册url，可以避免过多的注册会影响程序启动时间
 
 @param url 链接url
 @param handler 创建回调block，返回一个创建好的界面示例
 */
+ (void)registerUrl:(NSString*)url toHandler:(KVRouterCreateBlock)handler {
    if (handler) {
        KVRouter * router = [KVRouter initRouter];
        NSString * newurl = [self getAbsolutepathWithUrl:url];
        if (newurl) {
            //判断url是否已经注册过
            if ([router.url_interface_map objectForKey:newurl]) {
                [router.url_createBlock_map setObject:handler forKey:newurl];
            }else {
                //没有被注册进url中，需要将调用的类名以及url注册进来
                //获取调用者的类名
                NSString       *sourceString = [[NSThread callStackSymbols] objectAtIndex:1];
                NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
                NSMutableArray *array        = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
                [array removeObject:@""];
                if (array.count > 3) {
                    NSString * className = [array objectAtIndex:3];
                    [router.url_interface_map setObject:className forKey:newurl];
                    [router.interface_url_map setObject:newurl forKey:className];
                    [router.url_createBlock_map setObject:handler forKey:newurl];
                }
            }
        }
    }
}

/**
 通过类获取对应的链接url
 
 @param targetClass 想要查询的class
 @return 返回链接url，没有则返回nil
 */
+ (NSString*)getUrlWithClass:(Class)targetClass {
    return [self getUrlWithClassName:NSStringFromClass(targetClass)];
}

/**
 通过类名获取对应的链接url
 
 @param className 想要查询的类的名
 @return 返回链接url，没有则返回nil
 */
+ (NSString*)getUrlWithClassName:(NSString*)className {
    KVRouter * router = [KVRouter initRouter];
    if ([className isKindOfClass:[NSString class]]) {
        return [router.interface_url_map objectForKey:className];
    }else {
        return nil;
    }
}

#pragma mark - push形式推出界面的方法
/**
 根据url跳转界面（简单跳转，没有参数）push
 默认使用项目中的导航控制器推出
 
 @param url 链接url
 */
+ (void)openUrl:(NSString*)url {
    [self openUrl:url parameter:nil complete:nil withNavigationController:nil];
}

/**
 根据url跳转界面（简单跳转，没有参数）push
 需要传入一个导航控制器，用于推出
 
 @param url 链接url
 @param nav 用于推出界面的导航控制器
 */
+ (void)openUrl:(NSString *)url withNavigationController:(UINavigationController*)nav {
    [self openUrl:url parameter:nil complete:nil withNavigationController:nav];
}

/**
 拥有回调的跳转方法
 
 @param url 链接url
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 */
+ (void)openUrl:(NSString*)url complete:(KVRouterComplete)complete{
    [self openUrl:url parameter:nil complete:complete withNavigationController:nil];
}

/**
 拥有回调的跳转方法
 
 @param url 链接url
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 @param nav 需要传入一个导航控制器，用于推出
 */
+ (void)openUrl:(NSString*)url complete:(KVRouterComplete)complete withNavigationController:(UINavigationController*)nav{
    [self openUrl:url parameter:nil complete:complete withNavigationController:nav];
}

/**
 可以传参的跳转方法
 
 @param url 链接url
 @param parameter 需要传递的参数字典
 */
+ (void)openUrl:(NSString*)url parameter:(NSDictionary*)parameter {
    [self openUrl:url parameter:parameter complete:nil withNavigationController:nil];
}

/**
 可以传参的跳转方法
 
 @param url 链接url
 @param parameter 需要传递的参数字典
 @param nav 需要传入一个导航控制器，用于推出
 */
+ (void)openUrl:(NSString*)url parameter:(NSDictionary*)parameter withNavigationController:(UINavigationController*)nav{
    [self openUrl:url parameter:parameter complete:nil withNavigationController:nav];
}

/**
 可以传参，并且回调的跳转方法
 
 @param url 链接url
 @param parameter 需要传递的参数字典
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 */
+ (void)openUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterComplete)complete{
    [self openUrl:url parameter:parameter complete:complete withNavigationController:nil];
}

/**
 可以传参，并且回调的跳转方法
 
 @param url 链接url
 @param parameter 需要传递的参数字典
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 @param nav 需要传入一个导航控制器，用于推出
 */
+ (void)openUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterComplete)complete withNavigationController:(UINavigationController *)nav{
    [self getRequestWithUrl:url parameter:parameter complete:complete presentComplete:nil openType:KVRouterPush sourceController:nav];
}

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
+ (void)presentNavigationWithUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterPresentComplete)complete withSourceViewController:(UIViewController*)sourceViewController {
    [self getRequestWithUrl:url parameter:parameter complete:nil presentComplete:complete openType:KVRouterPresentWithNavgation sourceController:sourceViewController];
}

/**
 根据url跳转界面（简单跳转，没有参数）present
 
 @param url 链接url
 */
+ (void)presentUrl:(NSString*)url {
    [self presentUrl:url parameter:nil complete:nil withSourceViewController:nil];
}

/**
 根据url跳转界面（简单跳转，没有参数）present
 
 @param url 链接url
 @param sourceViewController 需要传入一个根控制器，用于弹出，如果传入nil，那么默认使用根控制器弹出
 */
+ (void)presentUrl:(NSString *)url withSourceViewController:(UIViewController*)sourceViewController {
    [self presentUrl:url parameter:nil complete:nil withSourceViewController:sourceViewController];
}

/**
 拥有回调的跳转方法
 
 @param url 链接url
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 */
+ (void)presentUrl:(NSString*)url complete:(KVRouterComplete)complete {
    [self presentUrl:url parameter:nil complete:complete withSourceViewController:nil];
}

/**
 拥有回调的跳转方法
 
 @param url 链接url
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 @param sourceViewController 需要传入一个根控制器，用于弹出，如果传入nil，那么默认使用根控制器弹出
 */
+ (void)presentUrl:(NSString*)url complete:(KVRouterComplete)complete withSourceViewController:(UIViewController*)sourceViewController {
    [self presentUrl:url parameter:nil complete:complete withSourceViewController:sourceViewController];
}

/**
 可以传参的跳转方法
 
 @param url 链接url
 @param parameter 需要传递的参数字典
 */
+ (void)presentUrl:(NSString*)url parameter:(NSDictionary*)parameter {
    [self presentUrl:url parameter:parameter complete:nil withSourceViewController:nil];
}

/**
 可以传参的跳转方法
 
 @param url 链接url
 @param parameter 需要传递的参数字典
 @param sourceViewController 需要传入一个根控制器，用于弹出，如果传入nil，那么默认使用根控制器弹出
 */
+ (void)presentUrl:(NSString*)url parameter:(NSDictionary*)parameter withSourceViewController:(UIViewController*)sourceViewController {
    [self presentUrl:url parameter:parameter complete:nil withSourceViewController:sourceViewController];
}

/**
 可以传参，并且回调的跳转方法
 
 @param url 链接url
 @param parameter 需要传递的参数字典
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 */
+ (void)presentUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterComplete)complete {
    [self presentUrl:url parameter:parameter complete:complete withSourceViewController:nil];
}

/**
 可以传参，并且回调的跳转方法
 
 @param url 链接url
 @param parameter 需要传递的参数字典
 @param complete 注册的界面创建完成的回调，可以在这里设置界面的代理或其他操作
 @param sourceViewController 需要传入一个根控制器，用于弹出，如果传入nil，那么默认使用根控制器弹出
 */
+ (void)presentUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterComplete)complete withSourceViewController:(UIViewController*)sourceViewController {
    [self getRequestWithUrl:url parameter:parameter complete:complete presentComplete:nil openType:KVRouterPresent sourceController:sourceViewController];
}

#pragma mark - 跳转任务代码
/**
 *  生成跳转请求，并且开始跳转任务
 */
+ (void)getRequestWithUrl:(NSString*)url parameter:(NSDictionary*)parameter complete:(KVRouterComplete)complete presentComplete:(KVRouterPresentComplete)presentComplete openType:(KVRouterOpenType)type sourceController:(UIViewController *)sourceController {
    //判断是否可以跳转
    if (![self canOpenUrl:url]) {
        //不可以跳转
        if (complete) {
            complete(nil);
        }
        return;
    }
    
    //创建一个跳转请求
    KVRouterRequest * request = [KVRouterRequest handleDataWithUrl:url parameter:parameter complete:complete];
    request.openType = type;
    request.sourceViewController = sourceController;
    request.presentComplete = presentComplete;
    
    KVRouter * router = [KVRouter initRouter];
    //为了更好的容错率，需要在主线程中完成跳转界面
    dispatch_async(dispatch_get_main_queue(), ^{
        [router.requestWaitQueue addObject:request];    //添加进跳转队列
        //开始任务
        [router beginTask];
    });
}

/**
 *  开始跳转任务
 */
- (void)beginTask {
    if (self.requestWaitQueue.count && !self.routerIsWorking) {
        KVRouterRequest * request = self.requestWaitQueue.firstObject;
        [self handleRequest:request];   //开始跳转
    }
}

/**
 *  可以处理跳转队列的方法
 */
- (void)handleRequest:(KVRouterRequest*)request {
    self.routerIsWorking = YES;
    NSString * url = request.url;
    NSDictionary * parameter = request.parameter;
    KVRouter * router = [KVRouter initRouter];
    //先获取有没有注册过界面
    NSString * interfacename = [router.url_interface_map objectForKey:url];
    Class newClass = NSClassFromString(interfacename);
    if (newClass) {
        UIViewController * vc = nil;
        KVRouterCreateBlock createBlock = [self.url_createBlock_map objectForKey:url];
        if (createBlock) {
            vc = createBlock(); //调用注册的自定义创建界面的回调
            if (!vc) {
                vc = [[newClass alloc] init];
            }
        }else {
            vc = [[newClass alloc] init];
        }
        if (parameter) {
            //如果有传参，那么传进去
            [vc router:router getParameter:parameter];
        }
        //判断跳转类型
        if (request.openType == KVRouterPush) {
            if (request.complete) {
                request.complete(vc);
            }
            //推出的
#warning 第二个控制器开始隐藏tabbar，如果项目中已经自定制了导航控制器，内部已经做了处理，这句话可以删除
            vc.hidesBottomBarWhenPushed = YES;
            if ([request.sourceViewController isKindOfClass:[UINavigationController class]]) {
                [((UINavigationController*)request.sourceViewController) pushViewController:vc animated:YES];
            }else {
#warning 这里需要根据项目的需求定制默认形式的推出代码，在这里我默认一个tabbar里面有多个nav，这里的代码可以修改
                //没有，那么使用默认形式推出界面
                AppDelegate * del = (AppDelegate*)[UIApplication sharedApplication].delegate;
                UITabBarController *tabVC = (UITabBarController *)del.window.rootViewController;
                UINavigationController *pushClassStance = (UINavigationController *)tabVC.viewControllers[tabVC.selectedIndex];
                // 跳转到对应的控制器
                [pushClassStance pushViewController:vc animated:YES];
            }
        }else {
            UIViewController * presentVC = vc;
            if (request.openType == KVRouterPresentWithNavgation) {
                //需要包装一层
                if (request.presentComplete) {
                    UINavigationController * nav = request.presentComplete(vc);
                    if (nav) {
                        presentVC = nav;
                    }else {
                        //返回nil
#warning 默认包装导航控制器，这部分代码可以修改成自己项目的定制导航控制器
                        //没有回调，那么使用默认的导航控制器进行包装
                        UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:vc];
                        presentVC = nav;
                    }
                }else {
#warning 默认包装导航控制器，这部分代码可以修改成自己项目的定制导航控制器
                    //没有回调，那么使用默认的导航控制器进行包装
                    UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:vc];
                    presentVC = nav;
                }
            }
            //弹出的
            if (request.sourceViewController) {
                if ([request.sourceViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
                    if (request.complete) {
                        request.complete(vc);
                    }
                    [request.sourceViewController presentViewController:presentVC animated:YES completion:nil];
                }else {
                    if (request.complete) {
                        request.complete(nil);
                    }
                }
            }else {
                //没有弹出的根控制器，那么使用最原先的控制器弹出
                if (request.complete) {
                    request.complete(vc);
                }
                AppDelegate * del = (AppDelegate*)[UIApplication sharedApplication].delegate;
                [del.window.rootViewController presentViewController:presentVC animated:YES completion:nil];
            }
        }
    }else {
        if (request.complete) {
            request.complete(nil);
        }
    }
    
    [self workEnd:request];
}

/**
 转场结束，用于移除任务，以及开始下一个任务

 @param request 跳转请求
 */
- (void)workEnd:(KVRouterRequest*)request {
    [self.requestWaitQueue removeObject:request];   //移除掉任务
    self.routerIsWorking = NO;
    [self beginTask];   //开始任务
}

/**
 是否可以跳转该url
 
 @param url 链接url
 @return 返回布尔值
 */
+ (BOOL)canOpenUrl:(NSString*)url{
    KVRouter * router = [KVRouter initRouter];
    NSString * className = [router.url_interface_map objectForKey:[self getAbsolutepathWithUrl:url]];
    if (className) {
        return YES;
    }else {
        return NO;
    }
}

/**
 获取跳转路径，需要去除协议名称以及参数，用于判断是否可以跳转该界面或者保存创建回调block

 @param url 链接url
 @return 返回可以跳转的绝对路径
 */
+ (NSString*)getAbsolutepathWithUrl:(NSString*)url {
    NSMutableString * newurl = [NSMutableString stringWithString:url];
    //分割协议
    if ([newurl hasPrefix:kvrouter_main_scheme]) {
        //需要去除协议名称
        [newurl deleteCharactersInRange:NSMakeRange(0, kvrouter_main_scheme.length)];
    }
    NSArray * componseArr = [newurl componentsSeparatedByString:@"?"];
    return componseArr.firstObject;
}

@end


#pragma mark - 跳转请求
@implementation KVRouterRequest

+ (instancetype)handleDataWithUrl:(NSString *)url parameter:(NSDictionary *)parameter complete:(KVRouterComplete)complete {
    KVRouterRequest * request = [[KVRouterRequest alloc] init];
    //处理url，获取到url携带的参数
    [request handleUrl:url];
    if (parameter) {
        //判断是否已有了参数字典
        if (request.parameter) {
            //已有参数，这是从url中解析得到的参数
            NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:request.parameter];
            for (NSString * key in parameter.allKeys) {
                [dict setObject:parameter[key] forKey:key];
            }
            request.parameter = [NSDictionary dictionaryWithDictionary:dict];
        }else {
            request.parameter = parameter;
        }
    }
    request.complete = complete;
    return request;
}
/**
 *  处理url
 */
- (void)handleUrl:(NSString*)url {
    NSMutableString * newurl = [NSMutableString stringWithString:url];
    //分割协议
    if ([newurl hasPrefix:kvrouter_main_scheme]) {
        //需要去除协议名称
        [newurl deleteCharactersInRange:NSMakeRange(0, kvrouter_main_scheme.length)];
    }
    //分割参数
    NSArray * componseArr = [newurl componentsSeparatedByString:@"?"];
    if (componseArr.count > 1) {
        self.url = componseArr.firstObject;
        NSString * parameterStr = componseArr.lastObject;
        //继续切割
        NSMutableDictionary * parameterDict = [NSMutableDictionary dictionary];
        NSArray * parametersArr = [parameterStr componentsSeparatedByString:@"&"];
        for (NSString * parameter in parametersArr) {
            //使用等号切割
            NSArray * detailParameters = [parameter componentsSeparatedByString:@"="];
            if (detailParameters.count == 2) {
                [parameterDict setObject:detailParameters.lastObject forKey:detailParameters.firstObject];
            }
        }
        if (parameterDict.count) {
            //对参数赋值
            self.parameter = [NSDictionary dictionaryWithDictionary:parameterDict];
        }
    }else {
        //没有参数
        self.url = newurl;
    }
}

@end

@implementation NSObject (KVRouter)

- (void)router:(KVRouter *)router getParameter:(NSDictionary *)parameter {
    
}

@end
