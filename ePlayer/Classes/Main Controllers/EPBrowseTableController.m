//
//  EPBrowseTableController.m
//  ePlayer
//
//  Created by Eric Huss on 4/14/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "EPBrowseTableController.h"
#import "EPCommon.h"
#import "EPPlayerController.h"
#import "EPTrackController.h"
#import "EPGearTableController.h"
#import "EPPlayButton.h"
#import "EPMainTabController.h"
#import "EPInfoPopup.h"
#import "RLMRealm+EPCat.h"

NSUInteger minEntriesForSections = 10;
static const NSInteger kSectionIndexMinimumDisplayRowCount = 10;
static NSString *kSpecialSectionTitle = @"SPECIAL";

@interface EPBrowseTableController ()

@end

@implementation EPBrowseTableController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Don't display search header if only a few items.
    int count = 0;
    for (NSArray *section in self.sections) {
        count += section.count;
    }
    self.wantsSearch = count > 10;
    // Misc setup.
    // This seems to be bugged in Interface Builder.
    self.tableView.sectionIndexMinimumDisplayRowCount = kSectionIndexMinimumDisplayRowCount;
    // Need this for a complex issue.  When bringing up the queue, the bottom
    // tab bar is hidden.  When returning to this table, it gets resized as
    // the tab bar is brought back.  This causes the contentOffset to get reset
    // if the table does not fill the entire screen.  That causes the search
    // header to pop back (if it was hidden).  There might be some way
    // to set this in Interface Builder, but I couldn't find it.
    self.tableView.autoresizingMask = 0;
    // Register the class for creating cells.
    UINib *entryNib = [UINib nibWithNibName:@"EntryCell" bundle:nil];
    [self.tableView registerNib:entryNib
         forCellReuseIdentifier:@"EntryCell"];
    
    if (self.wantsSearch) {
        // Add a search ability.
        // Don't need a search results controller, will use our existing table.
        self.searchController = [[UISearchController alloc]
                                 initWithSearchResultsController:nil];
        self.searchController.searchResultsUpdater = self;
        self.searchController.delegate = self;
        self.searchController.obscuresBackgroundDuringPresentation = NO;
        self.tableView.tableHeaderView = self.searchController.searchBar;
//        self.definesPresentationContext = YES;

        // Scroll down to hide the header.
        CGFloat headerHeight = self.searchController.searchBar.frame.size.height;
        self.tableView.contentOffset = CGPointMake(0, headerHeight);
    }

    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(playStatusUpdate:)
                   name:kEPPlayNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(playStatusUpdate:)
                   name:kEPStopNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(playStatusUpdate:)
                   name:kEPQueueFinishedNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(didBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
}

- (void)didBecomeActive:(UIApplication *)application
{
    [self updatePlayButtons];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.editing) {
        // Hit the back button while editing.  It won't turn editing off, so
        // do anything that needs to be done.
        [self setEditing:NO animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)playStatusUpdate:(NSNotification *)notification
{
    [self updatePlayButtons];
}

/*****************************************************************************/
#pragma mark - Table view data source
/*****************************************************************************/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EPBrowserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EntryCell"];
    assert (cell != nil);
    if (!cell.gesturesConfigured) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(playTapped:)];
        [cell.playButton addGestureRecognizer:tapGesture];
        UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc]
                                                     initWithTarget:self
                                                     action:@selector(playHeld:)];
        [cell.playButton addGestureRecognizer:longGesture];
        cell.gesturesConfigured = true;
    }
    BOOL useDateLabel = ((self.sortOrder==EPSortOrderAddDate ||
                          self.sortOrder==EPSortOrderPlayDate ||
                          self.sortOrder==EPSortOrderReleaseDate) && self.sections.count==1);
    if (!useDateLabel) {
        cell.dateLabel.text = nil;
    }

    if (self.focusAddFolder && indexPath.section==0 && indexPath.row==0) {
        // Force the keyboard to show for a new folder.
        EPBrowserCell *bcell = (EPBrowserCell *)cell;
        bcell.textView.editable = YES;
        // Unfortunately, becomeFirstResponder won't work until the view is actually up.
        // UITableView does not provide a callback *after* a cell has been added/displayed.
        [bcell.textView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.2];
    }
    
    NSArray *data;
    if (self.filteredSections) {
        data = self.filteredSections;
    } else {
        data = self.sections;
    }
    [self updateCell:cell forIndexPath:indexPath withSections:data withDateLabel:useDateLabel];
    cell.parentController = self;
    // Unfortnately, XCode seems to have hate me, and won't allow setting the
    // delegate to the object itself anymore.  It used to work.
    // File's Owner does not work.
    cell.textView.delegate = cell;
    cell.textView.userInteractionEnabled = self.renaming;
    cell.textView.returnKeyType = UIReturnKeyDone;

    return cell;
}

