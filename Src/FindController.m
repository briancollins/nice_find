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
@synthesize query, findButton, project, resultsTable, queryField, results, buffer, 
			gitGrep, caseSensitive, regex, spinner, resultsCount, selectedFolder, lookInSelected,
			parentWindow, rememberedPositions, foundFiles;

static FindController *fc;

+ (id)sharedInstance {
	if (fc != nil) {
				return fc;
	} else {
		return fc = [[self alloc] initWithWindowNibName:@"FindPanel"];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	[[[NSApplication sharedApplication] delegate] 
	 openFiles:[NSArray arrayWithObject:[item objectForKey:@"absolute"]]];
	[[self.project textView] goToLineNumber:[item objectForKey:@"line"]];
	NSRange r = NSRangeFromString([item objectForKey:@"range"]);
	[[self.project textView] goToColumnNumber:[NSNumber numberWithInt:r.location + 1]];
	[[self.project textView] selectToLine:[item objectForKey:@"line"] 
								andColumn:[NSNumber numberWithInt:r.location + r.length + 1]];
	return NO;
}

- (BOOL)isGitProject:(OakProjectController *)p {
	return [[NSFileManager defaultManager] fileExistsAtPath:
			[[p projectDirectory] stringByAppendingPathComponent:@".git"]];
}

- (void)showForWindow:(NSWindow *)newParent {
	if (newParent != self.parentWindow) {
		NSString *offsetString;
		NSRect rect = self.window.frame;
		if (!self.rememberedPositions)
			self.rememberedPositions = [NSMutableDictionary dictionary];

		if (self.parentWindow) {
			NSPoint offset = rect.origin;
			offset.x -= self.parentWindow.frame.origin.x;
			offset.y -= self.parentWindow.frame.origin.y;
			[self.rememberedPositions setObject:NSStringFromPoint(offset) forKey:[NSNumber numberWithInt:[self.parentWindow windowNumber]]];
		}
		
		if (offsetString = [self.rememberedPositions objectForKey:[NSNumber numberWithInt:[newParent windowNumber]]]) {
			NSPoint offset = NSPointFromString(offsetString);
			rect.origin = newParent.frame.origin;
			rect.origin.x += offset.x;
			rect.origin.y += offset.y;
		} else {
			rect.origin = newParent.frame.origin;
			rect.origin.x += 50;
			rect.origin.y += 300;
		}
		
		[self.window setFrame:rect display:NO];	
		self.parentWindow = newParent;
	}
	
	
	[self showWindow:self];
}

- (void)showAndMove {
	[self wakeUp];
	[self showForWindow:self.project.window];
}

- (void)show {
	[self wakeUp];
	[self showWindow:self];
}

- (void)wakeUp {	
	[self.window makeFirstResponder:self.queryField]; 
	self.project = nil;
	for (NSWindow *w in [[NSApplication sharedApplication] orderedWindows]) {
		if ([[[w windowController] className] isEqualToString: @"OakProjectController"] &&
			[[w windowController] projectDirectory]) {
			self.project = [w windowController];
			break;
		}
	}
	
	if (self.project) {
		self.selectedFolder = [[self.project environmentVariables] objectForKey:@"TM_SELECTED_FILE"];
		BOOL isDirectory = NO;
		[[NSFileManager defaultManager] fileExistsAtPath:self.selectedFolder isDirectory:&isDirectory];
		if (isDirectory) {
			[self.lookInSelected setHidden:NO];
		} else {
			[self.lookInSelected setHidden:YES];
		}
		
		if (![self isGitProject:self.project]) {
			[self.gitGrep setState:NSOffState];
			[self.gitGrep setHidden:YES];
		} else {
			[self.gitGrep setHidden:NO];
		}
	} else {
		[self close];
		[[[NSApplication sharedApplication] delegate] orderFrontFindPanel:self];
	}
}


- (void)windowDidLoad {
	[self.window setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
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

- (BOOL)useLookInSelected {
	return ![self.lookInSelected isHidden] && [self.lookInSelected state] == NSOnState;
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
	

	
	[args addObjectsFromArray:[NSArray arrayWithObjects:@"-n", @"-e", q, @".", nil]];
		
	
	if ([self useLookInSelected])
		[task setCurrentDirectoryPath:self.selectedFolder];
	else
		[task setCurrentDirectoryPath:directory];
		
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
	
	self.results = [NSMutableDictionary dictionary];
	self.foundFiles = [NSMutableArray array];

	self.buffer = [NSMutableString string];

	resultCount = 0;
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
	NSString *s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	if (!s) {
		[[aNotification object] readInBackgroundAndNotify];  
		return;
	}
	
	[self.buffer appendString:s];
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

	if (resultCount == 1)
		[self.resultsCount setStringValue:@"1 result"];
	else 
		[self.resultsCount setStringValue:[NSString stringWithFormat:@"%d results", resultCount]];
}


- (void)addResult:(NSDictionary *)aResult forFile:(NSString *)path {
	
	NSMutableArray *a = [self.results objectForKey:path];
	if (!a) {
		a = [NSMutableArray array];
		[self.results setObject:a forKey:path];
		[self.foundFiles addObject:path];
		[a addObject:aResult];
		[self.resultsTable reloadItem:nil];
		[self.resultsTable expandItem:path];
	} else {
		[a addObject:aResult];
		[self.resultsTable reloadItem:path];
	}

}

- (void)addResult:(NSString *)aResult { 
	NSArray *components = [aResult componentsSeparatedByRegex:@":\\d+:"];
	NSNumber *line = [NSNumber numberWithInt:[[aResult stringByMatching:@":(\\d+):" capture:1] intValue]];
	if ([components count] > 1) {
		NSString *filePath = [components objectAtIndex:0];
		NSString *absolute = [[self directory] stringByAppendingPathComponent:filePath];
		
		if ([filePath isMatchedByRegex:[self filePattern]] ||
			[[filePath stringByDeletingLastPathComponent] isMatchedByRegex:[self folderPattern]]) {
			return;
		}			
		
		for (NSString *range in [[components objectAtIndex:1] rangesOfString:self.query caseless:![self useCaseSensitive] regex:[self useRegex]]) {
			[self addResult:[NSDictionary dictionaryWithObjectsAndKeys:
							 filePath, @"path",
							 line, @"line",
							 range, @"range",
							 absolute, @"absolute",
							 [self prettifyString:[components objectAtIndex:1] range:range], @"match", nil]
					forFile:filePath];
			
			resultCount ++;
			[self updateResultsCount];
		}
	}
}



- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	if (item == nil) {
		return [self.foundFiles objectAtIndex:index];
	} else {
		return [[self.results objectForKey:item] objectAtIndex:index];
	}
}

- (int)outlineView:(NSOutlineView *)olv numberOfChildrenOfItem:(id)item {
	if (!item) {
		return [self.foundFiles count];
	} else {
		return [[self.results objectForKey:item] count];
	}
}


- (BOOL)outlineView:(NSOutlineView *)olv isItemExpandable:(id)item {
	return [item isKindOfClass:[NSString class]];
}

- (NSAttributedString *)underlineString:(NSString *)string {
	return [[[NSMutableAttributedString alloc] initWithString:string attributes:
			 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnderlineStyleSingle]
										 forKey:NSUnderlineStyleAttributeName]] autorelease];
	
}

- (id)outlineView:(NSOutlineView *)olv objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	if ([item isKindOfClass:[NSString class]]) {
		if ([[tableColumn identifier] isEqualToString:@"text"])
			return [self underlineString:item];
	} else {
		if ([[tableColumn identifier] isEqualToString:@"text"])
			return [item objectForKey:@"match"]; 
		else
			return [[item objectForKey:@"line"] stringValue];

	}
	
	return nil;
	
}

@end
