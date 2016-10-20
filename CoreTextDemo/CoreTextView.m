//
//  CoreTextView.m
//  CoreTextDemo
//
//  Created by fangwenyu on 2016/10/18.
//  Copyright © 2016年 fangwenyu. All rights reserved.
//

#import "CoreTextView.h"
#import <CoreText/CoreText.h>

@interface CoreTextView()

{

    NSMutableArray *imageArr;   //存放图片
    NSMutableArray *imageDics;  //存放图片的尺寸信息
    
    NSAttributedString *_attString;
}


@end

@implementation CoreTextView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (void)setMarkupStr:(NSString *)mark {
    _attString = [self match:mark];
    [self setNeedsDisplay];
}

- (NSAttributedString *)attString {
    return _attString;
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_attString);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    NSInteger length = _attString.length;
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, length), path, NULL);
    CTFrameDraw(frame, context);    //绘制文本
    
    NSArray *imgFrms = [self calculateImageRectWithFrame:frame];   //根据ctframe 计算图片的绘制frame
    for (int i = 0; i < imgFrms.count; i ++) {
        NSValue *value = [imgFrms objectAtIndex:i];
        CGRect imgFrame = [value CGRectValue];
        CGContextDrawImage(context,imgFrame, [[imageArr objectAtIndex:i] CGImage]);  //绘制图片
    }
    
    CFRelease(frame);
    CFRelease(path);
    CFRelease(frameSetter);
}

-(NSMutableArray *)calculateImageRectWithFrame:(CTFrameRef)frame
{
    NSArray * arrLines = (NSArray *)CTFrameGetLines(frame);     //用ctframe获取所有的ctline
    NSInteger count = [arrLines count];
    CGPoint points[count];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), points);    //用ctframe获取每一个ctline的origin point
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:imageArr.count];
    
    
    for (int i = 0; i < count; i ++) {  //遍历每一个ctline
        CTLineRef line = (__bridge CTLineRef)arrLines[i];
        NSArray * arrGlyphRun = (NSArray *)CTLineGetGlyphRuns(line);    //用ctline获取该行内的ctrun数组
        for (int j = 0; j < arrGlyphRun.count; j ++) {  //遍历每一个ctline内的ctrun
            CTRunRef run = (__bridge CTRunRef)arrGlyphRun[j];
            NSDictionary * attributes = (NSDictionary *)CTRunGetAttributes(run);    //获取ctrun的attributes
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[attributes valueForKey:(id)kCTRunDelegateAttributeName];    //从ctrun的attributes中获取ctrundelegate
            if (delegate == nil) {
                continue;
            }
            NSDictionary * dic = CTRunDelegateGetRefCon(delegate);
            if (![dic isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            CGPoint point = points[i];  //该ctline的originpoint
            CGFloat ascent;
            CGFloat descent;
            CGRect boundsRun;
            boundsRun.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);//获取该ctrun的width
            boundsRun.size.height = ascent + descent;//通过ascent+descent计算该ctrun的height
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);//计算该ctrun的x坐标偏移量
            boundsRun.origin.x = point.x + xOffset;//该ctline的originpoint的x坐标 + 该ctrun的x轴偏移量 = 该ctrun的x轴坐标
            boundsRun.origin.y = point.y - descent;//该ctline的originpoint的y坐标 - 该ctrun的descent = 该ctrun的y轴坐标
            CGPathRef path = CTFrameGetPath(frame);
            CGRect colRect = CGPathGetBoundingBox(path);
            CGRect imageBounds = CGRectOffset(boundsRun, colRect.origin.x, colRect.origin.y);//计算出该ctrun在整个View中的frame
            //return imageBounds;
            [array addObject:[NSValue valueWithCGRect:imageBounds]];
        }
    }
    return array;
}

