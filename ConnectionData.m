#import "ConnectionData.h"

@implementation ConnectionData

@synthesize url;
@synthesize response;
@synthesize error;


- (id)initWithURL:(NSURL*)_url {
	if (![super init]) return nil;
	url = [_url retain];
	return self;
}


- (NSArray*)cookies {
	return response ? [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:url] : nil;
}


- (NSData*)responseData {
	return data;
}


- (void)appendResponseData:(NSData*)_data {
	if (!data) {
		data = [[NSMutableData alloc] initWithData:_data];
	} else {
		[data appendData:_data];
	}
}


- (NSError*)error {
	if (!error && response && response.statusCode != 200) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"WebServer Error" forKey:NSLocalizedDescriptionKey];
		return error = [[NSError errorWithDomain:@"WebServerError" code:[response statusCode] userInfo:userInfo] retain];
	}
	return error;
}


- (void)dealloc {
	[url release];
	[response release];
	[data release];
	[error release];
	[super dealloc];
}

@end
