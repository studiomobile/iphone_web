#import "ConnectionData.h"
#import "WebService.h"

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


- (NSString*)errorNameFromCode:(NSInteger)code {
    switch (code) {
        case 401: return @"Unauthorized";
        case 402: return @"Payment Required";
        case 403: return @"Forbidden";
    }
    return @"WebServer Error";
}


- (NSError*)error {
	if (!error && response && response.statusCode >= 400) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[self errorNameFromCode:response.statusCode]
                                                             forKey:NSLocalizedDescriptionKey];
		error = [[NSError errorWithDomain:(NSString*)kHTTPErrorDomain code:response.statusCode userInfo:userInfo] retain];
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