// Populates the labels for a cell with the values for an entry.
- (void)updateCell:(EPBrowserCell *)cell
      forIndexPath:(NSIndexPath *)indexPath
      withSections:(NSArray *)sections
     withDateLabel:(BOOL)useDateLabel
{
    EPEntry *entry = sections[indexPath.section][indexPath.row];
    cell.entry = entry;
    cell.textView.text = entry.name;
    if (entry.duration > 120*60) {
        cell.timeLabel.text = [NSString stringWithFormat:@"%ih", (int)entry.duration/(60*60)];
    } else {
        cell.timeLabel.text = [NSString stringWithFormat:@"%i:%02i",
                               (int)entry.duration/60, (int)entry.duration%60
                               ];
    }
    if (self.indexesEnabled) {
        cell.timeLabel.center = CGPointMake(258, cell.timeLabel.center.y);
    } else {
        cell.timeLabel.center = CGPointMake(279, cell.timeLabel.center.y);
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (useDateLabel) {
        cell.dateLabel.text = [self.folder sectionTitleForEntry:entry forIndex:NO];
    }
    [self updateCellButton:cell];
}

- (void)updateCellButton:(EPBrowserCell *)cell
{
    UIImage *playImage;
//    if (self.playerController.player.isPlaying) {
//        NSLog(@"update is NOW playing - Append");
//    } else {
//        NSLog(@"update is STOPPED - Play");
//    }
    if ([self.playerController shouldAppend]) {
        playImage = [UIImage imageNamed:@"add"];
    } else {
        playImage = [UIImage imageNamed:@"play2"];
    }
    [cell.playButton setImage:playImage forState:UIControlStateNormal];
}

- (void)updatePlayButtons
{
    for (EPBrowserCell *cell in self.tableView.visibleCells) {
        [self updateCellButton:cell];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    NSArray *data;
    if (self.filteredSectionTitles) {
        data = self.filteredSectionTitles;
    } else {
        data = self.sectionTitles;
    }
    if (data != nil) {
        return [data count];
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSArray *data;
    if (self.filteredSections) {
        data = self.filteredSections;
    } else {
        data = self.sections;
    }
    if (data != nil && data.count) {
        return [[data objectAtIndex:section] count];
    } else {
        return 0;
    }
}

/*****************************************************************************/
#pragma mark - Section Methods
/*****************************************************************************/

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (self.indexesEnabled) {
        NSArray *data;
        if (self.filteredSectionIndexTitles) {
            data = self.filteredSectionIndexTitles;
        } else {
            data = self.sectionIndexTitles;
        }
        if (data.count < 4) {
            return nil;
        } else {
            return data;
        }
    } else {
        return nil;
    }
}


- (NSInteger)tableView:(UITableView *)tableView
sectionForSectionIndexTitle:(NSString *)title
               atIndex:(NSInteger)index
{
    // Section indicies are the same as index indicies.
    return index;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSArray *data;
    if (self.filteredSectionTitles) {
        data = self.filteredSectionTitles;
    } else {
        data = self.sectionTitles;
    }
    if (!data) {
        return nil;
    }
    NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:@"TableSectionView"
                                                      owner:self
                                                    options:nil];
    EPTableSectionView *view = nibViews[0];
    // I would really like to be able to adjust the Sort Description Label
    // so that it is positioned right-flush.  However, it is extraordinarily
    // difficult to determine if the section indexes are currently being
    // displayed.  So for now, it is shifted over 35 pixels so it never
    // overlaps with the section indexes.
    if (data[section] == kSpecialSectionTitle) {
        view.sectionLabel.text = @"";
        view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    } else {
        view.sectionLabel.text = data[section];
    }
    if (section == 0) {
        NSString *text;
        self.topSectionView = view;
        view.sortPopup = nibViews[1];
        switch (self.sortOrder) {
            case EPSortOrderAlpha:
                text = @"Alphabetical";
                break;
            case EPSortOrderAddDate:
                text = @"Added Date";
                break;
            case EPSortOrderPlayDate:
                text = @"Play Date";
                break;
            case EPSortOrderReleaseDate:
                text = @"Release Date";
                break;
            case EPSortOrderManual:
                text = @"Manual";
                break;
        }
        view.sortDescriptionLabel.text = text;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(sortTap:)];
        [view.sortDescriptionLabel addGestureRecognizer:tap];
    } else {
        view.sortDescriptionLabel.text = nil;
    }
    return view;
}

