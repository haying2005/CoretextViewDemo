//
//  ViewController.m
//  CoreTextDemo
//
//  Created by fangwenyu on 2016/10/18.
//  Copyright © 2016年 fangwenyu. All rights reserved.
//

#import "ViewController.h"
#import "CoreTextView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)loadView {
    CoreTextView *view = [[CoreTextView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    view.backgroundColor = [UIColor whiteColor];
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *str = @"a<IMG=\"icon-40\">d<IMG=\"icon-40\">s<COLOR = \"0XFDBFC5\" , font-size=\"20\">dfgaa.<IMG=\"icon-40\">DSD"; //@"<.*?>"
    //    NSMutableAttributedString *attStr = [self match:str];
    [((CoreTextView *)self.view) setMarkupStr:str];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [((CoreTextView *)self.view) setMarkupStr:@"<IMG=\"icon-40\">d<IMG=\"icon-40\">"];
    });
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
