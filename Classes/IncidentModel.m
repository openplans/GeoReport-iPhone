//
//  IncidentModel.m
//  UshahidiProj
//
//  Created by Paul Winkler on 6/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "IncidentModel.h"
#import "constants.h"
#import "UshahidiProjAppDelegate.h"

@implementation IncidentModel

@synthesize fname,lname,emailStr;
@synthesize cat,lat,lng, locationName;
@synthesize datetime;
@synthesize title, description;

+(IncidentModel *) createNew {
	IncidentModel *model = [[IncidentModel alloc] init];
	
	// We set defaults first, just in case something's wrong with the draft file
	// and not all required data is found there.
	model.datetime = [NSDate date];
	
	// Populate un-editable fields from the app settings.
	UshahidiProjAppDelegate *app = [[UIApplication sharedApplication] delegate];
	model.fname = app.fname;
	model.lname = app.lname;
	model.emailStr = app.emailStr;
	
	// Set other defaults so we can always call toDictionary.
	model.cat = @"";
	model.lat= @"";
	model.lng = @"";
	model.title = @"";
	model.description = @"";
	model.locationName = @"";
	return model;
}

+(IncidentModel *) loadDraftOrCreateNew {
	NSString *path = [IncidentModel draftFilePath];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	IncidentModel* model = [IncidentModel createNew];
	if ( [fileManager fileExistsAtPath:path isDirectory:FALSE] )
	{
		// load the file, get json value, update model data from json.
		// TODO: handle exceptions, in case eg. file is corrupted or our json structure changes.
		NSData *jsonData = [fileManager contentsAtPath:path];
		NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		NSLog(@"Loading data from file %@:\n%@", path, jsonString);
		NSMutableDictionary *dict = [jsonString JSONValue];
		[model updateFromDictionary:dict];
	}
	else 
	{
		NSLog(@"Draft file not found, leaving new model instance with defaults", nil);
	}
	NSLog(@"returning model", nil);
	return model;
}

-(BOOL) saveDraft {
	NSString *path = [IncidentModel draftFilePath];
    NSLog(@"Saving json data to %@...", path);
    NSMutableDictionary *dict = [self toDictionary];
	NSString *jsonString = [dict JSONRepresentation];
	NSLog(@"JSON dumped: \n%@", jsonString);
	[jsonString writeToFile:path atomically:TRUE encoding:NSUTF8StringEncoding error:nil];
	return TRUE;
}

-(BOOL) updateFromDictionary:(NSMutableDictionary *)dict {
	self.cat = [dict objectForKey:@"incident_category"];
	self.lat = [dict objectForKey:@"latitude"];
	self.lng = [dict objectForKey:@"longitude"];
	self.title = [dict objectForKey:@"incident_title"];
	self.description = [dict objectForKey:@"incident_description"];
	self.fname = [dict objectForKey:@"person_first"];
	self.lname = [dict objectForKey:@"person_last"];
	self.emailStr = [dict objectForKey:@"person_email"];
	self.locationName = [dict objectForKey:@"location_name"]; // TODO: un-hardcode this	
	// TODO: parse dates
	return TRUE;
}

-(BOOL) setDateFromString:(NSString *)dateString withFormat:(NSString *)dateFormat {
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:dateFormat];
	self.datetime = [df dateFromString:dateString];
	return TRUE;
}

-(NSMutableDictionary *) toDictionary {
	// Adapt the Incident as a dictionary convenient for feeding
	// to the Ushahidi JSON API.

	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	// Date Formatters to extract attributes of incident date.
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];	
	NSDateFormatter *detailsTimeFormatter = [[NSDateFormatter alloc] init];
	[detailsTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
	NSString *time = [[detailsTimeFormatter stringFromDate:self.datetime] lowercaseString];
	NSRange amResultsRange = [time rangeOfString:@"am" options:NSCaseInsensitiveSearch];
	NSString *ampm;
	if (amResultsRange.length > 0)
	{
		ampm = @"am";
	}
	else
	{
		ampm = @"pm";
	}
	
	[dateFormatter setDateFormat:@"hh"];
	int hour = [[dateFormatter stringFromDate:self.datetime] intValue];
	
	[dateFormatter setDateFormat:@"mm"];
	int minute = [[dateFormatter stringFromDate:self.datetime] intValue];

	[dateFormatter setDateFormat:@"MM/dd/yyyy"];
	NSString *dateString = [dateFormatter stringFromDate:self.datetime] ;
	
	// Populate the dictionary.
	[dict setObject:self.cat forKey:@"incident_category"];
	[dict setObject:self.lat forKey:@"latitude"];
	[dict setObject:self.lng forKey:@"longitude"];
	[dict setObject:self.title forKey:@"incident_title"];
	[dict setObject:self.description forKey:@"incident_description"];
	[dict setObject:dateString forKey:@"incident_date"];
	[dict setObject:[NSString stringWithFormat:@"%d",hour] forKey:@"incident_hour"];
	[dict setObject:[NSString stringWithFormat:@"%d",minute] forKey:@"incident_minute"];
	[dict setObject:ampm forKey:@"incident_ampm"];
	[dict setObject:self.fname forKey:@"person_first"];
	[dict setObject:self.lname forKey:@"person_last"];
	[dict setObject:self.emailStr forKey:@"person_email"];
	[dict setObject:@"India" forKey:@"location_name"]; // TODO: un-hardcode this

	//NSData *data = UIImageJPEGRepresentation(img1, 90);
	//	[dict setObject:data forKey:@"incident_photo"];
	
	return dict;
};


+ (NSString *)draftFilePath {
	// Where to load and save a draft.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
														 NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsPath = [documentsDirectory
							   stringByAppendingPathComponent:@"ushahidi_draft.json"];
	NSLog(@"Draft path: %@", documentsPath);
    return documentsPath;	
}
@end
