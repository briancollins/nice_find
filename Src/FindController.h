//
//  FindPanel.h
//  NiceFind
//
//  Created by Brian Collins on 09-10-23.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TextMate.h"

@interface FindController : NSWindowController {
	NSButton *findButton;
	NSTextField *queryField;
	NSOutlineView *resultsTable;
	NSTextField *resultsCount;
	
	NSMutableDictionary *results;
	NSMutableArray *foundFiles;
	int resultCount;
	
	OakProjectController *project;
	NSMutableString *buffer;
	NSButton *gitGrep;
	NSButton *regex;
	NSButton *caseSensitive;
	NSButton *lookInSelected;
	NSString *query;
	NSString *selectedFolder;
	NSProgressIndicator *spinner;
	NSTask *task;
	NSString *filePattern;
	NSString *folderPattern;
	NSWindow *parentWindow;
	NSMutableDictionary *rememberedPositions;
}

@property (nonatomic, retain) IBOutlet NSButton *findButton;
@property (nonatomic, retain) IBOutlet NSTextField *queryField;
@property (nonatomic, retain) IBOutlet NSOutlineView *resultsTable;
@property (nonatomic, retain) IBOutlet NSButton *gitGrep;
@property (nonatomic, retain) IBOutlet NSButton *regex;
@property (nonatomic, retain) IBOutlet NSButton *caseSensitive;
@property (nonatomic, retain) IBOutlet NSButton *lookInSelected;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *spinner;
@property (nonatomic, retain) IBOutlet NSTextField *resultsCount;
@property (nonatomic, retain) NSString *query;
@property (nonatomic, retain) NSString *selectedFolder;
@property (nonatomic, retain) OakProjectController *project;

@property (nonatomic, retain) NSMutableArray *foundFiles;
@property (nonatomic, retain) NSMutableDictionary *results;

@property (nonatomic, retain) NSMutableString *buffer;
@property (nonatomic, retain) NSWindow *parentWindow;
@property (nonatomic, retain) NSMutableDictionary *rememberedPositions;

+ (id)sharedInstance;
- (IBAction)performFind:(id)sender;
- (void)stopProcess;
- (void)taskEnded:(NSNotification *)aNotification;
- (void)addResult:(NSString *)aResult;
- (void)show;
- (void)showAndMove;
- (void)updateResultsCount;
- (void)wakeUp;


@end