- (void)sortTap:(UIGestureRecognizer *)recognizer
{
    EPSortPopup *popupView = self.topSectionView.sortPopup;

    popupView.blockingView.frame = self.view.window.frame;
    [self.view.window addSubview:popupView.blockingView];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(sortPopupDismiss)];
    [popupView.blockingView addGestureRecognizer:tapGesture];

    // Position the popup.
    CGPoint p = [self.tableView convertPoint:self.tableView.frame.origin toView:self.view.window];
    popupView.center = CGPointMake(self.topSectionView.frame.size.width-popupView.frame.size.width/2,
                                 popupView.frame.size.height/2+self.topSectionView.frame.origin.y+p.y);

    popupView.sortOrder = self.sortOrder;
    [popupView updateSelected];
    [self.view.window addSubview:popupView];
    // Animate the view scrolling down.
    CGFloat popViewHeight = popupView.frame.size.height;
    popupView.ep_frame_height = 0;
    [popupView setTarget:self action:@selector(sortUpdated:)];
    [UIView animateWithDuration:0.3
                     animations:^{
                         popupView.ep_frame_height = popViewHeight;
                     }];
}

- (void)sortUpdated:(EPSortPopup *)popupView
{
    self.sortOrder = popupView.sortOrder;
    [self sortPopupDismiss];
}

- (void)sortPopupDismiss
{
    EPSortPopup *popupView = self.topSectionView.sortPopup;
    CGFloat originalHeight = popupView.ep_frame_height;
    [popupView.blockingView removeFromSuperview];
    [UIView animateWithDuration:0.3
                     animations:^{
                         popupView.ep_frame_height = 0;
                     }
                     completion:^(BOOL finished) {
                         [popupView removeFromSuperview];
                         popupView.ep_frame_height = originalHeight;
                     }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSArray *data;
    if (self.filteredSectionTitles) {
        data = self.filteredSectionTitles;
    } else {
        data = self.sectionTitles;
    }
    if (data) {
        return 23;
    } else {
        return 0;
    }
}

/*****************************************************************************/
#pragma mark - Accessors
/*****************************************************************************/
- (void)setSortOrder:(EPSortOrder)sortOrder
{
    [[RLMRealm defaultRealm] epInnerTransactionWithBlock:^{
        self.folder.sortOrder = sortOrder;
    }];
    [self updateSections];
    [self.tableView reloadData];
}

- (EPSortOrder)sortOrder
{
    return self.folder.sortOrder;
}

- (EPPlayerController *)playerController
{
    return ((EPMainTabController *)self.tabBarController).playerController;
}

- (void)setIndexesEnabled:(BOOL)indexesEnabled
{
    _indexesEnabled = indexesEnabled;
    [self.tableView reloadSectionIndexTitles];
}

- (void)setFolder:(EPFolder *)folder
{
    _folder = folder;
    self.title = folder.name;
    // Set up sections.
    [self updateSections];
}

- (EPRoot *)root
{
    if (_root == nil) {
        _root = [EPRoot sharedRoot];
    }
    return _root;
}

- (void)setRoot:(EPRoot *)root
{
    _root = root;
}

- (BOOL)isRootFolder
{
    return [self.folder.uuid isEqualToString:self.root.playlists.uuid];
}

/*****************************************************************************/
#pragma mark - Searching
/*****************************************************************************/
- (void)didPresentSearchController:(UISearchController *)searchController
{
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    self.filteredSections = nil;
    self.filteredSectionTitles = nil;
    self.filteredSectionIndexTitles = nil;
    [self.tableView reloadData];
}

- (void)presentSearchController:(UISearchController *)searchController
{
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
}

- (void)willPresentSearchController:(UISearchController *)searchController
{
}


- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchText = searchController.searchBar.text;
    // Update filtered sections.
    NSPredicate *resultPred = [NSPredicate predicateWithFormat:@"name contains[cd] %@",
                               searchText];
    NSMutableArray *newSections = [NSMutableArray arrayWithCapacity:self.sections.count];
    NSMutableArray *newSectionTitles = nil;
    NSMutableArray *newSectionIndexTitles = nil;
    if (self.sectionTitles != nil) {
        newSectionTitles = [NSMutableArray arrayWithCapacity:self.sectionTitles.count];
        newSectionIndexTitles = [NSMutableArray arrayWithCapacity:self.sectionIndexTitles.count];
    }
    for (int i=0; i<self.sections.count; i++) {
        NSArray *section = self.sections[i];
        NSArray *newSection = [section filteredArrayUsingPredicate:resultPred];
        if (newSection.count) {
            [newSections addObject:newSection];
            if (newSectionTitles) {
                [newSectionTitles addObject:self.sectionTitles[i]];
                [newSectionIndexTitles addObject:self.sectionIndexTitles[i]];
            }
        }
    }
    self.filteredSections = newSections;
    self.filteredSectionTitles = newSectionTitles;
    self.filteredSectionIndexTitles = newSectionIndexTitles;
    [self.tableView reloadData];
}

