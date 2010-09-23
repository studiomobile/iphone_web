#import "RemoteImage.h"

@implementation RemoteImage

@synthesize delegate;
@synthesize imageUrl;
@synthesize imageData;
@synthesize lastError;


+ (RemoteImage*)remoteImageWithURL:(NSURL*)url {
    return [[[self alloc] initWithURL:url] autorelease];
}


- (id)initWithURL:(NSURL*)url {
	if (![super init]) return nil;
	imageUrl = [url retain];
	return self;
}


- (void)dealloc {
	[imageUrl release];
	[activeConnection release];
	[connectionData release];
	[lastError release];
	[imageData release];
	[image release];
	[super dealloc];
}


- (UIImage*)image {
	if (!image && imageData) {
		image = [[UIImage alloc] initWithData:imageData];
	}
	return image;
}


- (BOOL)loading {
	return activeConnection != nil;
}


- (void)startLoading {
	if (imageData || activeConnection) return;
	NSURLRequest *request = [NSURLRequest requestWithURL:imageUrl];
	activeConnection = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
	[activeConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
	[activeConnection start];
}


- (void)stopLoading {
	[activeConnection cancel];
	[activeConnection release];
	activeConnection = nil;
	[connectionData release];
	connectionData = nil;
}


- (void)clear:(BOOL)full {
	[image release];
	image = nil;
	if (full) {
		[imageData release];
		imageData = nil;
	}
}

#pragma mark URL Connection Delegate

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
}


- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
	if (!connectionData) {
		connectionData = [[NSMutableData alloc] initWithData:data];
	} else {
		[connectionData appendData:data];
	}
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[imageData release];
	imageData = [connectionData retain];
	[self stopLoading];
	[delegate remoteImageDidFinishLoading:self];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self stopLoading];
	lastError = [error retain];
	[delegate remoteImage:self loadingFailedWithError:error];
}

@end
