//
//  CoreTextView.h
//  CoreTextDemo
//
//  Created by fangwenyu on 2016/10/18.
//  Copyright © 2016年 fangwenyu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoreTextView : UIView

@property (nonatomic, copy, readonly)NSAttributedString *attString;

- (void)setMarkupStr:(NSString *)mark;
- (NSMutableAttributedString *)match:(NSString *)string;

@end
