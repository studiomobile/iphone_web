//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>

@interface WebParams : NSObject
@property (nonatomic, strong, readonly) NSString *queryString;
@property (nonatomic, strong, readonly) NSData *jsonData; // NSDictionary should respond to -(NSData*)JSONData;
@property (nonatomic, strong, readonly) NSData *formData;
@property (nonatomic, strong, readonly) NSData *multipartData;
@property (nonatomic, strong, readonly) NSData *postData;

@property (nonatomic, strong, readonly) NSString *jsonContentType;
@property (nonatomic, strong, readonly) NSString *formContentType;
@property (nonatomic, strong, readonly) NSString *multipartContentType;
@property (nonatomic, strong, readonly) NSString *postContentType;

@property (nonatomic, readonly) BOOL multipart;


- (id)initWithURL:(NSURL*)url;
- (id)initWithQuery:(NSString*)query;
- (id)initWithDictionary:(NSDictionary*)dictionary;

- (id)objectForKey:(id)key;
- (void)setObject:(id)obj forKey:(id)key;
- (void)addObject:(id)obj forKey:(id)key;


- (NSURL*)appendToURL:(NSURL*)url;

@end

