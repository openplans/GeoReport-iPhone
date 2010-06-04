/*****************************************************************************
 ** Copyright (c) 2010 Ushahidi Inc
 ** All rights reserved
 ** Contact: team@ushahidi.com
 ** Website: http://www.ushahidi.com
 **
 ** GNU Lesser General Public License Usage
 ** This file may be used under the terms of the GNU Lesser
 ** General Public License version 3 as published by the Free Software
 ** Foundation and appearing in the file LICENSE.LGPL included in the
 ** packaging of this file. Please review the following information to
 ** ensure the GNU Lesser General Public License version 3 requirements
 ** will be met: http://www.gnu.org/licenses/lgpl.html.
 **
 **
 ** If you have questions regarding the use of this file, please contact
 ** Ushahidi developers at team@ushahidi.com.
 **
 *****************************************************************************/

#import "API.h"
#import "UshahidiProjAppDelegate.h"
#import "GDataXMLNode.h"

@implementation GDataXMLNode (XMLNodeUtils)

- (NSString *)firstStringByXpath:(NSString*)xpath
{
	// It's nice that the XML APIs are generalized to always return arrays of nodes,
	// but dammit, sometimes we know there's just one.
	NSString *value = @"";
	NSArray *matches = [self nodesForXPath:xpath error:nil];
	if ([matches count] > 0) {
		value = [[matches objectAtIndex:0] stringValue];
	}
	return value;
}
@end


@implementation API

@synthesize endPoint;
@synthesize errorCode;
@synthesize errorDesc;
@synthesize responseData;
@synthesize responseXML;

- (id)init {
	
	responseData = [[NSMutableData data] retain];
	app = [[UIApplication sharedApplication] delegate];
	return self;
}


-(NSMutableArray *)mapLocation
{
	NSError *error;
	NSURLResponse *response;
	NSDictionary *results;
	
	NSString *queryURL = [NSString stringWithFormat:@"http://%@/api?task=mapcenter",app.urlString];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:queryURL]];
	
	responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	responseXML = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	results = [responseXML JSONValue];
	
	//categories
	NSMutableArray *mapcenters = [[results objectForKey:@"payload"] objectForKey:@"mapcenters"];
	return mapcenters;
	
}


- (NSMutableArray *)categoryNames {
	NSError *error;

	// Temporarily get the XML from a file. TODO: fetch this via HTTP using GeoReport API
	NSString *dataFilePath = [[NSBundle mainBundle] pathForResource:@"sample_request_types" ofType:@"xml"];
	responseData = [[NSMutableData alloc] initWithContentsOfFile:dataFilePath];
	responseXML = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSLog(@"Response: %@\n", responseXML );
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:responseData options:0 error:&error];

	// We're assuming that every category has exactly one service_code, service_name, and service_description.
	// If that's wrong, we're in trouble.
	// Also, we're not doing anything about sorting.
	NSArray *categoryIds = [doc nodesForXPath:@"//service/service_code" error:nil];
	NSArray *categoryTitles = [doc nodesForXPath:@"//service/service_name" error:nil];
	NSArray *categoryDescrs = [doc nodesForXPath:@"//service/description" error:nil];
	
	NSMutableArray *categories = [NSMutableArray arrayWithCapacity:[categoryIds count]]; 
	// In order to minimize changes, we're converting our XML structure into the same
	// array-of-dictionaries structure that Ushahidi returns as JSON.
    // From GeoReport's XML, we map service_code -> id, service_name -> title, description -> description.
	for (int i = 0; i < [categoryIds count]; i++) {
		NSMutableDictionary *cat = [NSMutableDictionary dictionaryWithCapacity:3];
		[cat setValue:[[categoryIds objectAtIndex:i] stringValue] forKey:@"id"];
		[cat setValue:[[categoryTitles objectAtIndex:i] stringValue] forKey:@"title"];
		[cat setValue:[[categoryDescrs objectAtIndex:i] stringValue] forKey:@"description"];
		[categories addObject:[NSDictionary dictionaryWithObject:cat forKey:@"category"]];
	}
	NSLog(@"categoryNames returning: %@\n", [categories JSONFragment]);
		
	return categories;
}

