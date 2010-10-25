//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "NSString+Web.h"

@implementation NSString (Web)

- (NSURL*)toUrl {
    return [NSURL URLWithString:self];
}


- (NSURL*)toFileUrl {
    return [NSURL fileURLWithPath:self];
}


- (NSString*)urlEncode {
	return [self urlEncode:nil];
}


- (NSString*)urlEncode:(NSString*)additionalCharacters {
	NSString* str = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, (CFStringRef)additionalCharacters, kCFStringEncodingUTF8);
	return [str autorelease];
}


- (NSString*)urlDecode {
    return [self urlDecode:@""];
}


- (NSString*)urlDecode:(NSString*)additionalCharacters {
    NSString *str = (NSString*)CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)self, (CFStringRef)additionalCharacters);
    return [str autorelease];
}

@end
