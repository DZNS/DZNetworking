//
//  PurgingDiskCache.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 07/12/17.
//  Copyright © 2017 Dezine Zync Studios LLP. All rights reserved.
//

#import "PurgingDiskCache.h"
#import "NSString+Coders.h"
#import "UIImage+Decoded.h"

#ifndef DZAPPKIT

#import <UIKit/UIKit.h>

// The implementation for the following has been taken from SDWebImage
FOUNDATION_STATIC_INLINE NSUInteger CacheCostForImage(UIImage *image) {
    return image.size.height * image.size.width * image.scale * image.scale * 8.f;
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
        
        // write only one file at a time to prevent memspace corruption
        self.writeQueue = dispatch_queue_create("com.DZ.PDC.writeQueue", DISPATCH_QUEUE_SERIAL);
        
        weakify(self);
        dispatch_sync(self.writeQueue, ^{
            strongify(self);
            self.fileManager = [NSFileManager defaultManager];
        });
        
        // read multiple files at any given point of time
        self.readQueue = dispatch_queue_create("com.DZ.PDC.readQueue", DISPATCH_QUEUE_CONCURRENT);
        
        // create the data folder on disk if it doesn't exist. Do this as early as possible
        dispatch_sync(self.writeQueue, ^{
            strongify(self);
            [self _createLocalFolder];
        });
    }
    
    return self;
}

- (void)_createLocalFolder {
    if ([self.fileManager fileExistsAtPath:self.diskPath] == NO) {
        [self.fileManager createDirectoryAtPath:self.diskPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

#pragma mark -

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

- (void)setObject:(UIImage *)obj data:(NSData *)data forKey:(NSString *)key {
    
    if (obj == nil) {
        return [self removeObjectForKey:key];
    }
    
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

}

- (void)setObject:(UIImage *)obj data:(NSData *)data forKey:(NSString *)key cost:(NSUInteger)g
{
    
    key = [(NSString *)key md5];
    
    [super setObject:obj forKey:key cost:g];
    
    if (!data && obj) {
        data = UIImagePNGRepresentation(obj);
    }
    
    if (data != nil) {
        [self setObjectToDisk:data forKey:key];
    }
}

- (void)removeObjectForKey:(NSString *)key {
    
    [self removeObjectForKey:key memoryOnly:NO];
    
}

- (void)removeObjectForKey:(NSString *)key memoryOnly:(BOOL)memoryOnly {
    
    key = [(NSString *)key md5];
    
    [super removeObjectForKey:key];
    
    if (memoryOnly == NO) {
        // remove from our disk cache

        weakify(self);
        
        dispatch_async(self.readQueue, ^{
            
            strongify(self);
            
            NSString *path = [self.diskPath stringByAppendingPathComponent:key];
            
            NSURL *url = [NSURL fileURLWithPath:path];
            
            if ([self.fileManager fileExistsAtPath:path]) {
                
                NSFileCoordinator *coordinator = [NSFileCoordinator new];
                
                [coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:nil byAccessor:^(NSURL * _Nonnull newURL) {
                    
                    NSError *error = nil;
                    
                    if ([self.fileManager removeItemAtURL:newURL error:&error] == NO) {
                        
                        NSLog(@"Error removing file from disk cache: %@", url);
                        
                    }
                    
                }];
                
            }
            
        });
        
    }
    
}

#pragma mark -

- (void)removeAllObjects
{
    [super removeAllObjects];
    
    // do not evict from disk cache.
}

- (void)removeAllObjectsFromDisk {
    
    dispatch_sync(self.writeQueue, ^{
        
#ifdef DEBUG
        NSLog(@"Path: %@", self.diskPath);
#endif
        
        NSFileCoordinator *coordinator = [NSFileCoordinator new];
        
        __block NSError *error = nil;
                            
        [coordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:self.diskPath] options:NSFileCoordinatorWritingForDeleting error:&error byAccessor:^(NSURL * _Nonnull newURL) {
            
            if ([self.fileManager removeItemAtURL:newURL error:&error] == NO) {
#ifdef DEBUG
                NSLog(@"%@: Error deleting caches directory: %@", NSStringFromClass(self.class), error);
#endif
            }
            else {
                [self _createLocalFolder];
            }
            
        }];
        
    });
    
}

#pragma mark -

- (void)setObjectToDisk:(id)obj forKey:(NSString *)key {
    
    weakify(self);
    
    dispatch_async(self.writeQueue, ^{
        
        strongify(self);
       
        NSString *path = [self.diskPath stringByAppendingPathComponent:key];
        
        NSURL *url = [NSURL fileURLWithPath:path];
        
        NSFileCoordinator *coordinator = [NSFileCoordinator new];
        
        [coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL * _Nonnull newURL) {
           
            [self.fileManager createFileAtPath:newURL.filePathURL.absoluteString contents:obj attributes:@{NSURLIsExcludedFromBackupKey: @(YES)}];
            
        }];
        
    });
    
}

- (void)objectForKeyOnDisk:(NSString *)key callback:(void (^ _Nullable)(UIImage *image))cb {
    
    if (!cb)
        return;
    
    weakify(self);
    
    dispatch_async(self.readQueue, ^{
        
        strongify(self);
        
        NSString *path = [self.diskPath stringByAppendingPathComponent:key];
        // exit early if we cannot respond back.
        
        NSURL *url = [NSURL fileURLWithPath:path];
        
        if ([self.fileManager fileExistsAtPath:path]) {
            
            NSFileCoordinator *coordinator = [NSFileCoordinator new];
            
            [coordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:nil byAccessor:^(NSURL * _Nonnull newURL) {
               
                NSData *data = [[NSData alloc] initWithContentsOfURL:newURL];
                            
                if (data == nil) {
                    return cb(nil);
                }
                
                UIImage *image = [[UIImage alloc] initWithData:data];
                                
                // if the above throws an exception, image will still be nil
                cb(image);
                
            }];
            
        }
        else
            cb(nil);
        
    });
    
}

@end