- (NSMutableAttributedString *)match:(NSString *)string {
    
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc]initWithString:@""];
    NSInteger index = 0;    //初始偏移量
    CGFloat fontSize = 12;  //初始字体大小
    UIColor *fontColor = [UIColor blackColor];   //初始字体颜色
    
    imageArr = [NSMutableArray array];
    imageDics = [NSMutableArray array];
    
    NSRegularExpression *regularEx = [[NSRegularExpression alloc]initWithPattern:@"<.*?>" options:NSRegularExpressionDotMatchesLineSeparators error:NULL];
    NSArray *chunks = [regularEx matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    
    for (NSTextCheckingResult *result in chunks) {
        
        NSDictionary *attrs = @{NSForegroundColorAttributeName : fontColor, NSFontAttributeName : [UIFont systemFontOfSize:fontSize]};
        [attrStr appendAttributedString:[[NSAttributedString alloc]initWithString:[string substringWithRange:NSMakeRange(index, result.range.location - index)] attributes:attrs]];
        
        index = result.range.location + result.range.length;
        
        NSString *subStr = [string substringWithRange:result.range];
        subStr = [subStr substringWithRange:NSMakeRange(1, subStr.length - 2)]; //去掉<>
        subStr = [subStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];    //去掉头尾空格与换行
        
        //NSLog(@"%@", subStr);
        
        NSArray *arr = [subStr componentsSeparatedByString:@","];
        for (NSString *str in arr) {
            NSString *str1 = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            //NSLog(@"%@", str1);
            NSArray *arr1 = [str1 componentsSeparatedByString:@"="];
            if (arr1.count == 2) {
                NSString *keyStr = [[arr1 firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *valueStr = [[arr1 lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                valueStr = [valueStr substringWithRange:NSMakeRange(1, valueStr.length - 2)];   //去掉""
                //NSLog(@"key=%@,value=%@", keyStr, valueStr);
                if ([keyStr compare:@"COLOR" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                    //NSLog(@"COLOR CHECKED!");
                    const char *cr = [valueStr UTF8String];
                    fontColor = [self colorWithHex:(unsigned int)strtol(cr, NULL, 16) alpha:1];
                }
                else if ([keyStr compare:@"FONT-SIZE" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                    //NSLog(@"FONT CHECKED!");
                    fontSize = [valueStr floatValue];
                }
                else if ([keyStr compare:@"IMG" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                    //NSLog(@"IMG CHECKED!");
                    //插入图片
                    UIImage *img = [UIImage imageNamed:valueStr];
                    CGFloat width = img.size.width;
                    CGFloat height = img.size.height;
                    
                    CTRunDelegateCallbacks callBacks;
                    memset(&callBacks,0,sizeof(CTRunDelegateCallbacks));    //声明一个callbacks结构体
                    callBacks.version = kCTRunDelegateCurrentVersion;
                    callBacks.getAscent = ascentCallBacks;
                    callBacks.getDescent = descentCallBacks;
                    callBacks.getWidth = widthCallBacks;
                    NSDictionary * dicPic = @{@"height":[NSNumber numberWithFloat:height],@"width":[NSNumber numberWithFloat:width]};
                    //NSDictionary * dicPic = @{@"height":@100,@"width":@100};
                    [imageDics addObject:dicPic];   //临时变量不保存起来的话，内存会被释放掉
                    CTRunDelegateRef delegate = CTRunDelegateCreate(&callBacks, (__bridge void *)dicPic);  //创建一个ctrundelegate，将图片的尺寸信息传入
                    unichar placeHolder = 0xFFFC;
                    NSString * placeHolderStr = [NSString stringWithCharacters:&placeHolder length:1];
                    NSMutableAttributedString * placeHolderAttrStr = [[NSMutableAttributedString alloc] initWithString:placeHolderStr]; //占位符
                    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)placeHolderAttrStr, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate); //给占位符添加ctrundelegate属性，设置为之前创建的curundelegate
                    CFRelease(delegate);    //释放delegate
                    
                    [attrStr appendAttributedString:placeHolderAttrStr];
                    
                    [imageArr addObject:img];
                }
            }
        }

    }
    
    return attrStr;
}

static CGFloat ascentCallBacks(void * ref)
{
    return [(NSNumber *)[(__bridge NSDictionary *)ref valueForKey:@"height"] floatValue]/2;
}
static CGFloat descentCallBacks(void * ref)
{
    return [(NSNumber *)[(__bridge NSDictionary *)ref valueForKey:@"height"] floatValue]/2; //图片垂直居中显示
}
static CGFloat widthCallBacks(void * ref)
{
    return [(NSNumber *)[(__bridge NSDictionary *)ref valueForKey:@"width"] floatValue];
}

- (UIColor *) colorWithHex:(uint) hex alpha:(CGFloat)alpha {
    int red, green, blue;
    
    blue = hex & 0x0000FF;
    green = ((hex & 0x00FF00) >> 8);
    red = ((hex & 0xFF0000) >> 16);
    
    return [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:alpha];
}

@end