- (NSMutableArray *)incidentsByCategoryId:(int)catid {
	//[[NSURLConnection alloc] initWithRequest:request delegate:self];
	NSError *error;
	NSURLResponse *response;
	NSDictionary *results;
	
	NSString *queryURL = [NSString stringWithFormat:@"http://%@/api?task=incidents&by=catid&id=%d",app.urlString, catid];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:queryURL]];
	
	responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	responseXML = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	results = [responseXML JSONValue];
	
	//categories
	NSMutableArray *incidents = [[results objectForKey:@"payload"] objectForKey:@"incidents"];
	//[error release];
	//[response release];
	//[results release];
	
	return incidents;
}

- (NSMutableArray *)allIncidents {
	//[[NSURLConnection alloc] initWithRequest:request delegate:self];
	NSError *error;

	// Temporarily get the XML from a file. TODO: fetch this via HTTP using GeoReport API
	NSString *dataFilePath = [[NSBundle mainBundle] pathForResource:@"sample_requests" ofType:@"xml"];
	responseData = [[NSMutableData alloc] initWithContentsOfFile:dataFilePath];
	responseXML = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSLog(@"Response: %@\n", responseXML );
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:responseData options:0 error:&error];
		
	//incidents
	NSArray *requestNodes = [doc nodesForXPath:@"//service_requests/request" error:nil];
	
	NSMutableArray *incidents = [NSMutableArray arrayWithCapacity:[requestNodes count]]; 
	// In order to minimize changes, we're converting our XML structure into the same
	// array-of-dictionaries structure that Ushahidi web API returns as JSON.
	for (int i = 0; i < [requestNodes count]; i++) {
		GDataXMLElement *node = [requestNodes objectAtIndex:i];
		NSMutableDictionary *inc = [[NSMutableDictionary alloc] init ];
		[inc setValue:[node firstStringByXpath:@"./service_request_id"] forKey:@"incidentid"];
		[inc setValue:[node firstStringByXpath:@"./service_name"] forKey:@"incidenttitle"]; // TODO: GeoReport has no titles?
		NSString *date;
		date = [node firstStringByXpath:@"./requested_datetime"]; // format is like "2010-04-14T06:37:38-08:00"
		[inc setValue:date forKey:@"incidentdate"];
		[inc setValue:[node firstStringByXpath:@"./description"] forKey:@"incidentdescription"];
		[inc setValue:[node firstStringByXpath:@"./address"] forKey:@"locationname"];
		[inc setValue:[node firstStringByXpath:@"./lat"] forKey:@"locationlatitude"];
		[inc setValue:[node firstStringByXpath:@"./long"] forKey:@"locationlongitude"];
		[inc setValue:@"2" forKey:@"incidentmode"];
		[inc setValue:@"0" forKey:@"incidentverified"];
		[inc setValue:@"0" forKey:@"incidentactive"];

		[incidents addObject:[NSMutableDictionary dictionaryWithObject:inc forKey:@"incident"]];
		[[incidents objectAtIndex:i] setValue:[[NSArray alloc] init] forKey:@"media"];
	}
	
	NSLog(@"allIncidents returning: %@", [incidents JSONFragment]);

	return incidents;
}

