//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>

@interface WebParams : NSObject
@property (nonatomic, readonly) NSString *queryString;
@property (nonatomic, readonly) BOOL multipart;

@property (nonatomic, readonly) NSData *jsonData; // NSDictionary should respond to -(NSString*)JSONRepresentation;
@property (nonatomic, readonly) NSData *formData;
@property (nonatomic, readonly) NSData *multipartData;

@property (nonatomic, readonly) NSData *postData;

@property (nonatomic, readonly) NSString *jsonContentType;
@property (nonatomic, readonly) NSString *formContentType;
@property (nonatomic, readonly) NSString *multipartContentType;
@property (nonatomic, readonly) NSString *postContentType;

- (id)initWithDictionary:(NSDictionary*)dictionary;

- (void)setObject:(id)obj forKey:(id)key;
- (void)addObject:(id)obj forKey:(id)key;

- (NSURL*)appendToURL:(NSURL*)url;

@end