/*****************************************************************************/
#pragma mark - Action Methods
/*****************************************************************************/
- (void)playHeld:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (self.popupButton != nil) {
            [self.popupButton removeFromSuperview];
            self.popupButton = nil;
        }
        CGPoint pos = [self.view convertPoint:gesture.view.center fromView:gesture.view];
        CGFloat height = 65;
        CGRect frame = CGRectMake(pos.x+80, pos.y-height/2.0f, 100, height);
        EPPopupButton *button = [[EPPopupButton alloc] initWithFrame:frame];
        if ([self.playerController shouldAppend]) {
            [button setTitle:@"Play" forState:UIControlStateNormal];
            [button addTarget:self action:@selector(popupPlay:) forControlEvents:UIControlEventTouchDown];
        } else {
            [button setTitle:@"Append" forState:UIControlStateNormal];
            [button addTarget:self action:@selector(popupAppend:) forControlEvents:UIControlEventTouchDown];
        }
        // Keep track of which cell was clicked.
        EPPlayButton *playButton = (EPPlayButton *)gesture.view;
        button.cell = playButton.browserCell;
        [self.view addSubview:button];
        self.popupButton = button;
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled ||
               gesture.state == UIGestureRecognizerStateFailed) {
        // Make a local variable so that we remove the correct one.
        EPPopupButton *button = self.popupButton;
        [UIView animateWithDuration:4.0 delay:0
                            options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             // Don't go all the way to 0 so that it stays enabled.
                             button.alpha = 0.1;
                         } completion:^(BOOL finished) {
                             [button removeFromSuperview];
                             if (self.popupButton == button) {
                                 self.popupButton = nil;
                             }
                         }];
    }
}

// User tapped the "Append" button popup.
- (void)popupAppend:(id)sender
{
    [self popupDone:^(EPEntry *entry) {
        [self appendEntry:entry];
    }];
}

- (void)popupPlay:(id)sender
{
    [self popupDone:^(EPEntry *entry) {
        [self playEntry:entry];
    }];
}

- (void)popupDone:(void (^)(EPEntry *))completion
{
    EPPopupButton *button = self.popupButton;
    button.alpha = 1.0;
    // Make it pulse before going away to give feedback that it did something.
    [UIView animateWithDuration:0.1 delay:0 options:0
                     animations:^{
                         button.transform = CGAffineTransformMakeScale(1.25, 1.25);
                     }completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.1 animations:^{
                             button.transform = CGAffineTransformMakeScale(0, 0);
                         } completion:^(BOOL finished) {
                             NSIndexPath *path = [self.tableView indexPathForCell:button.cell];
                             EPEntry *entry = self.sections[path.section][path.row];
                             [button removeFromSuperview];
                             if (self.popupButton == button) {
                                 self.popupButton = nil;
                             }
                             completion(entry);
                         }];
                     }];
}

- (void)playTapped:(UITapGestureRecognizer *)gesture
{
    // Determine which entry was tapped.
    EPPlayButton *playButton = (EPPlayButton *)gesture.view;
    if ([self.playerController shouldAppend]) {
        [self appendEntry:playButton.browserCell.entry];
    } else {
        [self playEntry:playButton.browserCell.entry];
    }
}

- (void)playEntry:(EPEntry *)entry
{
    [self.playerController playEntry:entry];
    NSString *text = [NSString stringWithFormat:@"Playing %@\n%lu entries.\n%@",
                      entry.name,
                      (unsigned long)[entry songCount],
                      formatDuration(entry.duration)];
    [EPInfoPopup showPopupWithText:text inView:self.navigationController.view];
}

- (void)appendEntry:(EPEntry *)entry
{
    [self.playerController appendEntry:entry];
    // TODO: Added vs total.
    NSString *text = [NSString stringWithFormat:@"Added %@\n%lu entries.\n%@ Added\n%@ Total",
                      entry.name,
                      (unsigned long)[entry songCount],
                      formatDuration(entry.duration),
                      formatDuration(self.root.queue.duration)];
    [EPInfoPopup showPopupWithText:text inView:self.navigationController.view];
}

