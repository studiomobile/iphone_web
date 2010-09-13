#import "WebService.h"
#import "ConnectionState.h"
#import "WebParams.h"

@implementation WebService

@synthesize timeout;

- (id)init {
	if (![super init]) return nil;
	connections = CFDictionaryCreateMutable(nil, 10, nil, &kCFTypeDictionaryValueCallBacks);
	timeout = 10;
	return self;
}


- (void)dealloc {
	CFRelease(connections);
	[cookies release];
	[super dealloc];
}


- (void)rememberCookies:(NSArray*)newCookies {
	[cookies release];
	cookies = [newCookies retain];
}


- (void)clearCookies {
	[cookies release];
	cookies = nil;
}


- (NSString*)methodVerb:(HttpMethod)method {
	switch (method) {
		case HTTP_METHOD_GET: return @"GET";
		case HTTP_METHOD_POST: return @"POST";
		case HTTP_METHOD_PUT: return @"PUT";
		case HTTP_METHOD_DELETE: return @"DELETE";
	}
	return nil;
}


- (NSURLRequest*)requestForAction:(WebAction*)action {
	NSURL *url = action.url;
	NSData *data = nil;
	NSString *contentType = nil;
	switch (action.method) {
		case HTTP_METHOD_GET:
			if (action.params) url = [action.params appendToURL:action.url];
			break;
		case HTTP_METHOD_POST:
		case HTTP_METHOD_PUT:
			data = action.params.postData;
			contentType = action.params.contentType;
			break;
		case HTTP_METHOD_DELETE:
			break;
	}
	NSLog(@"%@", url);
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeout];
	[request setHTTPMethod:[self methodVerb:action.method]];
	if (cookies) {
		NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
		[request setAllHTTPHeaderFields:headers];
	}
	if (data) {
		[request setHTTPBody:data];
		[request setValue:[NSString stringWithFormat:@"%d", data.length] forHTTPHeaderField:@"Content-Length"];
	}
	if (contentType) {
		[request setValue:contentType forHTTPHeaderField:@"Content-Type"];
	}
	return request;
}


- (ConnectionState*)startConnectionForAction:(WebAction*)action {
	NSURLRequest *request = [self requestForAction:action];
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
	ConnectionState *state = [[[ConnectionState alloc] initWithURL:[request URL] connection:connection action:action] autorelease];
	CFDictionarySetValue(connections, connection, state);
	[connection start];
	return state;
}


- (void)startAction:(WebAction*)action {
	[self startConnectionForAction:action];
}

#pragma mark URL Connection Delegate

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
	ConnectionState *state = nil;
	if (CFDictionaryGetValueIfPresent(connections, connection, (const void**)&state)) {
		state.data.response = httpResponse;
	} else {
		[connection cancel];
	}
}


- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
	ConnectionState *state = nil;
	if (CFDictionaryGetValueIfPresent(connections, connection, (const void**)&state)) {
		[state.data appendResponseData:data];
	} else {
		[connection cancel];
	}
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	ConnectionState *state = nil;
	if (CFDictionaryGetValueIfPresent(connections, connection, (const void**)&state)) {
		[state.action webService:self didFinishActionWithData:state.data];
		CFDictionaryRemoveValue(connections, connection);
	}
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	ConnectionState *state = nil;
	if (CFDictionaryGetValueIfPresent(connections, connection, (const void**)&state)) {
		state.data.error = error;
		[state.action webService:self didFinishActionWithData:state.data];
		CFDictionaryRemoveValue(connections, connection);
	}
}

@end
