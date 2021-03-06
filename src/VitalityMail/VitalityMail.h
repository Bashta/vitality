//
//  VitalityMail.h
//  VitalityMail
//
//  Created by Andrew Salamon on 10/8/14.
//  Copyright (c) 2014 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "METPluggableView.h"
#import "METIDtoName.h"

@class Character;
@class METInstance;
@class METMail;
@class METMessageViewController;

@interface VitalityMail : NSViewController <METPluggableView,NSTableViewDataSource,NSTableViewDataSource,NSSplitViewDelegate,METIDtoNameDelegate>
{
    Character *character;
    id<METInstance> app;
    METIDtoName *nameGetter;
    
    METMail *mail;
    
    NSMutableDictionary *namesByID;
    NSMutableArray *mailboxPairs;
    NSMutableArray *currentMessages; // messages in the currently selected mailbox(es)
    
    METMessageViewController *messageController;
    
    IBOutlet NSTableView *mailboxView;
    IBOutlet NSTableView *mailHeadersView;
    IBOutlet NSView *placeHolder; // will be replaced at runtime by a METMessageView
    IBOutlet NSSplitView *splitView;
    NSArray *minimumPaneWidths; // for the split view
}

- (BOOL)saveMailMessages:(NSArray *)messages; // Insert each message into the database
- (BOOL)saveMailBodies:(NSArray *)messages; // This will update each row in the database with the message body

- (NSArray *)messagesWithEmptyBody; ///< Used by METMail to limit extra processing to only messages that are not fully downloaded
@end
