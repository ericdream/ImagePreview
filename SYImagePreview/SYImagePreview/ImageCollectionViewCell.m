//
//  ImageCollectionViewCell.m
//  AnamationDemo
//
//  Created by Eric on 2019/12/10.
//  Copyright © 2019 Zhejiang AU Education & Technologies Co.,Ltd. All rights reserved.
//

#import "ImageCollectionViewCell.h"

@implementation ImageCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        _imageView = [[UIImageView alloc] initWithFrame:self.frame];
        [self.contentView addSubview:_imageView];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    _imageView.frame = self.contentView.frame;
}
@end
