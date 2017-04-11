//
//  EPRSong.h
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

#import <Realm/Realm.h>
#import "EPREntry.h"

@interface EPRSong : EPREntry
@property long long persistentID;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<EPRSong>
RLM_ARRAY_TYPE(EPRSong)
