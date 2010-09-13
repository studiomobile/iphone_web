#import "ConnectionState.h"

@implementation ConnectionState

@synthesize connection;
@synthesize action;
@synthesize data;


- (id)initWithURL:(NSURL*)_url connection:(NSURLConnection*)_connection action:(WebAction*)_action {
	if (![super init]) return nil;
	connection = [_connection retain];
	action = [_action retain];
	data = [[ConnectionData alloc] initWithURL:_url];
	return self;
}


- (void)dealloc {
	[connection release];
	[action release];
	[data release];
	[super dealloc];
}

@end

