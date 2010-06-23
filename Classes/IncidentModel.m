//
//  IncidentModel.m
//  UshahidiProj
//
//  Created by Paul Winkler on 6/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "IncidentModel.h"


@implementation IncidentModel

+(IncidentModel *) loadDraftOrCreateNew {
	// TODO: load saved draft from disk, if any.
	return [[IncidentModel alloc] init];
}

-(BOOL) saveDraft {
	// TODO: save draft to disk.
	return TRUE;
}

@synthesize fname,lname,emailStr;
@synthesize datetime,cat,lat,lng;

@end
