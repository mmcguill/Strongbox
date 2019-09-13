//
//  Binary.h
//  Strongbox
//
//  Created by Mark on 01/11/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseXmlDomainObjectHandler.h"

NS_ASSUME_NONNULL_BEGIN

// <Binary>
    // <Key>bash_profile</Key>
    // <Value Ref="0" />
// </Binary>

@interface Binary :  BaseXmlDomainObjectHandler

- (instancetype)initWithContext:(XmlProcessingContext*)context;

@property NSString* filename;
@property uint32_t index;

@end

NS_ASSUME_NONNULL_END
