//
//  SYPicturePreviewView.m
//  AnamationDemo
//
//  Created by Eric on 2019/12/4.
//  Copyright © 2019 Zhejiang AU Education & Technologies Co.,Ltd. All rights reserved.
//

#import "SYPicturePreviewView.h"

#import <UIImageView+WebCache.h>
#define disMissOffset 200.0f
#define enableOffset 20.f
#define enableTanValue 0.8  // 1 = 45度  0.8 小于45度

@protocol SYCollectionCellDelegate <NSObject>
- (void)collectionViewEnableScroll:(BOOL)enable;
- (void)changeViewAlpha:(CGFloat)alpha;
- (void)disMissView:(UIImageView *)view model:(SYImageModel *)model index:(NSInteger)index;
- (void)saveImage:(UIImage *)image;
@end

@implementation SYImageModel

@end
@interface SYImagePreviewFlowLayout : UICollectionViewFlowLayout
@property (nonatomic, assign) UIEdgeInsets sectionInsets;
@property (nonatomic, assign) CGFloat miniLineSpace;
@property (nonatomic, assign) CGFloat miniInterItemSpace;
@property (nonatomic, assign) CGSize eachItemSize;
@property (nonatomic, assign) CGPoint lastOffset;
@end
@implementation SYImagePreviewFlowLayout
- (instancetype)init{
    self = [super init];
    if (self) {
        _lastOffset = CGPointZero;
    }
    return self;
}

-(void)prepareLayout{
    [super prepareLayout];
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.sectionInset = _sectionInsets;
    self.minimumLineSpacing = _miniLineSpace;
    self.minimumInteritemSpacing = _miniInterItemSpace;
    self.itemSize = _eachItemSize;
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
}