- (BOOL)postIncidentWithDictionary:(NSMutableDictionary *)incidentinfo {
	//[[NSURLConnection alloc] initWithRequest:request delegate:self];
	NSError *error;
	NSURLResponse *response;
	NSDictionary *results;

	//NSString *queryURL = [NSString stringWithFormat:@"http://%@/api?task=report",app.urlString];
	NSString *queryURL = [NSString stringWithFormat:@"http://%@/requests.xml",app.urlString];

	// TODO: de-hardcode jurisdiction. The API requires us to know it a priori, ugh.
	queryURL = [NSString stringWithFormat:@"%@?jurisdiction_id=sfgov.org", queryURL];

	//form the rest of the url from the dict

	NSArray *ushahidiKeys = [NSArray arrayWithObjects:
							 @"incident_title",
							 @"incident_category",
							 @"person_last", @"person_first",
							 @"person_email",
							 @"latitude", @"longitude",
							 @"location_name",
							 nil];
	NSArray *geoReportKeys = [NSArray arrayWithObjects:
							  @"description",
							  @"service_code",
							  @"last_name", @"first_name",
							  @"email",
							  @"lat", @"long",
							  @"address_string",
							  nil];

	for (int i=0; i < [ushahidiKeys count]; i++) {
		NSString *valueString = [incidentinfo objectForKey:[ushahidiKeys objectAtIndex:i]];
		NSString *keyString = [geoReportKeys objectAtIndex:i];
		NSString *oldKey = [ushahidiKeys objectAtIndex:i];
		NSLog(@"Setting key '%@' to value '%@', from '%@'", keyString, valueString, oldKey);
		queryURL = [NSString stringWithFormat:@"%@&%@=%@", queryURL, [self urlEncode:keyString], [self urlEncode:valueString]];
	}
	
	NSString *requestString = [NSString stringWithFormat:@"%@", queryURL, nil];

	// Temporarily save x-www-form-urlencoded data to log. 
	// TODO: stand up *something* we can post this to via HTTP. SF dev service?
	NSLog(@"Sending POST with form-encoded string: %@", requestString);
	NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", queryURL]]];
	[request setHTTPMethod: @"POST"];	
	[request setHTTPBody:requestData];

	// Response handling.
	
	//responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	//responseXML = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	// TODO: parse GeoReport XML response
	//results = [responseXML JSONValue];
	//NSString *success = (NSString *)[[results objectForKey:@"payload"] objectForKey:@"success"];
	//NSLog(@"Response from POST new incident: %@", returnString); 	
	
	NSString *success = @"true";
	
	// Cleanup.
	//[response release];
	//[results release];

	if([success isEqual:@"true"])
		return YES;
	else
		return NO;
}

