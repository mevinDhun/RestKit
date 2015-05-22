//
//  RKHTTPRequestSerializer.h
//  RestKit
//
//  Created by Oli on 12/04/2015.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import "AFURLRequestSerialization.h"
#import "RKHTTPRequestSerialization.h"

@interface RKHTTPRequestSerializer : AFHTTPRequestSerializer <RKHTTPRequestSerialization>

@end