/*****************************************************************************/
#pragma mark - Table view delegate
/*****************************************************************************/

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        if (indexPath.section == self.specialSection) {
            return nil;
        }
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        [self updateEditToolbarStatus];
        return;
    }
    NSArray *data;
    if (self.filteredSections) {
        data = self.filteredSections;
    } else {
        data = self.sections;
    }
    EPEntry *entry = data[indexPath.section][indexPath.row];
    if ([entry isKindOfClass:[EPFolder class]]) {
        EPBrowseTableController *controller = [[EPBrowseTableController alloc] initWithStyle:UITableViewStylePlain];
        controller.folder = (EPFolder *)entry;
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        // A song.
        EPTrackController *controller = [self.tabBarController.storyboard instantiateViewControllerWithIdentifier:@"TrackController"];
        [controller loadSong:(EPSong *)entry];
        controller.trackSummary.infoButton.hidden = YES;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

//- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return indexPath;
//}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        [self updateEditToolbarStatus];
    }
}


- (void)updateSections
{
    NSArray *sortedEntries = [self.folder sortedEntries];
    self.specialSection = -1;
    // With a small number of entries, sections are a pain.
    if (self.sortOrder!=EPSortOrderManual &&
        sortedEntries.count > minEntriesForSections) {
        NSMutableArray *sections = [[NSMutableArray alloc] init];
        self.sections = sections;
        self.sectionTitles = [[NSMutableArray alloc] init];
        self.sectionIndexTitles = [[NSMutableArray alloc] init];
        NSMutableArray *currentSection = nil;
        NSString *currentSectionTitle = nil;
        for (EPEntry *entry in sortedEntries) {
            NSString *sectionTitle = [self.folder sectionTitleForEntry:entry forIndex:NO];
            // Is this entry a new section?
            if (currentSection == nil || [sectionTitle compare:currentSectionTitle]!=NSOrderedSame) {
                currentSectionTitle = sectionTitle;
                [self.sectionTitles addObject:sectionTitle];
                currentSection = [[NSMutableArray alloc] init];
                [sections addObject:currentSection];
                NSString *indexTitle = [self.folder sectionTitleForEntry:entry forIndex:YES];
                [self.sectionIndexTitles addObject:indexTitle];
            }
            [currentSection addObject:entry];
        }
        if (self.isRootFolder) {
            self.specialSection = self.sectionTitles.count;
            [self.sectionTitles addObject:kSpecialSectionTitle];
            currentSection = [NSMutableArray arrayWithObjects:self.root.artists,
                              self.root.albums, nil];
            [self.sections addObject:currentSection];
            [self.sectionIndexTitles addObject:@"--"];
        }
        // Don't enable indexes while editing.
        if (!self.editing) {
            self.indexesEnabled = YES;
        }
    } else {
        self.sections = [NSMutableArray arrayWithObject:
                         [NSMutableArray arrayWithArray:sortedEntries]];
        self.sectionTitles = [NSMutableArray arrayWithObject:@""];
        if (self.isRootFolder) {
            self.specialSection = self.sectionTitles.count;
            [self.sections addObject:[NSMutableArray arrayWithObjects:self.root.artists,
                                      self.root.albums, nil]];
            [self.sectionTitles addObject:kSpecialSectionTitle];
        }
        self.sectionIndexTitles = self.sectionTitles;
        self.indexesEnabled = NO;
    }
}

/*****************************************************************************/
#pragma mark - Editing Support
/*****************************************************************************/
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    if (editing) {
        [[RLMRealm defaultRealm] beginWriteTransaction];
        [self showEditToolbar];
        // Prevent the table from showing under the edit toolbar.
        self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, self.tableView.contentInset.bottom+self.editToolbar.frame.size.height, 0);
        self.indexesEnabled = NO;
        // Make sure enabled status on buttons is correct.
        [self updateEditToolbarStatus];
    } else {
        [[RLMRealm defaultRealm] commitWriteTransaction];
        [self hideEditToolbar];
        self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, self.tableView.contentInset.bottom-self.editToolbar.frame.size.height, 0);
        self.tableView.ep_frame_height += self.editToolbar.frame.size.height;
        // Clean up.
        self.indexesEnabled = YES;
        [self setRenaming:false];
        // Re-sort in case anything was added.
        [self updateSections];
        [self.tableView reloadData];
        // Update previous tables.
        [self reloadParents];
    }
}

