//
//  IncidentModel.m
//  UshahidiProj
//
//  Created by Paul Winkler on 6/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "IncidentModel.h"
#import "constants.h"

@implementation IncidentModel

@synthesize fname,lname,emailStr;
@synthesize cat,lat,lng;
@synthesize datetime;

+(IncidentModel *) loadDraftOrCreateNew {
	// TODO: load saved draft from disk, if any.
	IncidentModel *model = [[IncidentModel alloc] init];
	model.datetime = [NSDate date];
	return model;
}

-(BOOL) saveDraft {
	// TODO: save draft to disk.
	return TRUE;
}

-(BOOL) updateFromDictionary:(NSMutableDictionary *)dict {
	self.cat = [dict objectForKey:@""];
	return TRUE;
}

-(BOOL) setDateFromString:(NSString *)dateString withFormat:(NSString *)dateFormat {
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:dateFormat];
	self.datetime = [df dateFromString:dateString];
	return TRUE;
}

-(NSMutableDictionary *) toDictionary {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	[dict setObject:self.cat forKey:@"incident_category"];
	[dict setObject:self.lat forKey:@"latitude"];
	[dict setObject:self.lng forKey:@"longitude"];
	// TO DO: move the stuff that splits up the date/time here from newIncident.save_data

	return dict;
};

@end
