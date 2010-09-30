#import <UIKit/UIKit.h>

@class RemoteImage;

@protocol RemoteImageDelegate <NSObject>
- (void)remoteImageDidFinishLoading:(RemoteImage*)remoteImage;
- (void)remoteImage:(RemoteImage*)remoteImage loadingFailedWithError:(NSError*)error;
@end


@interface RemoteImage : NSObject {
	id<RemoteImageDelegate> delegate;
	NSURL *imageUrl;
	NSURLConnection *activeConnection;
	NSMutableData *connectionData;
	NSError *lastError;
	NSData *imageData;
	UIImage *image;
}
@property (nonatomic, assign) id<RemoteImageDelegate> delegate;
@property (nonatomic, readonly) NSURL *imageUrl;
@property (nonatomic, readonly) NSData *imageData;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSError *lastError;
@property (nonatomic, readonly) BOOL loading;

+ (RemoteImage*)remoteImageWithURL:(NSURL*)url;

- (id)initWithURL:(NSURL*)url;

- (void)startLoading;
- (void)stopLoading;
- (void)clear:(BOOL)full;

@end
