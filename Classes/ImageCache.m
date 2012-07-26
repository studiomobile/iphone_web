//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "ImageCache.h"
#import "URLRequestExecutor.h"

@interface Callbacks : NSObject
@property (nonatomic, copy) ImageCacheCallback callback;
@property (nonatomic, copy) ImageCacheErrback errback;
@end

@interface DownloadState : NSObject
@property (nonatomic, strong) URLRequestExecutor *exec;
@property (nonatomic, strong) NSMutableArray *callbacks;
@property (nonatomic, strong) NSOutputStream *stream;
@end

@interface CacheInfo : NSObject <NSCoding>
@property (nonatomic, strong, readonly) NSString *filename;
@property (nonatomic, strong) NSString *etag;
@property (nonatomic, strong) NSString *mtime;
@property (nonatomic, strong) DownloadState *state;

- (id)initWithFileName:(NSString*)fileName;

- (void)fillInRequest:(NSMutableURLRequest*)req;
- (void)handleResponse:(NSHTTPURLResponse*)res dir:(NSString*)dir;

- (IMAGE*)getImageFrom:(NSString*)dir hold:(BOOL)hold;
- (BOOL)updateImageData:(NSData*)data dir:(NSString*)dir hold:(BOOL)hold;
- (void)clearCacheHeaders;
- (void)clearImage;

@end

static NSString* imagePath(CacheInfo *info, NSString *dir)
{
    return info.filename.length ? [dir stringByAppendingPathComponent:info.filename] : nil;
}

@interface ImageCache () <URLRequestExecutorDelegate>
@end

@implementation ImageCache {
    NSString *dir;
    NSString *cacheFilename;
    NSMutableDictionary *cache;
}
@synthesize holdImagesInMemory;

- (id)init
{
    NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *bundle = [caches stringByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier];
    return [self initWithCacheFolderPath:[bundle stringByAppendingPathComponent:@"ImageCache"]];
}

- (id)initWithCacheFolderPath:(NSString*)path
{
    if (self = [super init]) {
        NSError *error = nil;
        BOOL done = [[NSFileManager new] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (!done) {
            NSLog(@"Failed to create image cache directory: %@", error);
            return nil;
        }
        dir = path;
        cacheFilename = [dir stringByAppendingPathComponent:@"cache.data"];
        NSDictionary *data = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheFilename];
        if ([data isKindOfClass:[NSDictionary class]]) {
            cache = [data mutableCopy];
        } else {
            cache = [NSMutableDictionary new];
        }
    }
    return self;
}

- (void)_persist
{
    [NSKeyedArchiver archiveRootObject:cache toFile:cacheFilename];
}

- (CacheInfo*)_getInfoForURL:(NSURL*)url
{
    url = [url absoluteURL];
    CacheInfo *info = [cache objectForKey:url];
    if (!info) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        NSString *fileName = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        CFRelease(uuid);
        info = [[CacheInfo alloc] initWithFileName:fileName];
        [cache setObject:info forKey:url];
    }
    return info;
}

- (IMAGE*)imageWithURL:(NSURL*)url callback:(ImageCacheCallback)callback errback:(ImageCacheErrback)errback
{
    CacheInfo *info = [self _getInfoForURL:url];
    DownloadState *state = info.state;
    Callbacks *callbacks = [Callbacks new];
    callbacks.callback = callback;
    callbacks.errback = errback;
    if (!state) {
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        [info fillInRequest:req];
        state = [DownloadState new];
        state.callbacks = [NSMutableArray new];
        state.exec = [[URLRequestExecutor alloc] initWithRequest:req];
        state.exec.delegate = self;
        [state.exec start];
        info.state = state;
    }
    [state.callbacks addObject:callbacks];
    return [info getImageFrom:dir hold:holdImagesInMemory];
}

- (void)forceImageToUpdate:(NSURL*)url;
{
    CacheInfo *info = [self _getInfoForURL:url];
    [info clearCacheHeaders];
}

- (BOOL)updateImageData:(NSData*)data forURL:(NSURL*)url;
{
    CacheInfo *info = [self _getInfoForURL:url];
    BOOL updated = [info updateImageData:data dir:dir hold:holdImagesInMemory];
    if (updated) {
        [self _persist];
    }
    return updated;
}

- (BOOL)removeImageWithURL:(NSURL*)url
{
    url = [url absoluteURL];
    CacheInfo *info = [cache objectForKey:url];
    if (info != nil) {
        [cache removeObjectForKey:url];
        [self _persist];
    }
    NSString *path = imagePath(info, dir);
    return path ? [[NSFileManager new] removeItemAtPath:path error:nil] : NO;
}

