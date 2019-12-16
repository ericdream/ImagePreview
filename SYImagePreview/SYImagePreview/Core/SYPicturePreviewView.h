//
//  SYPicturePreviewView.h
//  AnamationDemo
//
//  Created by Eric on 2019/12/4.
//  Copyright © 2019 Zhejiang AU Education & Technologies Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@class SYPicturePreviewView;
@protocol SYPicturePreviewViewDelegate <NSObject>
@optional
- (CGRect)disMisWithIndex:(NSInteger)index view:(SYPicturePreviewView *)view;
- (void)saveImage:(UIImage *)image view:(SYPicturePreviewView *)view;
@end
@interface SYImageModel : NSObject
@property (nonatomic,strong)UIImage *image;
@property (nonatomic,copy)NSString *imageUrl;
@end
@interface SYPicturePreviewView : UIView
@property (nonatomic,strong)NSArray <SYImageModel *>*allImages;
@property (nonatomic,assign) id<SYPicturePreviewViewDelegate>delegate;
- (void)showWithFristImage:(UIImage *)image fromIndex:(NSInteger)index fromRect:(CGRect)rect;
@end

NS_ASSUME_NONNULL_END


