//
//  ViewController.m
//  KVRouterTest
//
//  Created by kevin on 2017/2/7.
//  Copyright © 2017年 yiye. All rights reserved.
//

#import "ViewController.h"
#import "OneController.h"   //由于需要使用到协议代理，所以还是需要包含头文件，如果与下个页面耦合性不高，完全可以不引入头文件了

@interface ViewController () <OneControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
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
//    //使用自带导航控制器推出控制器
//    [KVRouter openUrl:url parameter:parameter withNavigationController:self.navigationController];
}

- (void)nihao {
    NSLog(@"协议代理触发了");
}

@end
