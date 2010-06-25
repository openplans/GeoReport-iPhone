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

#import <QuartzCore/QuartzCore.h>
#import "addIncident.h"
#import "cameraview.h"
#import "CustomCell.h"
#import "showMap.h"
#import "dataCells.h"
#import "UshahidiProjAppDelegate.h"
#import "API.h"
#import "selectCatagory.h"
#import "constants.h"


@implementation addIncident


- (void)viewWillAppear:(BOOL)animated
{
	self.title = @"New Report";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save_data)];
	self.navigationItem.backBarButtonItem.title = @"Cancel";
	[tblView reloadData];
}

-(void) done_Clicked
{
	[tblView setContentOffset:CGPointMake(0, 0)];
	[tv resignFirstResponder];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save_data)];

}

-(void) save_data
{
	
	// Resign the KeyBoard
	[tv resignFirstResponder];
	[textTitle resignFirstResponder];
	
	// XXX TODO: move all this to [IncidentModel toDictionary]
	NSDate *myDate = app.newIncident.datetime;
	
	// Date Formatters to extract attributes of incident date.
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];	
	NSDateFormatter *detailsTimeFormatter = [[NSDateFormatter alloc] init];
	[detailsTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
	NSString *time = [[detailsTimeFormatter stringFromDate:myDate] lowercaseString];
	NSRange titleResultsRange = [time rangeOfString:@"am" options:NSCaseInsensitiveSearch];
	NSString *ampm;
	if (titleResultsRange.length > 0)
	{
		ampm = @"am";
	}
	else
	{
		ampm = @"pm";
	}
	
	[dateFormatter setDateFormat:@"hh"];
	int hour = [[dateFormatter stringFromDate:myDate] intValue];
	
	[dateFormatter setDateFormat:@"mm"];
	int minute = [[dateFormatter stringFromDate:myDate] intValue];
	[dateFormatter setDateFormat:@"MM/dd/yyyy"];
	NSString *dateString = [dateFormatter stringFromDate:myDate] ;
	
	// Set the Data, Insert into Dictionary 
	if([textTitle.text length]<=0 || [app.newIncident.cat length]<0 || [app.newIncident.lat length]<=0 || [app.newIncident.lng length]<=0)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Some Data are Missing" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok",nil];
		[alert show];
	} 
	else {		
		NSMutableDictionary *tempdict = [[NSMutableDictionary alloc] init];
		[tempdict setObject:@"report" forKey:@"task"];
		[tempdict setObject:textTitle.text forKey:@"incident_title"];
		[tempdict setObject:tv.text forKey:@"incident_description"];
		[tempdict setObject:dateString forKey:@"incident_date"];
		[tempdict setObject:[NSString stringWithFormat:@"%d",hour] forKey:@"incident_hour"];
		[tempdict setObject:[NSString stringWithFormat:@"%d",minute] forKey:@"incident_minute"];
		[tempdict setObject:ampm forKey:@"incident_ampm"];
		[tempdict setObject:app.newIncident.cat forKey:@"incident_category"];
		[tempdict setObject:app.newIncident.lat forKey:@"latitude"];
		[tempdict setObject:app.newIncident.lng forKey:@"longitude"];
		[tempdict setObject:@"India" forKey:@"location_name"];
		[tempdict setObject:app.fname forKey:@"person_first"];
		[tempdict setObject:app.lname forKey:@"person_last"];
		[tempdict setObject:app.emailStr forKey:@"person_email"];
		[tempdict setObject:@"json" forKey:@"resp"];
		//NSData *data = UIImageJPEGRepresentation(img1, 90);
		//	[tempdict setObject:data forKey:@"incident_photo"];

		// Post the Data to Server
		NSString *errorMsg;
		if([app.imgArray count]>0 )
		{
			errorMsg = [app postDataWithImage:tempdict];
		}
		else 
		{
			errorMsg = [app postData:tempdict];
		}

		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];	
		if( errorMsg == @"")
		{
			[alert setTitle:@"Reported!"];
			textTitle.text = @"";
			tv.text = @"";
			// TO DO: remove saved draft, once we've implemented drafts..
			app.newIncident = [IncidentModel loadDraftOrCreateNew];
			[tblView reloadData];		
		}
		else
		{
			[alert setMessage:errorMsg];
		}
		[alert show];
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
   
	tv.delegate = self;
	textTitle.delegate = self;
	tblView.delegate = self;
	tblView.dataSource = self;
	tv.layer.cornerRadius = 10.0;
	
	app = [[UIApplication sharedApplication] delegate];
	arr = [[NSMutableArray alloc] init];
	[arr addObject:@"Title:"];
	[arr addObject:@"Date & Time:"];
	[arr addObject:@"Categories:"];
	[arr addObject:@"Location:"];
	[arr addObject:@"Photos:"];
	[arr retain];
	
	[super viewDidLoad];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	return TRUE;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return TRUE;
}

-(void)camera_Clicked
{
	cameraview *cv = [[cameraview alloc] initWithNibName:@"cameraview" bundle:nil];
	[self.navigationController pushViewController:cv animated:YES];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	[tblView setContentOffset:CGPointMake(0, 180)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done_Clicked)];
	return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[tv resignFirstResponder];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark Table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 40;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    CustomCell *cell = (CustomCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[CustomCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
	
	tblView.tableFooterView = v1;
	// Configure the cell.
	cell.add_Label.text = [arr objectAtIndex:indexPath.row];
	cell.add_Label.hidden = FALSE;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;

	if(indexPath.row == 0)
	{
		cell.txt.hidden = FALSE;
		[cell.txt setPlaceholder:@"Required"];
		cell.txt.delegate = self;
		textTitle = cell.txt;
		cell.accessoryType = UITableViewCellAccessoryNone; 
	}
	else if(indexPath.row == 1)
	{
		cell.showDate.hidden = FALSE;
		[df setDateFormat:UI_DATE_FORMAT];
		cell.showDate.text = [NSString stringWithFormat:@"%@",[df stringFromDate:app.newIncident.datetime]];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; 
	}
	else if(indexPath.row == 2)
	{
		cell.showDate.hidden = FALSE;
		cell.showDate.text = @"Select";
		if([app.newIncident.cat length]>0)
		{
			cell.showDate.text = app.newIncident.cat;
		}
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; 
	}
	else if(indexPath.row == 3)
	{
		cell.showDate.hidden = TRUE;
		cell.showLoc.hidden = FALSE;
		cell.showLoc.text = @"Select";
		if([app.newIncident.lat length] > 0)
		{
			cell.showLoc.text = [NSString stringWithFormat:@"%@,%@",app.newIncident.lat,app.newIncident.lng];
		}
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; 
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; 
	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

	if(indexPath.row == 3)
	{
		showMap *sh = [[showMap alloc] initWithNibName:@"showMap" bundle:nil];
		[self.navigationController pushViewController:sh animated:YES];
	}
	if(indexPath.row == 1 )
	{
		dataCells *dc = [[dataCells alloc] initWithNibName:@"dataCells" bundle:nil];
		dc.selectedQ = indexPath.row;
		[self.navigationController pushViewController:dc animated:YES];
	}
	if(indexPath.row == 2 )
	{
		selectCatagory *sc = [[selectCatagory alloc] initWithNibName:@"selectCatagory" bundle:nil];
		[self.navigationController pushViewController:sc animated:YES];
	}
	if(indexPath.row == 4)
	{
		cameraview *cv = [[cameraview alloc] initWithNibName:@"cameraview" bundle:nil];
		[self.navigationController pushViewController:cv animated:YES];
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
