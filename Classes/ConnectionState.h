//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "WebAction.h"
#import "ConnectionData.h"

@interface ConnectionState : NSObject {
	NSURLConnection *connection;
	WebAction *action;
	ConnectionData *data;
}
@property (nonatomic, readonly) NSURLConnection *connection;
@property (nonatomic, readonly)	WebAction *action;
@property (nonatomic, readonly) ConnectionData *data;

- (id)initWithURL:(NSURL*)url connection:(NSURLConnection*)connection action:(WebAction*)action;

@end
