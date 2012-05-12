//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "URLRequestExecutor.h"

@protocol URLRequestExecutor_NSURLConnectionDelegate
- (NSURLRequest*)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)redirect;
- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error;
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response;
- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data;
- (void)connectionDidFinishLoading:(NSURLConnection*)connection;
@end

@interface URLRequestExecutor_ConnectionProxy : NSObject <URLRequestExecutor_NSURLConnectionDelegate>
@property (nonatomic, assign) id<URLRequestExecutor_NSURLConnectionDelegate> delegate;
@end

@interface URLRequestExecutor () <URLRequestExecutor_NSURLConnectionDelegate>
@end

@implementation URLRequestExecutor {
    URLRequestExecutor_ConnectionProxy *proxy;
#if TARGET_OS_MAC
    NSURLRequest *originalRequest;
#endif
    NSURLConnection *connection;
    NSMutableData *data;
    struct {
        BOOL started : 1;
        BOOL finishWithResponse:1;
        BOOL finishWithData:1;
        BOOL failedWithError:1;
        BOOL receiveResponse : 1;
        BOOL receiveDataChunk : 1;
        BOOL handleRedirect : 1;
    } flags;
}
@synthesize delegate;
@synthesize response;
@synthesize error;

- (id)initWithRequest:(NSURLRequest*)req
{
    if (self = [super init]) {
        proxy = [URLRequestExecutor_ConnectionProxy new];
        proxy.delegate = self;
#if TARGET_OS_MAC
        originalRequest = req;
#endif
        connection = [[NSURLConnection alloc] initWithRequest:req delegate:proxy startImmediately:NO];
        [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
    return self;
}

- (void)dealloc
{
    [self cancel];
}

- (void)setDelegate:(id<URLRequestExecutorDelegate>)_delegate
{
    delegate = _delegate;
    flags.finishWithResponse = [delegate respondsToSelector:@selector(requestExecutor:didFinishWithResponse:)];
    flags.finishWithData = [delegate respondsToSelector:@selector(requestExecutor:didFinishWithData:)];
    flags.failedWithError = [delegate respondsToSelector:@selector(requestExecutor:didFailWithError:)];
    flags.receiveResponse = [delegate respondsToSelector:@selector(requestExecutor:didReceiveResponse:)];
    flags.receiveDataChunk = [delegate respondsToSelector:@selector(requestExecutor:didReceiveDataChunk:)];
    flags.handleRedirect = [delegate respondsToSelector:@selector(requestExecutor:didReceiveRedirectResponse:willSendRequest:)];
}

- (NSURLRequest*)originalRequest
{
#if TARGET_OS_MAC
    return originalRequest;
#else
    return connection.originalRequest;
#endif
}

#if TARGET_OS_IPHONE
- (NSURLRequest*)currentRequest
{
    return connection.currentRequest;
}
#endif

- (void)start
{
    if (flags.started) return;
    flags.started = YES;
    data = flags.finishWithData ? [NSMutableData new] : nil;
    [connection start];
}

- (NSURLRequest*)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)redirect
{
    if (redirect && flags.handleRedirect) {
        return [delegate requestExecutor:self didReceiveRedirectResponse:redirect willSendRequest:request];
    }
    return request;
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)_error
{
    error = _error;
    [delegate requestExecutor:self didFailWithError:error];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)_response
{
    response = _response;
    if (flags.receiveResponse) {
        [delegate requestExecutor:self didReceiveResponse:response];
    }
}

- (void)connection:(NSURLConnection*)_connection didReceiveData:(NSData*)_data
{	
    [data appendData:_data];
    if (flags.receiveDataChunk) {
        [delegate requestExecutor:self didReceiveDataChunk:_data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (flags.finishWithResponse) {
        [delegate requestExecutor:self didFinishWithResponse:self.response];
    }
    if (flags.finishWithData) {
        [delegate requestExecutor:self didFinishWithData:data];
    }
}

- (void)cancel
{
    proxy.delegate = nil;
    [connection cancel];
}

@end


@implementation URLRequestExecutor_ConnectionProxy
@synthesize delegate;
- (NSURLRequest*)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)redirect
{
    return [delegate connection:connection willSendRequest:request redirectResponse:redirect];
}
- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [delegate connection:connection didFailWithError:error];
}
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    [delegate connection:connection didReceiveResponse:response];
}
- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    [delegate connection:connection didReceiveData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    [delegate connectionDidFinishLoading:connection];
}
@end