- (void)showEditToolbar
{
    NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:@"EditToolbar"
                                                      owner:self
                                                    options:nil];
    self.editToolbar = nibViews[0];
    EPEditToolbar *toolbar = self.editToolbar;
    [self.navigationController.view addSubview:toolbar];
    EPMainTabController *tabC = (EPMainTabController *)self.tabBarController;
    CGSize navSize = self.navigationController.view.frame.size;
    toolbar.frame = CGRectMake(0,
                               navSize.height - toolbar.frame.size.height - tabC.tabBar.frame.size.height,
                               navSize.width,
                               toolbar.frame.size.height);
    [toolbar.deleteButton addTarget:self action:@selector(delete:)
                          forControlEvents:UIControlEventTouchUpInside];
    [toolbar.cutButton addTarget:self action:@selector(cut:)
                       forControlEvents:UIControlEventTouchUpInside];
    [toolbar.cpyButton addTarget:self action:@selector(copy:)
                       forControlEvents:UIControlEventTouchUpInside];
    [toolbar.pasteButton addTarget:self action:@selector(paste:)
                         forControlEvents:UIControlEventTouchUpInside];
    [toolbar.renameButton addTarget:self action:@selector(rename:)
                          forControlEvents:UIControlEventTouchUpInside];
    [toolbar.addFolderButton addTarget:self action:@selector(addFolder:)
                             forControlEvents:UIControlEventTouchUpInside];
    [toolbar.collapseButton addTarget:self action:@selector(collapse:)
                            forControlEvents:UIControlEventTouchUpInside];
}

- (void)hideEditToolbar
{
    [self.editToolbar removeFromSuperview];
}

- (void)updateEditToolbarStatus
{
    BOOL haveSelections = self.tableView.indexPathsForSelectedRows.count != 0;
    self.editToolbar.deleteButton.enabled = haveSelections;
    self.editToolbar.cutButton.enabled = haveSelections;
    self.editToolbar.cpyButton.enabled = haveSelections;
    self.editToolbar.collapseButton.enabled = haveSelections;
    BOOL havePasteItems = playlistPasteboard.URLs.count != 0;
    self.editToolbar.pasteButton.enabled = havePasteItems;
}

- (void)reloadParents
{
    // Tell any table controllers higher in the chain to reload, just in case
    // anything changed (dates, etc.).
    for (EPBrowseTableController *controller in self.navigationController.viewControllers) {
        if (controller != self && [controller.class isSubclassOfClass:[EPBrowseTableController class]]) {
            if (controller != self) {
                [controller updateSections];
                [controller.tableView reloadData];
            }
        }
    }
}

/* Delete rows from the current view. */
- (void)deleteRows:(NSArray *)indexPaths
{
    // Determine the entries to delete.
    NSMutableArray *entriesToDelete = [NSMutableArray arrayWithCapacity:indexPaths.count];
    // Remove from sections.  I'm not sure if indexPaths is guaranteed to be
    // grouped by sections.  We need a set of indicies per section.
    // Key is NSNumber section number, value is NSIndexSet.
    NSMutableDictionary *sectionsToDelete = [NSMutableDictionary dictionaryWithCapacity:indexPaths.count];
    for (NSIndexPath *path in indexPaths) {
        // Figure out the entry being removed.
        EPEntry *entry = self.sections[path.section][path.row];
        NSLog(@"Deleting %@", entry.name);
        [entriesToDelete addObject:entry];
        // Add to the set of section data to clean up.
        NSNumber *sectionNumber = [NSNumber numberWithInteger:path.section];
        NSMutableIndexSet *indexSet = [sectionsToDelete objectForKey:sectionNumber];
        if (indexSet == nil) {
            indexSet = [[NSMutableIndexSet alloc] init];
            [sectionsToDelete setObject:indexSet forKey:sectionNumber];
        }
        [indexSet addIndex:path.row];
    }
    [self.folder removeEntries:entriesToDelete];
    // Will be committed when editing is done.

    [sectionsToDelete enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSMutableIndexSet *obj, BOOL *stop) {
        NSMutableArray *section = self.sections[key.integerValue];
        [section removeObjectsAtIndexes:obj];
        // XXX What happens if this was last entry in section?
    }];
    
    // Remove from table.
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self reloadParents];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section != self.specialSection;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.sortOrder == EPSortOrderManual) {
        return indexPath.section != self.specialSection;
    } else {
        return NO;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(nonnull NSIndexPath *)sourceIndexPath toProposedIndexPath:(nonnull NSIndexPath *)proposedDestinationIndexPath
{
    // TODO: Prevent mixing of folders and songs.
    return proposedDestinationIndexPath;
}

// Moving is only supported in manual sorting method.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    // Figure out the entry being moved.
    EPEntry *entry = self.sections[fromIndexPath.section][fromIndexPath.row];
    NSUInteger sourceIndex = fromIndexPath.row;
    NSUInteger destIndex = toIndexPath.row;
    // Since folders appear before songs, adjust the index.
    if ([entry.class isSubclassOfClass:[EPSong class]]) {
        sourceIndex -= self.folder.folders.count;
        destIndex -= self.folder.folders.count;
        [self.folder moveSongAtIndex:sourceIndex toIndex:destIndex];
    } else {
        [self.folder moveFolderAtIndex:sourceIndex toIndex:destIndex];
    }

    // Update sections.
    NSMutableArray *section = self.sections[fromIndexPath.section];
    [section removeObjectAtIndex:fromIndexPath.row];
    [section insertObject:entry atIndex:toIndexPath.row];
    // XXX What happens if this was last entry in section?
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
    // Unfortunately looks like can't have StyleInsert with multiple selection.
    //    if (self.showingControlCells && indexPath.section == 0) {
    //        if (indexPath.row == 1) {
    //            // Insert new folder cell.
    //            return UITableViewCellEditingStyleInsert;
    //        } else {
    //            return UITableViewCellEditingStyleNone;
    //        }
    //    } else {
    //        // Existing cell.
    //        return UITableViewCellEditingStyleNone;
    //    }
}

