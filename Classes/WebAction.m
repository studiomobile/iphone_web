//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "WebAction.h"

@implementation WebAction

@synthesize url;
@synthesize params;
@synthesize method;
@synthesize userData;


- (id)initWithURL:(NSURL*)_url {
	return [self initWithURL:_url method:HTTP_METHOD_GET params:[WebParams params]];
}
			
- (id)initWithURL:(NSURL*)_url params:(WebParams*)_params {
	return [self initWithURL:_url method:HTTP_METHOD_GET params:_params];
}

- (id)initWithURL:(NSURL*)_url method:(HttpMethod)_method {
	return [self initWithURL:_url method:_method params:[WebParams params]];
}

- (id)initWithURL:(NSURL*)_url method:(HttpMethod)_method params:(WebParams*)_params {
	if (![super init]) return nil;
	url = [_url retain];
	method = _method;
	params = [_params retain];
	return self;
}


- (void)webService:(WebService*)service didFinishActionWithData:(ConnectionData*)data {
}


- (void)dealloc {
	[url release];
	[params release];
	[userData release];
	[super dealloc];
}

@end
