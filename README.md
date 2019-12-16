# ImagePreview
仿微信图片预览

#### 1、只需要\#import "SYPicturePreviewView.h" 就可以使用

#### 2、demo

>
>
>~~~objective-c
>	 SYPicturePreviewView *previewImageView = [[SYPicturePreviewView alloc] initWithFrame:[UIScreen mainScreen].bounds];
>    previewImageView.allImages = previewImages; // 需要预览的所有图片对象
>    //ImageCollectionViewCell *cell1 = (ImageCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
>   // CGRect rect = [cell1.contentView.superview convertRect:cell1.contentView.frame toView:[UIApplication sharedApplication].keyWindow];
>// 传入点击图片的位置
>    [previewImageView showWithFristImage:cell1.imageView.image fromIndex:indexPath.row fromRect:rect];
>    previewImageView.delegate = self; // 实现代理
>~~~

>
>
>~~~objective-c
>#pragma SYPicturePreviewViewDelegate
>- (CGRect)disMisWithIndex:(NSInteger)index view:(SYPicturePreviewView *)view{
>   // NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
>    // ImageCollectionViewCell *cell1 = (ImageCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:path];
>    //CGRect toRect = [cell1.contentView.superview convertRect:cell1.contentView.frame toView:[UIApplication sharedApplication].keyWindow];
>    return toRect; //返回点击图片对应的消失位置
>}
>~~~
>
>