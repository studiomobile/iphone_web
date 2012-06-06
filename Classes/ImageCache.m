//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "ImageCache.h"
#import "URLRequestExecutor.h"

@interface Callbacks : NSObject
@property (nonatomic, copy) ImageCacheCallback callback;
@property (nonatomic, copy) ImageCacheErrback errback;
@end

@interface ExecutorHolder : NSObject
@property (nonatomic, strong) URLRequestExecutor *exec;
@property (nonatomic, strong) NSMutableArray *callbacks;
@property (nonatomic, strong) NSOutputStream *stream;
@end

@interface CacheInfo : NSObject <NSCoding>
@property (nonatomic, strong, readonly) NSString *filename;
@property (nonatomic, strong) NSString *etag;
@property (nonatomic, strong) NSString *mtime;
@property (nonatomic, strong) IMAGE *image;
@property (nonatomic, strong) ExecutorHolder *holder;

- (id)initWithFileName:(NSString*)fileName;

- (IMAGE*)loadImageFromDir:(NSString*)dir hold:(BOOL)hold;

@end

static NSString* pathForInfo(CacheInfo *info, NSString *dir);
static NSString* genFileName(NSString *dir);

@interface ImageCache () <URLRequestExecutorDelegate>
@property (atomic, assign) BOOL dirty;
@end

@implementation ImageCache {
    NSString *dir;
    NSString *cacheFilename;
    NSMutableDictionary *cache;
}
@synthesize holdImagesInMemory;
@synthesize dirty=_dirty;

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
        NSFileManager *fm = [NSFileManager new];
        BOOL done = [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (!done) {
            NSLog(@"Failed to create image cache directory: %@", error);
            return nil;
        }
        dir = path;
        cacheFilename = [dir stringByAppendingPathComponent:@"cache.data"];
        NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:cacheFilename];
        if ([data isKindOfClass:[NSDictionary class]]) {
            cache = [data mutableCopy];
        } else {
            cache = [NSMutableDictionary new];
        }
    }
    return self;
}

- (CacheInfo*)_createInfoForURL:(NSURL*)url
{
    CacheInfo *info = [[CacheInfo alloc] initWithFileName:genFileName(dir)];
    [cache setObject:info forKey:url];
    self.dirty = YES;
    return info;
}

- (void)_startExecWithURL:(NSURL*)url info:(CacheInfo*)info callbacks:(Callbacks*)callbacks
{
    ExecutorHolder *holder = info.holder;
    if (!holder) {
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        if (info.etag)  [req addValue:info.etag  forHTTPHeaderField:@"If-None-Match"];
        if (info.mtime) [req addValue:info.mtime forHTTPHeaderField:@"If-Modified-Since"];
        holder = [ExecutorHolder new];
        holder.callbacks = [NSMutableArray new];
        holder.exec = [[URLRequestExecutor alloc] initWithRequest:req];
        holder.exec.delegate = self;
        [holder.exec start];
        info.holder = holder;
    }
    [holder.callbacks addObject:callbacks];
}

- (IMAGE*)imageWithURL:(NSURL*)url callback:(ImageCacheCallback)callback errback:(ImageCacheErrback)errback
{
    CacheInfo *info = [cache objectForKey:url];
    if (!info) {
        info = [self _createInfoForURL:url];
    }
    IMAGE *image = info.image;
    if (!image) {
        image = [info loadImageFromDir:dir hold:holdImagesInMemory];
    }
    Callbacks *callbacks = [Callbacks new];
    callbacks.callback = callback;
    callbacks.errback = errback;
    [self _startExecWithURL:url info:info callbacks:callbacks];
    return image;
}

- (BOOL)updateImageData:(NSData*)data forURL:(NSURL*)url;
{
    CacheInfo *info = [cache objectForKey:url];
    if (!info) {
        info = [self _createInfoForURL:url];
    }
    info.etag = nil;
    info.mtime = nil;
    self.dirty = YES;
    return [data writeToFile:pathForInfo(info, dir) atomically:NO];
}

