//
//  RKHTTPResponseSerializer.h
//  RestKit
//
//  Created by Oli on 12/04/2015.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import "AFURLResponseSerialization.h"
#import "RKHTTPResponseSerialization.h"

@interface RKHTTPResponseSerializer : AFHTTPResponseSerializer <RKHTTPResponseSerialization>

@end
