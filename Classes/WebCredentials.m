//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "WebCredentials.h"
#import "NSData+Base64.h"


@implementation WebCredentials

@synthesize login;
@synthesize password;


+ (WebCredentials*)webCredentialsWithLogin:(NSString*)login password:(NSString*)password {
    return [[[self alloc] initWithLogin:login password:password] autorelease];
}


- (id)initWithLogin:(NSString*)_login password:(NSString*)_password {
    if (![super init]) return nil;
    login = [_login copy];
    password = [_password copy];
    return self;
}


- (NSString*)basicAuthHeader {
    NSString *pair = [NSString stringWithFormat:@"%@:%@", login, password];
    NSData *pairData = [pair dataUsingEncoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"Basic %@", [pairData base64EncodedString]];
}


- (void)dealloc {
    [login release];
    [password release];
    [super dealloc];
}

@end
