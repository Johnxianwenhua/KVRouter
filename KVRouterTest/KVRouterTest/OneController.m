//
//  OneController.m
//  KVRouterTest
//
//  Created by kevin on 2017/2/7.
//  Copyright © 2017年 yiye. All rights reserved.
//

#import "OneController.h"

@interface OneController ()

@end

@implementation OneController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"第一个";
    self.view.backgroundColor = [UIColor yellowColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //触发代理事件
    if (self.delegate && [self.delegate respondsToSelector:@selector(nihao)]) {
        [self.delegate nihao];
    }
    //弹出一个使用导航控制器包装的控制器，如果complete传nil或者返回nil，那么使用默认的导航控制器进行包装
    [KVRouter presentNavigationWithUrl:@"main/two" parameter:nil complete:nil withSourceViewController:self];
//    //也可以自定义包装导航控制器
//    [KVRouter presentNavigationWithUrl:@"main/two" parameter:nil complete:^UINavigationController *(UIViewController *object) {
//        UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:object];
//        return nav;
//    } withSourceViewController:nil];
//    //也可以不加导航控制器进行弹出
//    [KVRouter presentUrl:@"main/two"];
}
//传递过来的参数，以字典的形式，使用者不需要做其他操作，只需要在需要接收参数的地方重写这个方法即可接收到传参
- (void)router:(KVRouter *)router getParameter:(NSDictionary *)parameter {
    NSLog(@"%@", parameter);
}

@end
