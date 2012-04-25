//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>
#import "FileUpload.h"

@interface Multipart : NSObject
@property (nonatomic, strong, readonly) NSString *boundary;
@property (nonatomic, strong, readonly) NSString *contentType;

- (id)initWithBoundary:(NSString*)boundary;

+ (NSString*)contentTypeWithBoundary:(NSString*)boundary;

- (void)appendName:(NSString*)name value:(id)value;
- (void)appendName:(NSString*)name fileUpload:(FileUpload*)upload;

- (NSData*)getData;

@end
