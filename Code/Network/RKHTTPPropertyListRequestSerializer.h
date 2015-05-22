//
//  RKHTTPPropertyListRequestSerializer.h
//  RestKit
//
//  Created by Oli on 20/04/2015.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import "RKHTTPRequestSerialization.h"
#import "AFURLRequestSerialization.h"

@interface RKHTTPPropertyListRequestSerializer : AFPropertyListRequestSerializer <RKHTTPRequestSerialization>

@end
