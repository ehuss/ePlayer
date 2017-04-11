//
//  EPRRoot.h
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

#import <Realm/Realm.h>
#import "EPRFolder.h"

@interface EPRRoot : RLMObject
@property EPRFolder *playlists;
@property EPRFolder *artists;
@property EPRFolder *albums;
@property EPRFolder *cut;
@property EPRFolder *queue;
@property EPRFolder *orphans;
@property NSInteger currentQueueIndex;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<EPRRoot>
RLM_ARRAY_TYPE(EPRRoot)
