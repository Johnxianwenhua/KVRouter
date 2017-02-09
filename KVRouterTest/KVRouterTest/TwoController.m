//
//  TwoController.m
//  KVRouterTest
//
//  Created by kevin on 2017/2/7.
//  Copyright © 2017年 yiye. All rights reserved.
//

#import "TwoController.h"

@interface TwoController ()

@end

@implementation TwoController

+ (void)load {
    //注册自定义创建方法，在这里，由于"main/two"已经注册进plist中，所以将不会重复注册
    [KVRouter registerUrl:@"main/two" toHandler:^UIViewController *{
        return [[self alloc] init];
    }];
    //快速地通过class注册自定义创建方法，注意：这个方法只适用于该类已经和url注册进plist的情况，上面的方法，如果忘记了注册进plist，会自动将url注册
//    [KVRouter registerClass:self toHandler:^UIViewController *{
//        return [[self alloc] init];
//    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"第二个";
    self.view.backgroundColor = [UIColor redColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"退出" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.navigationController) {
        [KVRouter openUrl:@"main/three" withNavigationController:self.navigationController];
    }else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
