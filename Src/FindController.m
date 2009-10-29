//
//  FindPanel.m
//  NiceFind
//
//  Created by Brian Collins on 09-10-23.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import "FindController.h"
#import "RegexKitLite.h"
#import "NSStringExtensions.h"

@implementation FindController
@synthesize query, findButton, project, resultsTable, queryField, results, buffer, gitGrep, caseSensitive, regex, spinner, resultsCount;

static FindController *fc;

+ (id)sharedInstance {
	if (fc != nil) {
				return fc;
	} else {
		return fc = [[self alloc] initWithWindowNibName:@"FindPanel"];
				[fc showWindow:self];
	}
}

- (void)goToFile:(id)sender {
	NSDictionary *row = [self.results objectAtIndex:[self.resultsTable selectedRow]];
	[[[NSApplication sharedApplication] delegate] 
	 openFiles:[NSArray arrayWithObject:[row objectForKey:@"path"]]];
	[(OakTextView *)[self.project textView] goToLineNumber:[row objectForKey:@"line"]];
	NSRange r = NSRangeFromString([row objectForKey:@"range"]);
	[[self.project textView] goToColumnNumber:[NSNumber numberWithInt:r.location + 1]];
	[[self.project textView] selectToLine:[row objectForKey:@"line"] 
								andColumn:[NSNumber numberWithInt:r.location + r.length + 1]];
}

- (BOOL)isGitProject:(OakProjectController *)p {
	return [[NSFileManager defaultManager] fileExistsAtPath:
			[[p projectDirectory] stringByAppendingPathComponent:@".git"]];
}

- (void)show {	
	[self.window makeFirstResponder:self.queryField]; 
	for (NSWindow *w in [[NSApplication sharedApplication] orderedWindows]) {
		if ([[[w windowController] className] isEqualToString: @"OakProjectController"] &&
			[[w windowController] projectDirectory]) {
			self.project = [w windowController];
			break;
		}
	}
	
	if (self.project) {
		if (![self isGitProject:self.project]) {
			[self.gitGrep setState:NSOffState];
			[self.gitGrep setHidden:YES];
		} else {
			[self.gitGrep setHidden:NO];
		}
		[self showWindow:self];		
	} else {
		[self close];
		[[[NSApplication sharedApplication] delegate] orderFrontFindPanel:self];
	}
}


- (void)windowDidLoad {
	[self.resultsTable setDoubleAction:@selector(goToFile:)];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:)
												 name:NSWindowDidBecomeKeyNotification object:self.window];
}


- (void)windowDidBecomeKey:(NSNotification *)notification {
	[self show];
}

- (void)setProject:(OakProjectController *)p {
	project = p;
}

- (id)font {
	return [[OakFontsAndColorsController sharedInstance] font];
}

- (NSString *)projectFile { // if using a tmproj file
	return [[self.project environmentVariables] objectForKey:@"TM_PROJECT_FILEPATH"];
}

- (NSString *)filePattern {
	if (filePattern)
		return filePattern;
	else
		return filePattern = [[[[NSUserDefaults standardUserDefaults] stringForKey:@"OakFolderReferenceFilePattern"] substringFromIndex:1] retain];
}

- (NSString *)folderPattern {
	if (folderPattern) 
		return folderPattern;
	else
		return folderPattern = [[[[NSUserDefaults standardUserDefaults] stringForKey:@"OakFolderReferenceFolderPattern"] substringFromIndex:1] retain];	
}

- (void)dealloc {
	[folderPattern release];
	[filePattern release];
	[super dealloc];
}

- (void)textFieldDidEndEditing:(NSTextField *)textField {
	[self performFind:self];
}

- (BOOL)useRegex {
	return [self.regex state] == NSOnState;
}

- (BOOL)useGitGrep {
	return [self.gitGrep state] == NSOnState;
}

- (BOOL)useCaseSensitive {
	return [self.caseSensitive state] == NSOnState;
}

- (NSString *)grepPath {
	return [[[NSBundle bundleForClass:self.class] resourcePath] stringByAppendingPathComponent:@"grep"];
}

