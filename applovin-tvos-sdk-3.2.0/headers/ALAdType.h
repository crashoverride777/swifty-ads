//
//  ALAdType.h
//  sdk
//
//  Created by Matt Szaro on 10/1/13.
//
//

#import <Foundation/Foundation.h>
#import "ALAnnotations.h"

/**
 *  This class represents the behavior of an ad.
 */

@interface ALAdType : NSObject <NSCopying>

/**
 *  @name Ad Type Identification
 */

/**
 *  String representing the name of this ad type.
 */
@property (copy, nonatomic, readonly) NSString* __alnonnull label;

/**
 *  @name Supported Ad Type Singletons
 */

/**
 *  Represents a standard advertisement.
 *
 *  @return ALAdType representing a standard advertisement.
 */
+(alnonnull ALAdType*) typeRegular;

/**
 *  Represents a rewarded video.
 *
 *  Typically, you'll award your users coins for viewing this type of ad.
 *
 *  @return ALAdType representing a rewarded video.
 */
+(alnonnull ALAdType*) typeIncentivized;

/**
 *  Retrieve an <code>NSArray</code> of all available ad size singleton instances.
 *
 *  @return <code>[NSArray arrayWithObjects: [ALAdType typeRegular], [ALAdType typeIncentivized], nil];</code>
 */
+(alnonnull NSArray*) allTypes;

@end