- (BOOL)removeAll
{
    NSFileManager *fm = [NSFileManager new];
    [fm removeItemAtPath:dir error:nil];
    cache = [NSMutableDictionary new];
    return [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)freeMemory
{
    for (CacheInfo *info in cache.objectEnumerator) {
        [info clearImage];
    }
}

#pragma mark URLRequestExecutorDelegate

- (void)requestExecutor:(URLRequestExecutor*)executor didFinishWithResponse:(NSHTTPURLResponse*)response
{
    NSURL *url = executor.originalRequest.URL;
    CacheInfo *info = [cache objectForKey:url];
    NSArray *callbacks = info.state.callbacks;
    info.state = nil;
    if (response.statusCode == 304) return;
    [info handleResponse:response dir:dir];
    [self _persist];
    IMAGE *image = [info getImageFrom:dir hold:holdImagesInMemory];
    if (image) {
        for (Callbacks *cb in callbacks) {
            if (cb.callback) {
                cb.callback(self, url, image);
            }
        }
    }
}

- (void)requestExecutor:(URLRequestExecutor*)executor didReceiveDataChunk:(NSData*)data
{
    NSURL *url = executor.originalRequest.URL;
    CacheInfo *info = [cache objectForKey:url];
    NSOutputStream *stream = info.state.stream;
    if (!stream && info.state) {
        NSString *path = imagePath(info, dir);
        stream = info.state.stream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
        [stream open];
    }
    [stream write:data.bytes maxLength:data.length];
}

- (void)requestExecutor:(URLRequestExecutor*)executor didFailWithError:(NSError*)error
{
    NSURL *url = executor.originalRequest.URL;
    CacheInfo *info = [cache objectForKey:url];
    NSArray *callbacks = info.state.callbacks;
    info.state = nil;
    for (Callbacks *cb in callbacks) {
        if (cb.errback) {
            cb.errback(self, url, error);
        }
    }
}

@end


@implementation CacheInfo {
    IMAGE *image;
}
@synthesize etag;
@synthesize mtime;
@synthesize filename;
@synthesize state;

- (id)initWithFileName:(NSString*)fileName
{
    if (self = [super init]) {
        filename = fileName;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        etag = [decoder decodeObjectForKey:@"e"];
        mtime = [decoder decodeObjectForKey:@"m"];
        filename = [decoder decodeObjectForKey:@"f"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:etag forKey:@"e"];
    [coder encodeObject:mtime forKey:@"m"];
    [coder encodeObject:filename forKey:@"f"];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"<%@: file:%@, etag:%@, mtime:%@>", NSStringFromClass(self.class), filename, etag, mtime];
}

- (void)fillInRequest:(NSMutableURLRequest*)req
{
    if (etag)  [req addValue:etag  forHTTPHeaderField:@"If-None-Match"];
    if (mtime) [req addValue:mtime forHTTPHeaderField:@"If-Modified-Since"];
}

- (void)handleResponse:(NSHTTPURLResponse*)res dir:(NSString*)dir
{
    NSDictionary *headers = [res allHeaderFields];
    etag  = [headers objectForKey:@"ETag"];
    mtime = [headers objectForKey:@"Last-Modified"];
    image = nil;

    if (res.MIMEType) {
        NSString *uti = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)res.MIMEType, NULL));
        if (uti) {
            NSString *ext = CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)uti, kUTTagClassFilenameExtension));
            if (ext && ![ext isEqualToString:filename.pathExtension]) {
                NSString *new  = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:ext];
                NSString *from = [dir stringByAppendingPathComponent:filename];
                NSString *to   = [dir stringByAppendingPathComponent:new];
                BOOL moved     = [[NSFileManager new] moveItemAtPath:from toPath:to error:nil];
                if (moved) filename = new;
            }
        }
    }
}

- (IMAGE*)getImageFrom:(NSString *)dir hold:(BOOL)hold
{
    if (image) return image;
    NSString *path = [dir stringByAppendingPathComponent:filename];
    IMAGE *_image = path ? [[IMAGE alloc] initWithContentsOfFile:path] : nil;
    return hold ? image = _image : _image;
}

- (BOOL)updateImageData:(NSData*)data dir:(NSString*)dir hold:(BOOL)hold
{
    NSString *path = [dir stringByAppendingPathComponent:filename];
    BOOL written = [data writeToFile:path atomically:NO];
    if (!written) return NO;
    [self clearCacheHeaders];
    image = hold ? [[IMAGE alloc] initWithData:data] : nil;
    return YES;
}

- (void)clearCacheHeaders
{
    etag = nil;
    mtime = nil;
}

- (void)clearImage
{
    [self clearCacheHeaders];
    image = nil;
}

@end

@implementation DownloadState
@synthesize exec;
@synthesize stream;
@synthesize callbacks;
@end

@implementation Callbacks
@synthesize callback;
@synthesize errback;
@end
