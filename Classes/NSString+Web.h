//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>

@interface NSString (Web)

- (NSURL*)toUrl;
- (NSURL*)toFileUrl;

- (NSString*)urlEncode:(NSString*)additionalCharacters;
- (NSString*)urlEncode;

- (NSString*)urlDecode;
- (NSString*)urlDecode:(NSString*)additionalCharacters;

@end
