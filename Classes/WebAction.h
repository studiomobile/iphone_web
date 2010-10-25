//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "WebParams.h"
#import "ConnectionData.h"

typedef enum  {
	HTTP_METHOD_GET,
	HTTP_METHOD_POST,
	HTTP_METHOD_PUT,
	HTTP_METHOD_DELETE
} HttpMethod;

@class WebService;

@interface WebAction : NSObject {
	NSURL *url;
	WebParams *params;
	HttpMethod method;
	NSDictionary *userData;
}
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) WebParams *params;
@property (nonatomic, assign) HttpMethod method;
@property (nonatomic, retain) NSDictionary *userData;

- (id)initWithURL:(NSURL*)url;
- (id)initWithURL:(NSURL*)url params:(WebParams*)params;
- (id)initWithURL:(NSURL*)url method:(HttpMethod)method;
- (id)initWithURL:(NSURL*)url method:(HttpMethod)method params:(WebParams*)params;

- (void)webService:(WebService*)service didFinishActionWithData:(ConnectionData*)data;

@end
