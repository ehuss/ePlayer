//
//  EPRoot.h
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

#import <Realm/Realm.h>
#import "EPFolder.h"

@interface EPRoot : RLMObject
@property EPFolder *playlists;
@property EPFolder *artists;
@property EPFolder *albums;
@property EPFolder *cut;
@property EPFolder *queue;
// This is the index of the song that is currently playing in queue.
@property NSInteger currentQueueIndex;

// Returns the global EPRoot, loaded from disk (using the default Realm).
// If it does not exist on disk, it will be created.
+ (EPRoot *)sharedRoot:(BOOL *)wasCreated;
// Convenience if you don't care if it was created.
+ (EPRoot *)sharedRoot;

// Erases all in-memory information.
- (void)reset;

// Updates currentQueueIndex inside a transaction.
- (void)transUpdateIndex:(NSInteger)newIndex;

#ifdef TARGET_IPHONE_SIMULATOR
- (void)createSimulatedData;
#endif

@end

// This protocol enables typed collections. i.e.:
// RLMArray<EPRoot>
RLM_ARRAY_TYPE(EPRoot)
