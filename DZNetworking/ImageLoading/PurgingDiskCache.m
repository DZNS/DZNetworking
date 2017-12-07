//
//  PurgingDiskCache.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 07/12/17.
//  Copyright © 2017 Dezine Zync Studios LLP. All rights reserved.
//

#import "PurgingDiskCache.h"
#import "NSString+Coders.h"

#ifndef DZAPPKIT

#import <UIKit/UIKit.h>

// The implementation for the following has been taken from SDWebImage
FOUNDATION_STATIC_INLINE NSUInteger CacheCostForImage(UIImage *image) {
#ifdef DZAPPKIT
    return image.size.height * image.size.width;
#else
    return image.size.height * image.size.width * image.scale * image.scale;
#endif
}

#endif

@interface PurgingDiskCache ()

@property (nonatomic, copy) NSString *diskPath;
@property (nonatomic, nullable) dispatch_queue_t writeQueue, readQueue;
@property (nonatomic, weak) NSFileManager *fileManager;

- (void)objectForKeyOnDisk:(NSString *)key callback:(void(^_Nullable)(UIImage *image))cb;

@end

@implementation PurgingDiskCache

- (instancetype)init {
    
    if (self = [super init]) {
        NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        self.diskPath = [paths[0] stringByAppendingPathComponent:@"purgingDiskCache"];
        self.fileManager = [NSFileManager defaultManager];
        
        // write only one file at a time to prevent memspace corruption
        self.writeQueue = dispatch_queue_create("com.DZ.PDC.writeQueue", DISPATCH_QUEUE_SERIAL);
        // read multiple files at any given point of time
        self.readQueue = dispatch_queue_create("com.DZ.PDC.readQueu", DISPATCH_QUEUE_CONCURRENT);
        
        // create the data folder on disk if it doesn't exist. Do this as early as possible
        if (![self.fileManager fileExistsAtPath:self.diskPath]) {
            [self.fileManager createDirectoryAtPath:self.diskPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    }
    
    return self;
}

- (void)objectforKey:(NSString *)key callback:(void (^ _Nullable)(UIImage * _Nullable))cb {
    
    if (!cb)
        return;
    
    key = [(NSString *)key md5];
    
    UIImage *retval = [super objectForKey:key];
    
    if (retval)
        cb(retval);
    else {
        // check with disk cache
        [self objectForKeyOnDisk:key callback:cb];
    }
    
}

- (void)setObject:(UIImage *)obj data:(NSData *)data forKey:(NSString *)key
{
    BOOL stored = NO;
    
#ifndef DZAPPKIT
    if ([obj isKindOfClass:UIImage.class]) {
        UIImage *image = (UIImage *)obj;
        NSUInteger cost = CacheCostForImage(image);
        [self setObject:obj data:data forKey:key cost:cost];
        stored = YES;
    }
#endif
    
    if (stored)
        return;
    
    key = [(NSString *)key md5];
    
    [super setObject:obj forKey:key];
        
    // store on disk cache
    // set inside our disk cache
    if (!data && obj)
        data = UIImagePNGRepresentation(obj);
    
    [self setObjectToDisk:data forKey:key];
}

- (void)setObject:(UIImage *)obj data:(NSData *)data forKey:(NSString *)key cost:(NSUInteger)g
{
    
    key = [(NSString *)key md5];
    
    [super setObject:obj forKey:key cost:g];
    
    // set inside our disk cache
    if (!data && obj)
        data = UIImagePNGRepresentation(obj); //assume PNG if we dont have the source
    
    [self setObjectToDisk:data forKey:key];
}

- (void)removeObjectForKey:(NSString *)key
{
    key = [(NSString *)key md5];
    
    [super removeObjectForKey:key];
    
    // remove from our disk cache
}

- (void)removeAllObjects
{
    [super removeAllObjects];
    
    // do not evict from disk cache.
}

#pragma mark -

- (void)setObjectToDisk:(NSData *)obj forKey:(NSString *)key {
    
    __weak typeof(self) wself = self;
    
    dispatch_async(self.writeQueue, ^{
        
        typeof(wself) sself = wself;
       
        NSString *path = [sself.diskPath stringByAppendingPathComponent:key];
        
        if ([sself.fileManager fileExistsAtPath:path]) {
            NSError *error = nil;
            [sself.fileManager removeItemAtPath:path error:&error];
            
            if (error) {
                NSLog(@"Error writing %@ to disk: %@", key, error);
                return;
            }
        }
        
        [sself.fileManager createFileAtPath:path contents:obj attributes:@{NSURLIsExcludedFromBackupKey: @(YES)}];
        
    });
    
}

- (void)objectForKeyOnDisk:(NSString *)key callback:(void (^ _Nullable)(UIImage *image))cb {
    
    if (!cb)
        return;
    
    __weak typeof(self) wself = self;
    
    dispatch_async(self.readQueue, ^{
        
        typeof(wself) sself = wself;
        
        NSString *path = [sself.diskPath stringByAppendingPathComponent:key];
        // exit early if we cannot respond back.
        
        if ([sself.fileManager fileExistsAtPath:path]) {
            NSData *data = [sself.fileManager contentsAtPath:path];
            
            UIImage *image = [[UIImage alloc] initWithData:data];
            
            cb(image);
        }
        else
            cb(nil);
        
    });
    
}

@end
