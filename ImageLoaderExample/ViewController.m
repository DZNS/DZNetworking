//
//  ViewController.m
//  ImageLoaderExample
//
//  Created by Nikhil Nigade on 15/05/20.
//  Copyright © 2020 Dezine Zync Studios LLP. All rights reserved.
//

#import "ViewController.h"
#import <DZNetworking/UIImageView+ImageLoading.h>
#import <DZNetworking/ImageLoader.h>

@interface UIImage (Sizing)

- (UIImage *)fastScale:(CGFloat)maxWidth quality:(CGFloat)quality imageData:(NSData **)imageData;

@end

@implementation UIImage (Sizing)

- (UIImage *)fastScale:(CGFloat)maxWidth quality:(CGFloat)quality imageData:(NSData **)imageData {
    
    UIImage * scaled;
    NSData * data = UIImageJPEGRepresentation(self, 1);
    
    CGFloat const deviceMaxWidth = MAX(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
    CGFloat usableWidth = MIN(maxWidth * UIScreen.mainScreen.scale, deviceMaxWidth);
    
    if (usableWidth >= self.size.width) {
        if (imageData != nil) {
            *imageData = UIImageJPEGRepresentation(self, 1);
        }
        
        return self;
    }
    
    CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                                                           (id) kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                           (id) kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                           (id) kCGImageSourceThumbnailMaxPixelSize : @(usableWidth),
                                                           (id) kCGImageSourceShouldCacheImmediately: @YES
                                                           };
    
    CGImageSourceRef src = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
    CGImageRef scaledImageRef = CGImageSourceCreateThumbnailAtIndex(src, 0, options);
    scaled = [UIImage imageWithCGImage:scaledImageRef];
    
    if (scaled == nil) {
        scaled = self;
    }
    else {
        if (imageData != nil) {
            *imageData = UIImagePNGRepresentation(scaled);
        }
    }
    
    data = nil;
    
    CGImageRelease(scaledImageRef);
    CFBridgingRelease(src);
    
    return scaled;
    
}

@end

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.segmentControl setTitle:@"None" forSegmentAtIndex:0];
    [self.segmentControl setTitle:@"PNG" forSegmentAtIndex:1];
    [self.segmentControl insertSegmentWithTitle:@"JPG" atIndex:2 animated:NO];
    [self.segmentControl insertSegmentWithTitle:@"GIF" atIndex:3 animated:NO];
    
    [self didChangeValue:self.segmentControl];
    
}

- (IBAction)didChangeValue:(UISegmentedControl *)sender {
    
    [self.imageView il_cancelImageLoading];
    
    switch (sender.selectedSegmentIndex) {
        case 1:
        {
            
            CGFloat maxWidth = self.imageView.bounds.size.width;
            
            NSURL *url = [NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/560px-PNG_transparency_demonstration_1.png"];
            
            [self.imageView il_setImageWithURL:url mutate:^UIImage * _Nonnull(UIImage * _Nonnull image) {
                
                UIImage *sized = [image fastScale:maxWidth quality:0.9f imageData:nil];
                
                return sized;
                
            } success:^(UIImage * _Nonnull image, NSURL * _Nonnull url) {
                
                self.imageView.backgroundColor = UIColor.systemBlueColor;
                
            } error:^(NSError * _Nonnull error) {
                
                NSLog(@"Error: %@", error.localizedDescription);
                
            }];
        }
            break;
        case 2:
        {
            
            [self.imageView il_setImageWithURL:[NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/3/3f/JPEG_example_flower.jpg"] success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {
                
                self.imageView.backgroundColor = UIColor.systemBackgroundColor;
                
            } error:^(NSError * _Nonnull error) {
                
                NSLog(@"Error: %@", error.localizedDescription);
                
            }];
            
        }
            break;
        case 3:
        {
            
            [self.imageView il_setImageWithURL:[NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/1/19/%27Founder_Takes_All%27_process.gif"] success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {
                
                self.imageView.backgroundColor = UIColor.systemBackgroundColor;
                
            } error:^(NSError * _Nonnull error) {
                
                NSLog(@"Error: %@", error.localizedDescription);
                
            }];
            
        }
            break;
        default:
        {
            self.imageView.image = nil;
            self.imageView.backgroundColor = UIColor.systemBackgroundColor;
            
            if (SharedImageLoader.cache != nil) {
                
                [SharedImageLoader.cache removeAllObjects];
                
            }
            
        }
            break;
    }
    
}

@end