- (BOOL)postIncidentWithDictionaryWithPhoto:(NSMutableDictionary *)incidentinfo {
	
	NSString *queryURL = [NSString stringWithFormat:@"http://%@/api?task=report",app.urlString];
	//NSURL *nsurl = [NSString stringWithFormat:@"http://%@/api?task=report",app.urlString];
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", queryURL]]];
	//[request setURL:nsurl];  
	[request setHTTPMethod:@"POST"];  
	
	NSString *boundary = [NSString stringWithString:@"---------------------------14737809831466499882746641449"];  
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];  
	[request addValue:contentType forHTTPHeaderField: @"Content-Type"];  
	
	//[incidentinfo objectForKey:@"task"];
	NSString *param1 = 	[incidentinfo objectForKey:@"incident_title"];
	NSString *param2 = [incidentinfo objectForKey:@"incident_description"];
	NSString *param3 =[incidentinfo objectForKey:@"incident_date"];
	NSString *param4 =[incidentinfo objectForKey:@"incident_hour"];
	NSString *param5 =[incidentinfo objectForKey:@"incident_minute"];
	NSString *param6 =[incidentinfo objectForKey:@"incident_ampm"];
	NSString *param7 =[incidentinfo objectForKey:@"incident_category"];
	NSString *param8 =[incidentinfo objectForKey:@"latitude"];
	NSString *param9 =[incidentinfo objectForKey:@"longitude"];
	NSString *param10 =[incidentinfo objectForKey:@"location_name"];
	NSString *param11 =[incidentinfo objectForKey:@"person_first"];
	NSString *param12 =[incidentinfo objectForKey:@"person_last"];
	NSString *param13 =[incidentinfo objectForKey:@"person_email"];
	
	
	/* 
	 now lets create the body of the post 
	 */  
	NSMutableData *body = [NSMutableData data];  
	
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];   
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"incident_title\"\r\n\r\n%@", param1] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];  
	//Tags  
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"incident_description\"\r\n\r\n%@", param2] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];  
	//Status  
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"incident_date\"\r\n\r\n%@", param3] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];  
	//customerID  
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"incident_hour\"\r\n\r\n%@", param4] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];  
	//customerName  
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"incident_minute\"\r\n\r\n%@", param5] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];  
	//
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"incident_ampm\"\r\n\r\n%@", param6] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];  
	//
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"incident_category\"\r\n\r\n%@", param7] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];  
	//
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"latitude\"\r\n\r\n%@", param8] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];  
	//
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"longitude\"\r\n\r\n%@", param9] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];  
	//
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"location_name\"\r\n\r\n%@", param10] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]]; 
	//
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"person_first\"\r\n\r\n%@", param11] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]]; 
	//
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"person_last\"\r\n\r\n%@", param12] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	//
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"person_email\"\r\n\r\n%@", param13] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	//
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"task\"\r\n\r\n%@", @"report"] dataUsingEncoding:NSUTF8StringEncoding]];  
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	//Image 
	UIImage *img[100];
	NSData *imageData[100];
	arrData = [[NSMutableArray alloc] init];
	arrImage = [[NSMutableArray alloc] init]; 
	
	for(int i = 0; i <[app.imgArray count]; i ++)
	{
	img[i] = [app.imgArray objectAtIndex:i];
	imageData[i] = UIImageJPEGRepresentation(img[i], 90);
	[arrData addObject:imageData[i]];
	[arrData retain];
	[arrImage addObject:img[i]];
	[arrImage retain];
	}
	
	// i = 1;
//	img[i] = [app.imgArray objectAtIndex:i];
//	imageData[i] = UIImageJPEGRepresentation(img[i], 90);
//	[arrData addObject:imageData[i]];
//	[arrData retain];
//	[arrImage addObject:img[i]];
//	[arrImage retain];
	
	if([app.imgArray count] >0)
	{
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"incident_photo[]\"; filename=\"1.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];  
		[body appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]]; 
		for(int i = 0; i<[arrData count]; i++)
		{
			[body appendData:[NSData dataWithData:[arrData objectAtIndex:i]]]; 
		}
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]]; 
	}
	

		
//	
//	 i = 1;
//	img[i] = [app.imgArray objectAtIndex:i];
//	imageData[i] = UIImageJPEGRepresentation(img[i], 90);
//	[arrData addObject:imageData[i]];
//	[arrData retain];
//	[arrImage addObject:img[i]];
//	[arrImage retain];
//	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"incident_photo[]\"; filename=\"%d.jpg\"\r\n",i] dataUsingEncoding:NSUTF8StringEncoding]];  
//	[body appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];  
//	[body appendData:[NSData dataWithData:[arrData objectAtIndex:i]]]; 
//	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];  

	

	//}
	//}
	// setting the body of the post to the reqeust  
	[request setHTTPBody:body]; 
	NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];  
	//responseJSON = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSDictionary *results;
	
	NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
	results = [returnString JSONValue];
	//results = [returnData JSONValue];
		
		NSString *success = (NSString *)[[results objectForKey:@"payload"] objectForKey:@"success"];
		
	//[error release];
	//[response release];
	//[results release];
		
		if([success isEqual:@"true"])
			return YES;
		else
			return NO;
	

}
- (BOOL)postIncidentWithDictionary:(NSMutableDictionary *)incidentinfo andPhotoDataDictionary:(NSMutableDictionary *) photoData {
	return NO;
}

- (NSString *)urlEncode:(NSString *)string {
	return [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
}


- (void)dealloc {
	[endPoint release];
	[errorCode release];
	[errorDesc release];
	if(responseData != nil)
		[responseData release];
	[responseXML release];
	[super dealloc];
}

@end
