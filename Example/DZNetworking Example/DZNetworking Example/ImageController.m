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
    self.imageView.autoUpdateFrameOrConstraints = NO;
}

- (void)dealloc {
    
    [[SharedImageLoader cache] removeAllObjects];
    
}

- (IBAction)showStandardImage:(UIButton *)sender {
    
    self.imageView.image = nil;
    
    [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:YES];
    
    [self loadImage:@"https://upload.wikimedia.org/wikipedia/commons/1/11/HaaValley.jpg"];
    
}

- (IBAction)showSmallImage:(id)sender {
    
    [self loadImage:@"https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/HaaValley.jpg/600px-HaaValley.jpg"];
    
}

- (IBAction)showLargeImage:(id)sender {
    
    [self loadImage:@"https://bddf794624247cea6a0b-b4761d2ba0154d0278c36dbf2b3c114d.ssl.cf1.rackcdn.com/ivborw0kggoaaaansuheugaadtgaaajucayaaacfe4j3aaaacxbiwxmaaastaaaleweampwyaabg-2-21570296715866.PNG"];
    
}

- (void)loadImage:(NSString *)url {
    
    self.imageView.image = nil;
    
    [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:YES];
    
    [self.imageView il_setImageWithURL:[NSURL URLWithString:url] success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {
        
        [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:NO];
        
    } error:^(NSError * _Nonnull error) {
        
        NSLog(@"Error loading image: %@", error.localizedDescription);
        
        [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:NO];
        
    }];
    
}

@end