-(CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity{
    
    CGFloat pageSpace = [self stepSpace];
    CGFloat offsetMax = self.collectionView.contentSize.width;
    CGFloat offsetMin = 0;
    BOOL direction = (proposedContentOffset.x - _lastOffset.x) > 0;
    if (_lastOffset.x<offsetMin){
        _lastOffset.x = offsetMin;
    }
    else if (_lastOffset.x>offsetMax){
        _lastOffset.x = offsetMax;
    }
    CGFloat offsetForCurrentPointX = ABS(proposedContentOffset.x - _lastOffset.x);
    CGFloat velocityX = velocity.x;

    if ((offsetForCurrentPointX > pageSpace/2. || velocityX != 0) && _lastOffset.x>=offsetMin && _lastOffset.x<=offsetMax && (proposedContentOffset.x != _lastOffset.x)){
        NSInteger pageFactor = 0;
        pageFactor = 1;
        CGFloat pageOffsetX = pageSpace*pageFactor;
        proposedContentOffset = CGPointMake(_lastOffset.x + (direction?pageOffsetX:-pageOffsetX), proposedContentOffset.y);
        _lastOffset.x = proposedContentOffset.x;
    }
    else{
        proposedContentOffset = CGPointMake(_lastOffset.x, _lastOffset.y);
    }
    
    return proposedContentOffset;
}

-(CGFloat)stepSpace{
    return self.eachItemSize.width + self.miniLineSpace;
}
@end
@interface SYCollectionCell:UICollectionViewCell<UIGestureRecognizerDelegate,UIScrollViewDelegate>
@property (nonatomic,assign)id<SYCollectionCellDelegate>delegate;
@property (nonatomic,strong)UIImageView *previewImageView;
@property (nonatomic,strong)UIPanGestureRecognizer *panGesture;
@property (nonatomic,strong)UIScrollView *scrollView;
@property (nonatomic,strong)SYImageModel *previewImage;
@property (nonatomic,assign)NSInteger index;
@end
@implementation SYCollectionCell{
    CGPoint _beginPoint;
    CGPoint _imagePoint;
    CGFloat _startx;
    CGFloat _starty;
    BOOL _enableMove;
    BOOL _edgeLock;
    CGFloat _imageScale;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        _imageScale = 1.0f;
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
        _scrollView.minimumZoomScale = 1;
        _scrollView.maximumZoomScale = 2;
        _scrollView.delegate = self;
        [self.contentView addSubview:_scrollView];
        _previewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
        _previewImageView.userInteractionEnabled = YES;
        [_scrollView addSubview:_previewImageView];
        _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
        [_scrollView addGestureRecognizer:_panGesture];
        _panGesture.delegate = self;
        
        UITapGestureRecognizer *singleGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGesture:)];
        singleGesture.numberOfTapsRequired = 1;
        [_scrollView addGestureRecognizer:singleGesture];
        
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        [_scrollView addGestureRecognizer:doubleTapGesture];
        [singleGesture requireGestureRecognizerToFail:doubleTapGesture];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
        [_scrollView addGestureRecognizer:longPressGesture];
        
    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollActionNotification:) name:@"kScrollActionNotification" object:nil];
        
    }
    return self;
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)scrollActionNotification:(NSNotification *)notification{
    NSDictionary *info =  notification.object;
    BOOL flag = [info[@"enableGesture"] boolValue];
    _panGesture.enabled = flag;
}
- (void)collectionViewEnable:(BOOL)enable{
    if([self.delegate respondsToSelector:@selector(collectionViewEnableScroll:)]){
        [self.delegate collectionViewEnableScroll:enable];
    }
}
- (void)setPreviewImage:(SYImageModel *)previewImage{
    _previewImage = previewImage;
    CGSize imageSize = previewImage.image.size;
    if(previewImage.image && (imageSize.height != 0 ||imageSize.width != 0)){
        [self showImageWithImage:previewImage.image];
    }
    if(previewImage.imageUrl && previewImage.imageUrl.length>0){
        [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:previewImage.imageUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            [self showImageWithImage:image];
            self->_previewImage.image = image;
        }];
    }
}
- (void)showImageWithImage:(UIImage *)image{
    CGSize imageSize = image.size;
    if(imageSize.height/imageSize.width >= CGRectGetHeight(self.frame)/CGRectGetWidth(self.frame)){
        CGFloat w =  imageSize.width*CGRectGetHeight(self.frame)/imageSize.height;
        self.previewImageView.frame = CGRectMake(0, 0, w, CGRectGetHeight(self.frame));
    }else{
        CGFloat h = imageSize.height*CGRectGetWidth(self.frame)/imageSize.width;
        self.previewImageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), h);
    }
    self.previewImageView.center = self.scrollView.center;
    self.previewImageView.image =image;
}
- (void)longPressGesture:(UILongPressGestureRecognizer *)gesture{
    NSLog(@"longPressGesture");
    if(gesture.state == UIGestureRecognizerStateBegan){
        if([self.delegate respondsToSelector:@selector(saveImage:)]){
            [self.delegate saveImage:self.previewImage.image];
        }
    }
}
- (void)singleTapGesture:(UITapGestureRecognizer *)gesture{
    [self disMiss];
}
- (void)doubleTapGesture:(UITapGestureRecognizer *)gesture{
    if (self.scrollView.zoomScale > 1) {
        [self.scrollView setZoomScale:1 animated:YES];
    }else{
        CGPoint point = [gesture locationInView:self.previewImageView];
        CGRect zoomRect = [self zoomRectForScrollView:self.scrollView withScale:2 withCenter:point];
        [self.scrollView zoomToRect:zoomRect animated:YES];
    }
}
- (CGRect)zoomRectForScrollView:(UIScrollView *)scrollView withScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    zoomRect.size.height = scrollView.frame.size.height / scale;
    zoomRect.size.width  = scrollView.frame.size.width  / scale;
    
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}
- (void)panGesture:(UIPanGestureRecognizer *)gesture{
    UIView *panView = gesture.view;
    CGPoint panPoint = [gesture translationInView:panView.superview];
    if(gesture.state == UIGestureRecognizerStateBegan){
        _beginPoint = panPoint;
        _imagePoint = panView.frame.origin;
    }else if (gesture.state == UIGestureRecognizerStateChanged){
        
        CGPoint point = panPoint;
        CGFloat offset_y = point.y-_beginPoint.y;
        CGFloat offset_x = point.x-_beginPoint.x;
        
        CGFloat a_y = fabs(_beginPoint.y - point.y)*1.0;
        CGFloat b_x = fabs(_beginPoint.x-point.x)*1.0;
        double tanValue =  fabs(tan(b_x/a_y));
        
        if(offset_y>enableOffset && (ABS(offset_x)<enableOffset) && !_edgeLock){
            _edgeLock = YES;
            if(tanValue<enableTanValue){
                if(!_enableMove){
                    _startx = offset_x;
                    _starty = offset_y;
                }
                _enableMove = YES;
                [self collectionViewEnable:NO];
            }else{
                _enableMove = NO;
                [self collectionViewEnable:YES];
            }
        }
        if(_enableMove){
            offset_x = offset_x - _startx;
            offset_y = offset_y - _starty;
            CGRect frame = panView.frame;
            _imageScale = 1-(offset_y*1.0/CGRectGetHeight([UIScreen mainScreen].bounds));
            _imageScale =  MAX(_imageScale, 0);
            _imageScale = MIN(_imageScale, 1);
            CGFloat y = _imagePoint.y + offset_y + offset_y * _imageScale;
            CGFloat x = _imagePoint.x + offset_x + offset_x * _imageScale;
            y = MIN(y, CGRectGetHeight(self.frame));
            
            frame.origin.y= y;
            frame.origin.x = x;
            panView.frame = frame;
            if([self.delegate respondsToSelector:@selector(changeViewAlpha:)]){
                [self.delegate changeViewAlpha:_imageScale*0.6];
            }
            panView.transform = CGAffineTransformMakeScale(_imageScale, _imageScale);
        }
    }else if (gesture.state == UIGestureRecognizerStateEnded){
        _edgeLock = NO;
        [self collectionViewEnable:YES];
        if(_enableMove){
            CGPoint point = panPoint;
            CGFloat offset_y = point.y-_beginPoint.y;
            if(offset_y>disMissOffset){
                [self disMiss];
                return;
            }
            [UIView animateWithDuration:0.23 animations:^{
                panView.transform = CGAffineTransformIdentity;
                CGRect frame = panView.frame;
                frame.origin= self->_imagePoint;
                panView.frame = frame;
                if([self.delegate respondsToSelector:@selector(changeViewAlpha:)]){
                    [self.delegate changeViewAlpha:1];
                }
                self->_enableMove = NO;
            }];
        }
        
    }else if (gesture.state == UIGestureRecognizerStateCancelled){
        
        _edgeLock = NO;
        [self collectionViewEnable:YES];
        if(_enableMove){
            [UIView animateWithDuration:0.23 animations:^{
                panView.transform = CGAffineTransformIdentity;
                CGRect frame = panView.frame;
                frame.origin= self->_imagePoint;
                panView.frame = frame;
                if([self.delegate respondsToSelector:@selector(changeViewAlpha:)]){
                    [self.delegate changeViewAlpha:1];
                }
                self->_enableMove = NO;
            }];
        }
    }
}
- (void)disMiss{
    if([self.delegate respondsToSelector:@selector(disMissView:model:index:)]){
        [self.delegate disMissView:self.previewImageView model:self.previewImage index:self.index];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}
#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.previewImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    if(scrollView.zoomScale == 1){
        self.previewImageView.center = self.scrollView.center;
        self.panGesture.enabled = YES;
    }else{
        self.panGesture.enabled = NO;
        CGFloat centeX = scrollView.contentSize.width>CGRectGetWidth(self.frame)?scrollView.contentSize.width/2.0:CGRectGetWidth(self.frame)/2.0;
        CGFloat centerY = scrollView.contentSize.height>CGRectGetHeight(self.frame)?scrollView.contentSize.height/2.0:CGRectGetHeight(self.frame)/2.0;
        self.previewImageView.center = CGPointMake(centeX, centerY);
    }
    
}
@end
@interface SYPicturePreviewView ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDataSourcePrefetching,SYCollectionCellDelegate>
@property (nonatomic,strong)UICollectionView *collectionView;
@end
@implementation SYPicturePreviewView{
    CGFloat lastOffset;
    SYImagePreviewFlowLayout *_layout;
}
- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = [UIColor blackColor];
        _layout = [[SYImagePreviewFlowLayout alloc] init];
        _layout.eachItemSize = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
        _layout.miniLineSpace = 10.00f;
        _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame)) collectionViewLayout:_layout];
        _collectionView.userInteractionEnabled = YES;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.prefetchDataSource = self;
        [self addSubview:_collectionView];
        [_collectionView registerClass:[SYCollectionCell class] forCellWithReuseIdentifier:@"SYCollectionCell"];
    }
    return self;
}
- (void)showWithFristImage:(UIImage *)image fromIndex:(NSInteger)index fromRect:(CGRect)rect{
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    [self.collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    _layout.lastOffset = self.collectionView.contentOffset;
    UIImageView *tmpView = [[UIImageView alloc] initWithFrame:rect];
    tmpView.image = image;
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [self addSubview:tmpView];
    self.collectionView.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        CGSize imageSize = image.size;
        if(imageSize.height==0 ||imageSize.width == 0){
            return;
        }
        if(imageSize.height/imageSize.width >= CGRectGetHeight(self.frame)/CGRectGetWidth(self.frame)){
            CGFloat w =  imageSize.width*CGRectGetHeight(self.frame)/imageSize.height;
            tmpView.frame = CGRectMake(0, 0, w, CGRectGetHeight(self.frame));
        }else{
            CGFloat h = imageSize.height*CGRectGetWidth(self.frame)/imageSize.width;
            tmpView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), h);
        }
        tmpView.center = CGPointMake(CGRectGetWidth([UIScreen mainScreen].bounds)/2.0, CGRectGetHeight([UIScreen mainScreen].bounds)/2.0);
        
    } completion:^(BOOL finished) {
        self.collectionView.alpha = 1;
        [tmpView removeFromSuperview];
    }];
}
- (void)setAllImages:(NSArray<SYImageModel *> *)allImages{
    _allImages = allImages;
    [self.collectionView reloadData];
    
}
#pragma mark -SYCollectionCellDelegate
- (void)collectionViewEnableScroll:(BOOL)enable{
    _collectionView.scrollEnabled = enable;
}
- (void)disMissView:(UIImageView *)view model:(SYImageModel *)model index:(NSInteger)index{
    CGRect fromRect = [view.superview convertRect:view.frame toView:self];
    CGRect toRect = CGRectZero;
    if([self.delegate respondsToSelector:@selector(disMisWithIndex:view:)]){
        toRect = [self.delegate disMisWithIndex:index view:self];
    }
    UIImageView *tmpView = [[UIImageView alloc] initWithFrame:CGRectMake(fromRect.origin.x, fromRect.origin.y, CGRectGetWidth(fromRect), CGRectGetHeight(fromRect))];
    tmpView.image = model.image;
    
    [self addSubview:tmpView];
    self.collectionView.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        tmpView.frame = toRect;
        [self changeViewAlpha:0.1];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
- (void)changeViewAlpha:(CGFloat)alpha{
    self.collectionView.backgroundColor = [UIColor colorWithWhite:0 alpha:alpha];
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:alpha];
}
- (void)saveImage:(UIImage *)image{
    if([self.delegate respondsToSelector:@selector(saveImage:view:)]){
        [self.delegate saveImage:image view:self];
    }
}
#pragma mark --
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _allImages.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    SYCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SYCollectionCell" forIndexPath:indexPath];
    cell.delegate = self;
    SYImageModel *model = self.allImages[indexPath.row];
    cell.previewImage = model;
    cell.index = indexPath.row;
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths{
    //    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    //         [UIImage imageNamed:[NSString stringWithFormat:@"%li%li.jpeg",obj.row+1,obj.row+1]];
    //    }];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat offset =ABS(scrollView.contentOffset.x - lastOffset);
    if(offset>enableOffset){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kScrollActionNotification" object:@{@"enableGesture":@(NO)}];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    BOOL scrollStop = !scrollView.tracking && !scrollView.dragging && !scrollView.decelerating;
    if(scrollStop){
        lastOffset = _collectionView.contentOffset.x;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kScrollActionNotification" object:@{@"enableGesture":@(YES)}];
    }
}

@end
