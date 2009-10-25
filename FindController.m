//
//  FindPanel.m
//  NiceFind
//
//  Created by Brian Collins on 09-10-23.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import "FindController.h"
#import "RegexKitLite.h"

@implementation FindController
@synthesize query, findButton, project, resultsTable, results, buffer;

- (void)windowDidLoad {
	[self.window makeKeyAndOrderFront:self];
}

- (void)textFieldDidEndEditing:(NSTextField *)textField {
	[self performFind:self];
}


- (void)find:(NSString *)q inDirectory:(NSString *)directory {
	NSTask *task = [[NSTask alloc] init];
    [task setStandardOutput:[NSPipe pipe]];
    [task setStandardError:[task standardOutput]];
    [task setLaunchPath:@"/usr/bin/grep"];
    [task setArguments:[NSArray arrayWithObjects:@"-nr", q, directory,nil]];
	
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(getData:) 
												 name:NSFileHandleReadCompletionNotification 
											   object:[[task standardOutput] fileHandleForReading]];
    
    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
    [task launch];    
}

- (IBAction)performFind:(id)sender {
	self.results = [NSMutableArray array];
	self.buffer = [NSMutableString string];
	[self find:[self.query stringValue] inDirectory:[self.project projectDirectory]];
}
	 
- (void)getData:(NSNotification *)aNotification{
	NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];

	if ([data length]) {
		[self.buffer appendString:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
		NSArray *parts = [self.buffer componentsSeparatedByString:@"\n"];
		if ([parts count] > 1) {
			self.buffer = [NSMutableString stringWithString:[parts objectAtIndex:1]];
			[self addResult:[parts objectAtIndex:0]];
		}
	} else {
		//[self stopProcess];
	}
	
	[[aNotification object] readInBackgroundAndNotify];  
}
		 
- (void)addResult:(NSString *)aResult {
	NSArray *components = [aResult componentsSeparatedByRegex:@":\\d+:"];
	if ([components count] > 1) {
		[self.results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [components objectAtIndex:0], @"file", 
								 [components objectAtIndex:1], @"match", nil]];
		[self.resultsTable reloadData];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [self.results count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return [[self.results objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
	NSLog(@"%@", [self.results objectAtIndex:rowIndex]); 
}

@end
