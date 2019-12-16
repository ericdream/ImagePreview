//
//  ViewController.m
//  SYImagePreview
//
//  Created by Eric on 2019/12/16.
//  Copyright © 2019 Zhejiang AU Education & Technologies Co.,Ltd. All rights reserved.
//

#import "ViewController.h"
#import "SYPicturePreviewView.h"
#import "ImageCollectionViewCell.h"
#import <UIImageView+WebCache.h>
@interface ViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,NSURLSessionDataDelegate,NSURLSessionTaskDelegate,SYPicturePreviewViewDelegate>
@property (nonatomic,strong)UICollectionView *collectionView;
@end

@implementation ViewController{
    NSMutableArray *previewImages;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    previewImages = [[NSMutableArray alloc] init];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(120, 120);
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
       _collectionView.delegate = self;
       _collectionView.dataSource = self;
       [self.view addSubview:_collectionView];
    [_collectionView registerClass:[ImageCollectionViewCell class] forCellWithReuseIdentifier:@"ImageCollectionViewCell"];
       
       for (int i =0; i<9; i++) {
           SYImageModel *model = [[SYImageModel alloc] init];
           UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%i%i.jpeg",i+1,i+1]];
           model.image = image;
           [previewImages addObject:model];
       }
    SYImageModel *model = [[SYImageModel alloc] init];
    model.imageUrl = @"http://img4.imgtn.bdimg.com/it/u=2852083094,372235004&fm=26&gp=0.jpg";
    [previewImages addObject:model];
    // Do any additional setup after loading the view.
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return previewImages.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCollectionViewCell" forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor redColor];
    SYImageModel *model = [previewImages objectAtIndex:indexPath.row];
    
    if(model.image){
        cell.imageView.image = model.image;
    }else{
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:model.imageUrl] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            
        }];
    }
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    SYPicturePreviewView *previewImageView = [[SYPicturePreviewView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    previewImageView.allImages = previewImages;
    ImageCollectionViewCell *cell1 = (ImageCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    CGRect rect = [cell1.contentView.superview convertRect:cell1.contentView.frame toView:[UIApplication sharedApplication].keyWindow];
    [previewImageView showWithFristImage:cell1.imageView.image fromIndex:indexPath.row fromRect:rect];
    previewImageView.delegate = self;
}
#pragma SYPicturePreviewViewDelegate
- (CGRect)disMisWithIndex:(NSInteger)index view:(SYPicturePreviewView *)view{
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
     ImageCollectionViewCell *cell1 = (ImageCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:path];
    CGRect toRect = [cell1.contentView.superview convertRect:cell1.contentView.frame toView:[UIApplication sharedApplication].keyWindow];
    return toRect;
}

@end