- (void)find:(NSString *)q inDirectory:(NSString *)directory {
	self.query = q;
	task = [[NSTask alloc] init];
    [task setStandardOutput:[NSPipe pipe]];
    [task setStandardError:[task standardOutput]];
	

	[task setCurrentDirectoryPath:directory];
	
	NSMutableArray *args = [NSMutableArray array];
	
	if ([self useGitGrep]) {
		[task setLaunchPath:@"/usr/bin/env"];
		[args addObjectsFromArray:[NSArray arrayWithObjects:@"git", @"grep", nil]];
	} else {
		[task setLaunchPath:[self grepPath]];
		[args addObjectsFromArray:[NSArray arrayWithObjects:@"-Ir", @"--exclude-dir=.svn", @"--exclude-dir=.git", nil]];
	}
	
	if (![self useCaseSensitive]) 
		[args addObject:@"-i"];
	
	if (![self useRegex])
		[args addObject:@"-F"];
	else 
		[args addObject:@"-E"];

	
	[args addObjectsFromArray:[NSArray arrayWithObjects:@"-n", @"-e", q, directory, nil]];
	[task setArguments:args];
	
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(getData:) 
												 name:NSFileHandleReadCompletionNotification 
											   object:[[task standardOutput] fileHandleForReading]];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(taskEnded:) 
												 name:NSTaskDidTerminateNotification 
											   object:task];
    
    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
    [task launch];    
}

- (NSString *)directory {
	return [self.project projectDirectory];
}

- (IBAction)performFind:(id)sender {
	[self stopProcess];
	[self.spinner startAnimation:self];
	self.results = [NSMutableArray array];

	self.buffer = [NSMutableString string];

	[self updateResultsCount];
	[self.resultsTable reloadData];
	
	[self find:[self.queryField stringValue] inDirectory:[self directory]];
}

- (void)stopProcess {
	[self.spinner stopAnimation:self];
	[[[task standardOutput] fileHandleForReading] closeFile];
	[task terminate];
	[task release];
	task = nil;
}

- (void)taskEnded:(NSNotification *)aNotification {
	[self.spinner stopAnimation:self];
	[[[[aNotification object] standardOutput] fileHandleForReading] closeFile];
	[self addResult:self.buffer];
}
	 
- (void)getData:(NSNotification *)aNotification{
	NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length] == 0) {
		[self stopProcess];
		return;
	}
	
	[self.buffer appendString:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
	NSArray *parts = [self.buffer componentsSeparatedByString:@"\n"];
	if ([parts count] > 1) {
		for (NSString *p in [parts subarrayWithRange:NSMakeRange (0, [parts count] - 1)]) {
			[self addResult:p];
		}
		self.buffer = [NSMutableString stringWithString:[parts lastObject]];
	}

	[[aNotification object] readInBackgroundAndNotify];  
}

- (NSFont *)bold {
	return [[NSFontManager sharedFontManager] convertFont:[self font] toHaveTrait:NSBoldFontMask];
}


- (NSAttributedString *)prettifyString:(NSString *)s range:(NSString *)range {
	NSMutableAttributedString *pretty = [[[NSMutableAttributedString alloc] initWithString:s attributes:
										 [NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName]] autorelease];

	if (range) {
		NSRange r = NSRangeFromString(range);
		[pretty setAttributes:[NSDictionary dictionaryWithObject:[self bold] forKey:NSFontAttributeName] range:r];
	}
	
	return pretty;
}

- (void)updateResultsCount {
	[self.resultsCount setHidden:NO];
	int c = [self.results count];
	if (c == 1)
		[self.resultsCount setStringValue:@"1 result"];
	else 
		[self.resultsCount setStringValue:[NSString stringWithFormat:@"%d results", c]];
}

- (void)addResult:(NSString *)aResult { 
	NSArray *components = [aResult componentsSeparatedByRegex:@":\\d+:"];
	NSNumber *line = [NSNumber numberWithInt:[[aResult stringByMatching:@":(\\d+):" capture:1] intValue]];
	if ([components count] > 1) {
		NSString *filePath;
		if ([self useGitGrep]) // git returns relative paths :(
			filePath = [[self directory] stringByAppendingPathComponent:[components objectAtIndex:0]];
		else
			filePath = [components objectAtIndex:0];
		
		if ([filePath isMatchedByRegex:[self filePattern]] ||
			[[filePath stringByDeletingLastPathComponent] isMatchedByRegex:[self folderPattern]]) {
			return;
		}			
		
		for (NSString *range in [[components objectAtIndex:1] rangesOfString:self.query caseless:![self useCaseSensitive] regex:[self useRegex]]) {
			[self.results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									 [filePath lastPathComponent], @"file",
									 filePath, @"path",
									 line, @"line",
									 range, @"range",
									 [self prettifyString:[components objectAtIndex:1] range:range], @"match", nil]];
			[self.resultsTable reloadData];
			[self updateResultsCount];
		}
		[self.resultsTable reloadDataForRowIndexes:nil columnIndexes:nil];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [self.results count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return [[self.results objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
}

@end
