//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "FileUpload.h"

@implementation FileUpload
@synthesize data;
@synthesize fileName;
@synthesize contentType;

- (id)initWithData:(NSData*)_data fileName:(NSString*)_fileName contentType:(NSString*)_contentType
{
	if (self = [super init]) {
        data = _data;
        fileName = _fileName;
        contentType = _contentType;
	}
	return self;
}

#if TARGET_OS_IPHONE
+ (FileUpload*)fileUploadWithJPEGImage:(UIImage*)image withFileName:(NSString*)filename quality:(float)quality
{
    return [self fileUploadWithData:UIImageJPEGRepresentation(image, quality) withFileName:filename contentType:@"image/jpeg"];
}

+ (FileUpload*)fileUploadWithPNGImage:(UIImage*)image withFileName:(NSString*)filename
{
    return [self fileUploadWithData:UIImagePNGRepresentation(image) withFileName:filename contentType:@"image/png"];
}
#endif

+ (FileUpload*)fileUploadWithData:(NSData*)data withFileName:(NSString*)filename contentType:(NSString*)contentType
{
    return [[FileUpload alloc] initWithData:data fileName:filename contentType:contentType];
}

+ (id)wrapDataObject:(id)object name:(NSString*)name
{
#if TARGET_OS_IPHONE
    if ([object isKindOfClass:[UIImage class]]) {
        return [FileUpload fileUploadWithPNGImage:object withFileName:name];
    }
#endif
    if ([object isKindOfClass:[NSData class]]) {
        return [FileUpload fileUploadWithData:object withFileName:name contentType:@"application/octet-stream"];
    }
    return object;
}

@end