- (BOOL)removeImageWithURL:(NSURL*)url
{
    CacheInfo *info = [cache objectForKey:url];
    [cache removeObjectForKey:url];
    if (info != nil) {
        self.dirty = YES;
    }
    NSString *path = pathForInfo(info, dir);
    return path ? [[NSFileManager new] removeItemAtPath:path error:nil] : NO;
}

- (BOOL)removeAll
{
    NSFileManager *fm = [NSFileManager new];
    [fm removeItemAtPath:dir error:nil];
    cache = [NSMutableDictionary new];
    self.dirty = YES;
    return [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)freeMemory
{
    for (CacheInfo *info in cache.objectEnumerator) {
        info.image = nil;
    }
}

#pragma mark URLRequestExecutorDelegate

- (void)requestExecutor:(URLRequestExecutor*)executor didFinishWithResponse:(NSHTTPURLResponse*)response
{
    NSURL *url = executor.originalRequest.URL;
    CacheInfo *info = [cache objectForKey:url];
    ExecutorHolder *holder = info.holder;
    info.holder = nil;
    if (response.statusCode == 304) return;
    NSDictionary *headers = [response allHeaderFields];
    info.etag  = [headers objectForKey:@"ETag"];
    info.mtime = [headers objectForKey:@"Last-Modified"];
    self.dirty = ![cache writeToFile:cacheFilename atomically:NO];
    IMAGE *image = [info loadImageFromDir:dir hold:holdImagesInMemory];
    if (image) {
        for (Callbacks *callbacks in holder.callbacks) {
            if (callbacks.callback) {
                callbacks.callback(self, url, image);
            }
        }
    }
}

- (void)requestExecutor:(URLRequestExecutor*)executor didReceiveDataChunk:(NSData*)data
{
    CacheInfo *info = [cache objectForKey:executor.originalRequest.URL];
    NSOutputStream *stream = info.holder.stream;
    if (!stream && info.holder) {
        stream = info.holder.stream = [NSOutputStream outputStreamToFileAtPath:pathForInfo(info, dir) append:NO];
    }
    [stream write:data.bytes maxLength:data.length];
}

- (void)requestExecutor:(URLRequestExecutor*)executor didFailWithError:(NSError*)error
{
    NSURL *url = executor.originalRequest.URL;
    CacheInfo *info = [cache objectForKey:url];
    ExecutorHolder *holder = info.holder;
    info.holder = nil;
    for (Callbacks *callbacks in holder.callbacks) {
        if (callbacks.errback) {
            callbacks.errback(self, url, error);
        }
    }
}

@end

@implementation CacheInfo
@synthesize etag;
@synthesize mtime;
@synthesize filename;
@synthesize image;
@synthesize holder;

- (id)initWithFileName:(NSString*)fileName
{
    if (self = [super init]) {
        filename = filename;
    }
    return self;
}

- (IMAGE*)loadImageFromDir:(NSString*)dir hold:(BOOL)hold
{
    NSString *path = pathForInfo(self, dir);
    IMAGE *_image = path ? [[IMAGE alloc] initWithContentsOfFile:path] : nil;
    if (hold) {
        image = _image;
    }
    return _image;
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
@end

@implementation ExecutorHolder
@synthesize exec;
@synthesize stream;
@synthesize callbacks;
@end

@implementation Callbacks
@synthesize callback;
@synthesize errback;
@end


NSString* pathForInfo(CacheInfo *info, NSString *dir)
{
    return info.filename.length ? [dir stringByAppendingPathComponent:info.filename] : nil;
}

NSString* genFileName(NSString *dir)
{
    NSFileManager *fm = [NSFileManager new];
    NSString *path;
    NSString *name;
    do {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        name = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        CFRelease(uuid);
        path = [dir stringByAppendingPathComponent:name];
    } while ([fm fileExistsAtPath:path]);
    return name;
}
