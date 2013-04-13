//
//  EPEntryTableController.m
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPPlaylistTableController.h"
#import "Models/EPModels.h"

@interface EPPlaylistTableController ()

@end

@implementation EPPlaylistTableController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.enabled = NO;
    }
    return self;
}

- (EPPlaylistTableController *)copyMusicController
{
    EPPlaylistTableController *controller = [[EPPlaylistTableController alloc] initWithStyle:UITableViewStylePlain];
    controller.managedObjectContext = self.managedObjectContext;
    controller.managedObjectModel = self.managedObjectModel;
    controller.enabled = self.enabled;
    return controller;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (!self.enabled) {
        return 0;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (!self.enabled) {
        return 0;
    }
    return self.sortedEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlaylistCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.imageView.image = [UIImage imageNamed:@"play"];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(playTapped:)];
        [cell.imageView addGestureRecognizer:tapGesture];
        cell.imageView.userInteractionEnabled = YES;
    }
    Entry *entry = [self.sortedEntries objectAtIndex:indexPath.row];
    cell.textLabel.text = entry.name;    
    return cell;
}

- (void)playTapped:(UITapGestureRecognizer *)gesture
{
    UITableViewCell *cell = (UITableViewCell *)[[[gesture view] superview] superview];
    NSIndexPath *tappedIndexPath = [self.tableView indexPathForCell:cell];
    NSLog(@"Image Tap %@", tappedIndexPath);
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Entry *entry = [self.sortedEntries objectAtIndex:indexPath.row];
    if ([entry isKindOfClass:[Folder class]]) {
        EPPlaylistTableController *controller = [self copyMusicController];
        controller.folder = (Folder *)entry;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)loadRootFolder
{
    NSFetchRequest *request = [self.managedObjectModel fetchRequestTemplateForName:@"RootFolder"];
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (results==nil || results.count==0) {
        NSLog(@"Failed to fetch root folder: %@", error);
        return;
    }
    self.folder = [results objectAtIndex:0];
    [self.tableView reloadData];
}

- (void)setFolder:(Folder *)folder
{
    _folder = folder;
    self.title = folder.name;
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    self.sortedEntries = [self.folder.entries sortedArrayUsingDescriptors:@[sortDesc]];
}

@end
