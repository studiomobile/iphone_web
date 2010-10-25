//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "WebAction.h"

extern const NSString *kHTTPErrorDomain;

@interface WebService : NSObject {
	CFMutableDictionaryRef connections;
	NSTimeInterval timeout;
	NSArray *cookies;
}
@property (nonatomic, assign) NSTimeInterval timeout;

- (void)startAction:(WebAction*)action;

- (void)rememberCookies:(NSArray*)cookies;
- (void)clearCookies;

@end
