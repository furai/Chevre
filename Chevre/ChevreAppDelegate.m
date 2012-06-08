//
//  ChevreAppDelegate.m
//  Chevre
//
//  Created by Matthieu DESILE on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ChevreAppDelegate.h"
#import "Datasource.h"
#import "PreferencesWindowController.h"
#import "PreviewWindowController.h"
#import "NSString+regex.h"

@implementation ChevreAppDelegate

@synthesize window, browserViewController, dates, datesController;

+ (void) initialize
{
    /* get/set defaults */
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* defaultValues = [NSDictionary dictionaryWithObjectsAndKeys: 
                                   @"~/Pictures", @"depot", 
                                   @"~/Pictures", @"base", nil];
    [defaults registerDefaults: defaultValues];
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
{
    dates = [self getDates];
}

- (void) awakeFromNib
{
    [browserViewController setUndoManager: [[window firstResponder] undoManager]];
}

- (IBAction) openPreferencesWindow: (id) sender
{
    NSWindowController* wc = [[PreferencesWindowController alloc] init];
    [wc showWindow: self];
    //[wc autorelease];
}

- (IBAction) openPreviewWindow: (id) sender
{
    NSWindowController* wc = [[PreviewWindowController alloc] initWithDatasource: [browserViewController datasource]];
    [wc showWindow: self];
}


- (NSArray*) getDates
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* depot = [[NSUserDefaults standardUserDefaults] valueForKey: @"depot"];
    NSURL* base = [NSURL URLWithString: depot];
    NSDirectoryEnumerator* de = [fm enumeratorAtURL: base
                         includingPropertiesForKeys:[NSArray arrayWithObjects: NSURLIsDirectoryKey, nil]
                                            options: NSDirectoryEnumerationSkipsHiddenFiles
                                       errorHandler: nil];
    NSMutableArray* newDates = [[NSMutableArray alloc] init];
    NSArray* content;

    // so we can return to the base directory
    [newDates addObject: [NSDictionary dictionaryWithObjectsAndKeys: base, @"url", @"vrac", @"name", nil]];
    
    NSURL* filename;
    NSString* path;
    BOOL match;
    NSNumber* isDir;
    while (filename = [de nextObject]){
        path = [filename path];
        match = [path matchRegex: @".*[0-9]{4}\/[0-9]{2}\/[0-9]{2}"];
        [filename getResourceValue: &isDir forKey: NSURLIsDirectoryKey error: nil];
        if(match && [isDir boolValue] == YES){
            content = [fm contentsOfDirectoryAtURL: filename 
                        includingPropertiesForKeys: nil 
                                           options: NSDirectoryEnumerationSkipsHiddenFiles
                                             error: nil];
            if( [content count] != 0){
                [newDates addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                      filename, @"url", 
                                      path, @"name", nil]];
            }
        }
    }

    return [newDates autorelease];
}

- (IBAction) changeDate: (id) sender
{
    NSURL* url = [[datesController selection] valueForKey: @"url"];
    Datasource* datasource = [[Datasource alloc] initWithURL: url];
    NSUndoManager* undoManager = [[window firstResponder] undoManager];
    [datasource setUndoManager: undoManager];
    [browserViewController updateDatasource: datasource];
    [datasource release];
}

@end
