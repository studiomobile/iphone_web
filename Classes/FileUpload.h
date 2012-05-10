//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface FileUpload : NSObject
@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, strong, readonly) NSString *fileName;
@property (nonatomic, strong, readonly) NSString *contentType;

#if TARGET_OS_IPHONE
+ (FileUpload*)fileUploadWithJPEGImage:(UIImage*)image withFileName:(NSString*)filename quality:(float)quality;
+ (FileUpload*)fileUploadWithPNGImage:(UIImage*)image withFileName:(NSString*)filename;
#endif
+ (FileUpload*)fileUploadWithData:(NSData*)data withFileName:(NSString*)filename contentType:(NSString*)contentType;

+ (id)wrapDataObject:(id)object name:(NSString*)name;

@end
