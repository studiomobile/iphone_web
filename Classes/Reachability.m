//
//  This content is released under the MIT License: http://www.opensource.org/licenses/mit-license.html
//

#import "Reachability.h"
#import <netinet/in.h>


NSString *const kReachabilityChangedNotification = @"kReachabilityChangedNotification";

static void reachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info);

@implementation Reachability {
    SCNetworkReachabilityRef reachabilityRef;
    __strong id thisRef;
}

+ (Reachability*)reachabilityWithHostname:(NSString*)hostname
{
    return [[self alloc] initWithReachabilityRef:SCNetworkReachabilityCreateWithName(NULL, [hostname UTF8String])];
}

+ (Reachability *)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress
{
    return [[self alloc] initWithReachabilityRef:SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress)];
}

+ (Reachability *)reachabilityForInternetConnection
{   
    struct sockaddr_in addr;
    bzero(&addr, sizeof(addr));
    addr.sin_len    = sizeof(addr);
    addr.sin_family = AF_INET;
    return [self reachabilityWithAddress:&addr];
}

+ (Reachability*)reachabilityForLocalWiFi
{
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len         = sizeof(addr);
    addr.sin_family      = AF_INET;
    addr.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM); // defined in <netinet/in.h> as 169.254.0.0
    return [self reachabilityWithAddress:&addr];
}

- (id)initWithReachabilityRef:(SCNetworkReachabilityRef)ref
{
    if (!ref) return nil;
    if (self = [super init]) {
        reachabilityRef = ref;
    }
    return self;    
}

- (void)dealloc
{
    [self stop];
    if (reachabilityRef) {
        CFRelease(reachabilityRef);
    }
}

- (SCNetworkReachabilityFlags)flags
{
    SCNetworkReachabilityFlags flags = 0;
    SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
    return flags;
}

- (NetworkStatus)status
{
    if (self.reachable)
    {
        if (self.reachableViaWiFi) {
            return ReachableViaWiFi;
        }
#if	TARGET_OS_IPHONE
        return ReachableViaWWAN;
#endif
    }
    return NotReachable;
}


#define GETFLAGS SCNetworkReachabilityFlags flags = 0; return SCNetworkReachabilityGetFlags(reachabilityRef, &flags)

#define REACHABLE    (flags & kSCNetworkReachabilityFlagsReachable)
#define ISWWAN       (flags & kSCNetworkReachabilityFlagsIsWWAN)
#define CON_REQUIRED (flags & kSCNetworkReachabilityFlagsConnectionRequired)
#define CON_ONDEMAND (flags & (kSCNetworkReachabilityFlagsConnectionOnTraffic | kSCNetworkReachabilityFlagsConnectionOnDemand))
#define CON_TRANS    (flags & kSCNetworkReachabilityFlagsTransientConnection)
#define INT_REQUIRED (flags & kSCNetworkReachabilityFlagsInterventionRequired)

- (BOOL)reachable
{
    GETFLAGS && REACHABLE && !(CON_REQUIRED && CON_TRANS);
}

- (BOOL)reachableViaWWAN
{
#if	TARGET_OS_IPHONE
    GETFLAGS && REACHABLE && ISWWAN;
#endif
    return NO;
}

- (BOOL)reachableViaWiFi
{
#if	TARGET_OS_IPHONE
    GETFLAGS && REACHABLE && !ISWWAN;
#endif
    return NO;
}

- (BOOL)connectionRequired
{
	GETFLAGS && CON_REQUIRED;
}

- (BOOL)connectionOnDemand
{
	GETFLAGS && CON_REQUIRED && CON_ONDEMAND;
}

- (BOOL)interventionRequired
{
	GETFLAGS && CON_REQUIRED && INT_REQUIRED;
}


- (BOOL)start
{
    if (thisRef) return YES;
    // this should do a retain on ourself, so as long as we're in notifier mode we shouldn't disappear out from under ourselves
    thisRef = self;
    
    SCNetworkReachabilityContext context = { 0, NULL, NULL, NULL, NULL };
    context.info = (__bridge void *)self;
    
    if (!SCNetworkReachabilitySetCallback(reachabilityRef, reachabilityCallback, &context))
    {
#ifdef DEBUG
        NSLog(@"SCNetworkReachabilitySetCallback() failed: %s", SCErrorString(SCError()));
#endif
        return NO;
    }
    if (!SCNetworkReachabilitySetDispatchQueue(reachabilityRef, dispatch_get_main_queue()))
    {
#ifdef DEBUG
        NSLog(@"SCNetworkReachabilitySetDispatchQueue() failed: %s", SCErrorString(SCError()));
#endif
        return NO;
    }
    return YES;
}

- (void)stop
{
    SCNetworkReachabilitySetCallback(reachabilityRef, NULL, NULL);
    SCNetworkReachabilitySetDispatchQueue(reachabilityRef, NULL);
    thisRef = nil;
}


- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
#ifdef DEBUG
    NSLog(@"Reachability: %@", reachabilityString(flags));
#endif
    [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:self];
}

@end


static void reachabilityCallback(SCNetworkReachabilityRef _, SCNetworkReachabilityFlags flags, void* info)
{
    Reachability *reachability = (__bridge Reachability*)info;
    [reachability reachabilityChanged:flags];
}


NSString *reachabilityString(SCNetworkReachabilityFlags flags) 
{
    return [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
#if	TARGET_OS_IPHONE
            (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
#else
            'X',
#endif
            (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
            (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
            (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
            (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'];
}
