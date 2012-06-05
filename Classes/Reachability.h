//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

extern NSString *const kReachabilityChangedNotification;

typedef enum {
	NotReachable     = 0,
	ReachableViaWiFi = 2,
	ReachableViaWWAN = 1
} NetworkStatus;

struct sockaddr_in;
extern NSString* reachabilityString(SCNetworkReachabilityFlags flags);


@interface Reachability : NSObject
@property (nonatomic, readonly) SCNetworkReachabilityFlags flags;
@property (nonatomic, readonly) NetworkStatus status;

@property (nonatomic, readonly) BOOL reachable;
@property (nonatomic, readonly) BOOL reachableViaWWAN;
@property (nonatomic, readonly) BOOL reachableViaWiFi;

@property (nonatomic, readonly) BOOL connectionRequired;
@property (nonatomic, readonly) BOOL connectionOnDemand;
@property (nonatomic, readonly) BOOL interventionRequired;


- (id)initWithReachabilityRef:(SCNetworkReachabilityRef)ref;

+ (Reachability*)reachabilityWithHostname:(NSString*)hostname;
+ (Reachability*)reachabilityForInternetConnection;
+ (Reachability*)reachabilityWithAddress:(const struct sockaddr_in*)hostAddress;
+ (Reachability*)reachabilityForLocalWiFi;

- (BOOL)start;
- (void)stop;

@end