/*****************************************************************************/
#pragma mark - Insert Cell/Text Field
/*****************************************************************************/


- (void)addFolderWithText:(NSString *)text
{
    // New folder.
    EPFolder *folder = [EPFolder folderWithName:text
                                      sortOrder:EPSortOrderManual
                                    releaseDate:[NSDate distantPast]
                                        addDate:[NSDate date]
                                       playDate:[NSDate distantPast]];
    // Insert into the parent folder.
    [self.folder insertFolder:folder atIndex:0];
    // Add to sections.  This will get resorted later.
    NSMutableArray *section;
    if (self.sections.count) {
        section = self.sections[0];
    } else {
        section = [NSMutableArray arrayWithCapacity:10];
        [self.sections addObject:section];
    }
    [section insertObject:folder atIndex:0];
    
    [self.tableView beginUpdates];
    // Insert the newly created folder.
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

- (void)addFolder:(id)sender
{
    self.focusAddFolder = YES;
    _renaming = YES;
    [self addFolderWithText:@""];
}

/*****************************************************************************/
#pragma mark - Rename
/*****************************************************************************/
- (void)rename:(id)sender
{
    self.renaming = !self.renaming;
}

- (void)setRenaming:(BOOL)renaming
{
    _renaming = renaming;
    self.editToolbar.renameButton.selected = renaming;
    // Enable the text fields.
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell.class isSubclassOfClass:EPBrowserCell.class]) {
            EPBrowserCell *bcell = (EPBrowserCell *)cell;
            bcell.textView.userInteractionEnabled = renaming;
        }
    }
}

- (void)rename:(EPBrowserCell *)cell to:(NSString *)newText
{
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    EPEntry *entry = self.sections[path.section][path.row];
    entry.name = newText;
    // Will save when editing done.
    if (self.focusAddFolder) {
        // Unfocus.
        self.focusAddFolder = NO;
        self.renaming = NO;
    }
}

/*****************************************************************************/
#pragma mark - Cut/Copy/Paste
/*****************************************************************************/

- (void)delete:(id)sender
{
    // Display a confirmation.
    NSString *title = [NSString stringWithFormat:@"Really delete %lu items?",
                       (unsigned long)self.tableView.indexPathsForSelectedRows.count];
    UIActionSheet *sheet = [[UIActionSheet alloc]
                            initWithTitle:title
                            delegate:self
                            cancelButtonTitle:@"Cancel"
                            destructiveButtonTitle:@"Delete"
                            otherButtonTitles:nil];
    [sheet showFromTabBar:self.tabBarController.tabBar];
    
}

//UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    } else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        NSString *name = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([name compare:@"Delete"] == NSOrderedSame) {
            [self deleteRows:[self.tableView indexPathsForSelectedRows]];
        } else if ([name compare:@"Collapse"] == NSOrderedSame) {
            [self collapseRows:[self.tableView indexPathsForSelectedRows]];
        }
    }
}

- (void)cut:(id)sender
{
    NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
    [self doCopyWithCut:YES];
    // Remove these entries (shallow).
    [self deleteRows:indexPaths];
}


- (void)clearCutFolder
{
    // Make a copy so we can iterate over them after removing them from the folder.
    [self.root.cut removeAllEntries];
}

- (void)copy:(id)sender
{
    [self doCopyWithCut:NO];
}

- (void)doCopyWithCut:(BOOL)doCut
{
    [self clearCutFolder];
    NSMutableArray *copyItems = [NSMutableArray arrayWithCapacity:self.tableView.indexPathsForSelectedRows.count];
    for (NSIndexPath *path in self.tableView.indexPathsForSelectedRows) {
        // Figure out the entry being copied.
        EPEntry *entry = self.sections[path.section][path.row];
        [copyItems addObject:entry.url];
        // Clear the current selection.
        [self.tableView deselectRowAtIndexPath:path animated:YES];
        if (doCut) {
            // Move entry to the cut folder.
            [self.root.cut addEntry:entry];
        }
    }
    playlistPasteboard.URLs = copyItems;
    [self updateEditToolbarStatus];
}

