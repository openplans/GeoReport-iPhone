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
	
	// Set the Data, Insert into Dictionary 
	if([textTitle.text length]<=0 || [app.cat length]<0 || [app.lat length]<=0 || [app.lng length]<=0)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Some Data are Missing" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok",nil];
		[alert show];
	} 
	else {
		
	NSMutableDictionary *tempdict = [[NSMutableDictionary alloc] init];
	[tempdict setObject:@"report" forKey:@"task"];
	[tempdict setObject:textTitle.text forKey:@"incident_title"];
	[tempdict setObject:tv.text forKey:@"incident_description"];
	[tempdict setObject:app.cat forKey:@"incident_category"];
	[tempdict setObject:app.lat forKey:@"latitude"];
	[tempdict setObject:app.lng forKey:@"longitude"];
	[tempdict setObject:@"India" forKey:@"location_name"];
	[tempdict setObject:app.fname forKey:@"person_first"];
	[tempdict setObject:app.lname forKey:@"person_last"];
	[tempdict setObject:app.emailStr forKey:@"person_email"];
	[tempdict setObject:@"json" forKey:@"resp"];
	//NSData *data = UIImageJPEGRepresentation(img1, 90);
//	[tempdict setObject:data forKey:@"incident_photo"];
	// Post the Data to Server
	
		BOOL y;
		if([app.imgArray count]>0 )
		{
			y = [app postDataWithImage:tempdict];
		}
		else 
		{
			y = [app postData:tempdict];
		}
	if(y)
	{
		textTitle.text = @"";
		tv.text = @"";
		app.cat =@"";
		app.lat = @"";
		app.lng = @"";
		[tblView reloadData];		
	}
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
	//[arr addObject:@"Date & Time:"];
	[arr addObject:@"Categories:"];
	[arr addObject:@"Location:"];
	//[arr addObject:@"Photos:"];
	[arr retain];
	
	df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"EEE, MMM dd, yyyy hh:mm aa"];
	NSDate *dt = [NSDate date];
	dateStr = [NSString stringWithFormat:@"%@",[df stringFromDate:dt]];
	[dateStr retain];
	app.dt = dateStr;
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
	
	return 3; // 5 with photos
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
		cell.showDate.text = @"Select";
		if([app.cat length]>0)
		{
			cell.showDate.text = app.cat;
		}
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; 
	}
	else if(indexPath.row == 2)
	{
		cell.showDate.hidden = TRUE;
		cell.showLoc.hidden = FALSE;
		cell.showDate.text = @"Select";
		if([app.lat length] > 0)
		{
			cell.showLoc.text = [NSString stringWithFormat:@"%@,%@",app.lat,app.lng];
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

	if(indexPath.row == 1 )
	{  // Categories
		selectCatagory *sc = [[selectCatagory alloc] initWithNibName:@"selectCatagory" bundle:nil];
		[self.navigationController pushViewController:sc animated:YES];
	}
	if(indexPath.row == 2)
	{ // Location
		showMap *sh = [[showMap alloc] initWithNibName:@"showMap" bundle:nil];
		[self.navigationController pushViewController:sh animated:YES];
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
