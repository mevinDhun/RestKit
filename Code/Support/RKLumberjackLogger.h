//
//  RKLumberjackLogger.h
//  Pods
//
//  Created by C_Lindberg,Carl on 10/31/14.
//
//

#import <Foundation/Foundation.h>

#if RKLOG_USE_COCOALUMBERJACK && __has_include(<CocoaLumberjack/CocoaLumberjack.h>)
#import "RKLog.h"

@interface RKLumberjackLogger : NSObject <RKLogging>
@end

#endif