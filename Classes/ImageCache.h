//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#define IMAGE UIImage

#else

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>
#define IMAGE NSImage

#endif

@class ImageCache;

typedef void (^ImageCacheCallback)(ImageCache *cache, NSURL *url, IMAGE *image);
typedef void (^ImageCacheErrback)(ImageCache *cache, NSURL *url, NSError *error);

@interface ImageCache : NSObject
@property (nonatomic, assign) BOOL holdImagesInMemory;

- (id)initWithCacheFolderPath:(NSString*)path;

- (IMAGE*)imageWithURL:(NSURL*)url callback:(ImageCacheCallback)callback errback:(ImageCacheErrback)errback;

- (BOOL)updateImageData:(NSData*)data forURL:(NSURL*)url;

- (BOOL)removeImageWithURL:(NSURL*)url;

- (BOOL)removeAll;

- (void)freeMemory;

@end
