//
//  OneController.h
//  KVRouterTest
//
//  Created by kevin on 2017/2/7.
//  Copyright © 2017年 yiye. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OneControllerDelegate <NSObject>

@optional
- (void)nihao;  //代理

@end

@interface OneController : UIViewController

@property (nonatomic, weak) id <OneControllerDelegate> delegate;

@end
