//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "WebParams.h"
#import "FileUpload.h"
#import "Multipart.h"

#define IS_FILEUPLOAD(value) [value isKindOfClass:[FileUpload class]]

static NSString *encodeQueryField(id value)
{
    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)[value description], NULL, CFSTR("\"%;/?:@&=+$,[]#!'()*"), kCFStringEncodingUTF8));
}

static NSString *decodeQueryField(NSString *field)
{
    return CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(NULL, (__bridge CFStringRef)field, CFSTR("")));
}

typedef void (^Visitor)(NSString *name, id value);

static void visit(Visitor visitor, NSString *name, id value)
{
    if ([value conformsToProtocol:@protocol(NSFastEnumeration)]) {
        for (id v in value) {
            visit(visitor, name, v);
        }
    } else if (value) {
        visitor(name, value);
    }
}

@implementation WebParams {
	NSMutableDictionary *params;
    NSString *_boundary;
}
@synthesize multipart;

- (id)initWithURL:(NSURL*)url
{
    return [self initWithQuery:url.query];
}

- (id)initWithQuery:(NSString*)query
{
    NSMutableDictionary *values = [NSMutableDictionary new];
    for (NSString *kv in [query componentsSeparatedByString:@"&"]) {
        NSInteger idx = [kv rangeOfString:@"="].location;
        if (NSNotFound == idx) continue;
        NSString *k = decodeQueryField([kv substringToIndex:idx]);
        NSString *v = decodeQueryField([kv substringFromIndex:idx+1]);
        [values setObject:v forKey:k];
    }
    return [self initWithDictionary:values];
}

- (id)initWithDictionary:(NSDictionary*)dictionary
{
    if (self = [super init]) {
        params = [NSMutableDictionary new];
        for (id name in dictionary) {
            [self addObject:[dictionary objectForKey:name] forKey:name];
        }
    }
	return self;
}

- (id)init
{
    return [self initWithDictionary:[NSDictionary new]];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"<%@: %@>", NSStringFromClass(self.class), params];
}

- (NSString*)boundary
{
    if (!_boundary) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        _boundary = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        CFRelease(uuid);
    }
    return _boundary;
}

- (void)_each:(Visitor)visitor
{
    for (NSString *key in params.keyEnumerator) {
        visit(visitor, key, [params objectForKey:key]);
    }
}

- (id)objectForKey:(id)key
{
    return [params objectForKey:key];
}

- (void)setObject:(id)obj forKey:(id)key
{
    [params removeObjectForKey:key];
    [self addObject:obj forKey:key];
}

- (void)addObject:(id)obj forKey:(id)key
{
	if (!obj) return;
    NSMutableArray *values = [NSMutableArray new];
    visit(^(NSString *name, id value) {
        value = [FileUpload wrapDataObject:value name:name];
        multipart |= IS_FILEUPLOAD(value);
        [values addObject:value];
    }, key, obj);
    if (!values.count) return;
	NSMutableArray *container = [params objectForKey:key];
    if (container) {
        if (![container isKindOfClass:[NSMutableArray class]]) {
            container = [NSMutableArray arrayWithObject:container];
        }
        [container addObjectsFromArray:values];
    } else {
        id value = values.count > 1 ? values : [values lastObject];
        [params setObject:value forKey:key];
    }
}

- (NSMutableString*)_query
{
	NSMutableString *query = [NSMutableString string];
    [self _each:^(NSString *name, id value) {
        if (IS_FILEUPLOAD(value)) return;
        [query appendString:@"&"];
        [query appendString:encodeQueryField(name)];
        [query appendString:@"="];
        [query appendString:encodeQueryField(value)];
    }];
	return query;
}

- (NSString*)queryString
{
    NSMutableString *query = [self _query];
	if (query.length) {
		[query replaceCharactersInRange:NSMakeRange(0, 1) withString:@"?"];
	}
    return query;
}

- (NSString*)jsonContentType { return @"application/json"; }
- (NSString*)formContentType { return @"application/x-www-form-urlencoded"; }
- (NSString*)multipartContentType { return [Multipart contentTypeWithBoundary:self.boundary]; }
- (NSString*)postContentType { return multipart ? self.multipartContentType : self.formContentType; }

- (NSData*)postData
{
    return multipart ? self.multipartData : self.formData;
}

- (NSData*)multipartData
{
    Multipart *multi = [[Multipart alloc] initWithBoundary:self.boundary];
    [self _each:^(NSString *name, id value) {
        [multi appendName:name value:value];
    }];
	return [multi getData];
}

- (NSData*)formData
{
	if (params.count == 0) return [NSData new];
	NSMutableString *query = [self _query];
    if (query.length) {
        [query deleteCharactersInRange:NSMakeRange(0, 1)];
    }
	return [query dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData*)JSONData
{
    BOOL canSerialize = [params respondsToSelector:@selector(JSONData)];
    if (!canSerialize) {
        NSLog(@"WARNING: class %@ should respond to selector `JSONData`, meanwhile returning nil...", NSStringFromClass([params class]));
    }
    return canSerialize ? [(id)params JSONData] : nil;
}

- (NSURL*)appendToURL:(NSURL*)url
{
	if (params.count == 0) return url;
	BOOL haveParams = [[url absoluteString] rangeOfString:@"?"].length > 0;
    NSString *query = haveParams ? [self _query] : self.queryString;
	return [NSURL URLWithString:query relativeToURL:url];
}

@end

