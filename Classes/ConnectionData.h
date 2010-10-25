//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>

@interface ConnectionData : NSObject {
	NSURL *url;
	NSHTTPURLResponse *response;
	NSMutableData *data;
	NSError *error;
}
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, retain)   NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSArray *cookies;
@property (nonatomic, readonly) NSData *responseData;
@property (nonatomic, retain)   NSError *error;

- (id)initWithURL:(NSURL*)url;

- (void)appendResponseData:(NSData*)data;

@end
