//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>

@class UIImage;

@interface FileUpload : NSObject {
	NSData *data;
	NSString *fileName;
	NSString *contentType;
}
@property (readonly) NSData *data;
@property (readonly) NSString *fileName;
@property (readonly) NSString *contentType;

+ (FileUpload*)fileUploadForJPEGImage:(UIImage*)image withFileName:(NSString*)filename quality:(float)quality;
+ (FileUpload*)fileUploadForPNGImage:(UIImage*)image withFileName:(NSString*)filename;
+ (FileUpload*)fileUploadForData:(NSData*)data withFileName:(NSString*)filename contentType:(NSString*)contentType;

@end