- (void)paste:(id)sender
{
    NSUInteger count = 0;
    for (NSURL *objURI in playlistPasteboard.URLs) {
        if (objURI && [objURI.scheme isEqualToString:@"ePlayer"]) {
            NSLog(@"Paste URL %@", objURI);
            NSArray *components = objURI.pathComponents;
            if (components.count == 3) {
                EPEntry *entry = nil;
                NSString *type = components[1];
                if ([type isEqualToString:@"Folder"]) {
                    entry = [EPFolder objectForPrimaryKey:components[2]];
                } else if ([type isEqualToString:@"Song"]) {
                    entry = [EPSong objectForPrimaryKey:components[2]];
                }
                if (entry) {
                    entry = [self checkPasteCycle:entry];
                    [self.folder addEntry:entry];
                    [self.root.cut removeEntry:entry];
                    count += 1;
                } else {
                    NSLog(@"Could not find %@", objURI);
                }
            } else {
                NSLog(@"Invalid paste URL: %@", objURI);
            }
        } else {
            NSLog(@"Not a valid paste URL: %@", objURI);
        }
    }
    // Clear out the cut folder in case we aren't pasting from there.
    [self clearCutFolder];
    [self updateSections];
    [self.tableView reloadData];
    // Display a little popup that indicates how many entries pasted.
    NSString *text = [NSString stringWithFormat:@"Pasted %lu items.", (unsigned long)count];
    [EPInfoPopup showPopupWithText:text inView:self.navigationController.view];
}

- (EPEntry *)checkPasteCycle:(EPEntry *)entry
{
    // This may not be perfect, but seems to work well enough.
    if ([entry.class isSubclassOfClass:[EPFolder class]]) {
        EPFolder *folder = (EPFolder *)entry;
        // Verify that this is not self or any parents of self.
        folder = [self fixCycles:folder];
        return folder;
    } else {
        // XXX: Make a copy if it already exists in the current folder?
        return entry;
    }
}

- (EPFolder *)fixCycles:(EPFolder *)folder
{
    if ([self folder:folder inParents:self.folder]) {
        NSLog(@"Cycle: Clone %@", folder.name);
        folder = [folder copy];
        folder.name = [NSString stringWithFormat:@"%@ Copy", folder.name];
    }
    // Verify no sub-folders in folder are a parent.
    NSUInteger index = 0;
    for (EPFolder *subfolder in folder.folders) {
        EPFolder *newFolder = [self fixCycles:subfolder];
        if (newFolder != subfolder) {
            [folder replaceFolderAtIndex:index withFolder:newFolder];
        }
        index += 1;
    }
    return folder;
}

- (BOOL)folder:(EPFolder *)folder inParents:(EPFolder *)inFolder
{
    if (folder == inFolder) {
        return YES;
    }
    if ([inFolder.parents epRealmContainsObject:folder]) {
        return YES;
    }
    for (EPFolder *parent in inFolder.parents) {
        if ([self folder:folder inParents:parent]) {
            return YES;
        }
    }
    return NO;
}

/*****************************************************************************/
#pragma mark - Collapse
/*****************************************************************************/

- (void)collapse:(id)sender
{
    // Verify that all selections are folders.
    for (NSIndexPath *path in self.tableView.indexPathsForSelectedRows) {
        EPEntry *entry = self.sections[path.section][path.row];
        if (![entry.class isSubclassOfClass:[EPFolder class]]) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Operation Not Permitted"
                                  message:@"You may only collapse folders."
                                  delegate:nil
                                  cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    // Display a confirmation.
    NSString *title = [NSString stringWithFormat:@"Really collapse %lu folders?",
                       (unsigned long)self.tableView.indexPathsForSelectedRows.count];
    UIActionSheet *sheet = [[UIActionSheet alloc]
                            initWithTitle:title
                            delegate:self
                            cancelButtonTitle:@"Cancel"
                            destructiveButtonTitle:@"Collapse"
                            otherButtonTitles:nil];
    [sheet showFromTabBar:self.tabBarController.tabBar];
    
}

- (void)collapseRows:(NSArray *)indexPaths
{
    for (NSIndexPath *path in indexPaths) {
        EPFolder *folder = self.sections[path.section][path.row];
        [self.folder addFolders:folder.folders];
        [self.folder addSongs:folder.songs];
        [self.folder removeEntry:folder];
        if (folder.parents.count == 0) {
            NSLog(@"Collapse: Permanently removing folder %@", folder.name);
        }
    }
    // Could call insertRowsAtIndexPaths for better animation.
    [self updateSections];
    [self.tableView reloadData];
}

@end
