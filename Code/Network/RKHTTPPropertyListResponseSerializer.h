//
//  RKHTTPPropertyListResponseSerializer.h
//  RestKit
//
//  Created by Oli on 20/04/2015.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import "RKHTTPResponseSerialization.h"
#import "AFURLResponseSerialization.h"

@interface RKHTTPPropertyListResponseSerializer : AFPropertyListResponseSerializer <RKHTTPResponseSerialization>

@end
