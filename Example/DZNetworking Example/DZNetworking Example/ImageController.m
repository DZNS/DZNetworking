//
//  ImageController.m
//  DZNetworking Example
//
//  Created by Nikhil Nigade on 08/10/19.
//  Copyright © 2019 Dezine Zync Studios LLP. All rights reserved.
//

#import "ImageController.h"
#import <DZNetworking/ImageLoader.h>

@interface ImageController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ImageController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"Image Loading";
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)dealloc {
    
    [[SharedImageLoader cache] removeAllObjects];
    
}

- (IBAction)showStandardImage:(UIButton *)sender {
    
    self.imageView.image = nil;
    
    [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:YES];
    
    [self.imageView il_setImageWithURL:[NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/1/11/HaaValley.jpg"] success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {
        
        [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:NO];
        
    } error:^(NSError * _Nonnull error) {
        
        NSLog(@"Error loading image: %@", error.localizedDescription);
        
        [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:NO];
        
    }];
    
}

- (IBAction)showSmallImage:(id)sender {
    
    self.imageView.image = nil;
    
    [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:YES];
    
    [self.imageView il_setImageWithURL:[NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/HaaValley.jpg/600px-HaaValley.jpg"] success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {
        
        [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:NO];
        
    } error:^(NSError * _Nonnull error) {
        
        NSLog(@"Error loading image: %@", error.localizedDescription);
        
        [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:NO];
        
    }];
    
}

@end
