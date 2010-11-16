//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

@interface WebCredentials : NSObject {
    NSString *login;
    NSString *password;
}
@property (nonatomic, readonly) NSString *login;
@property (nonatomic, readonly) NSString *password;
@property (nonatomic, readonly) NSString *basicAuthHeader;

+ (WebCredentials*)webCredentialsWithLogin:(NSString*)login password:(NSString*)password;

- (id)initWithLogin:(NSString*)login password:(NSString*)password;

@end
