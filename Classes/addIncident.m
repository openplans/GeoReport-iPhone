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
	[incidentFieldsTableView reloadData];
}

-(void) done_Clicked
{
	[incidentFieldsTableView setContentOffset:CGPointMake(0, 0)];
	[descriptionEditView resignFirstResponder];
	//NSLog(@"text title %@", textTitle.text);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save_data)];

}

-(void) save_data
{
	
	// Resign the KeyBoard
	[descriptionEditView resignFirstResponder];
	[textTitle resignFirstResponder];
	
	IncidentModel *incident = app.newIncident;
	
	// Convert incident to dictionary for use with the ushahidi API.
	
	if([incident.title length]<=0 || [incident.cat length]<0 || [incident.lat length]<=0 || [incident.lng length]<=0)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Some Data are Missing" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok",nil];
		[alert show];
	} 
	else
	{
		NSMutableDictionary *tempdict = [incident toDictionary];
		
		// Set a few more things in the dictionary that the API uses,
		// these are not really part of the data model.
		[tempdict setObject:@"report" forKey:@"task"];
		[tempdict setObject:@"json" forKey:@"resp"];
		
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
			descriptionEditView.text = @"";
			app.newIncident = [IncidentModel createNew];
			[incidentFieldsTableView reloadData];
		}
		else
		{
			[alert setTitle:@"Failed to report!"];
			[alert setMessage:errorMsg];
		}
		[alert show];
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
   
	descriptionEditView.delegate = self;
	textTitle.delegate = self;
	incidentFieldsTableView.delegate = self;
	incidentFieldsTableView.dataSource = self;
	descriptionEditView.layer.cornerRadius = 10.0;
	// TODO: want some placeholder on the description field, or a label or something.
	// Look at http://github.com/facebook/three20 which provides a suitable subclass,
	// plus some other things we'll want like HTTP caching.
	//[descriptionEditView setPlaceholder:@"Required or something"];
	app = [[UIApplication sharedApplication] delegate];
	arr = [[NSMutableArray alloc] init];	
	[arr addObject:@"Title:"];
	//[arr addObject:@"Date & Time:"];
	[arr addObject:@"Categories:"];
	[arr addObject:@"Location:"];
	//[arr addObject:@"Photos:"];
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

-(void)textFieldDidEndEditing:(UITextField *)textField
{
	// Save title on the model.
	// TODO: this is bad, we assume there is only one UITextField
	app.newIncident.title = textField.text;
}


-(void)camera_Clicked
{
	cameraview *cv = [[cameraview alloc] initWithNibName:@"cameraview" bundle:nil];
	[self.navigationController pushViewController:cv animated:YES];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{   
	// Scroll down to show just the text view.
	 // TODO: figure out how to de-hardcode the amount to scroll
	[incidentFieldsTableView setContentOffset:CGPointMake(0, 110)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done_Clicked)];
	return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[descriptionEditView resignFirstResponder];
	// Description: save to the model.
	// TODO: this is bad, we assume there's only one UITextView.
	app.newIncident.description = textView.text;
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
	
	incidentFieldsTableView.tableFooterView = v1;  // TODO: what is this? nothing?
	// Configure the cell.
	cell.add_Label.text = [arr objectAtIndex:indexPath.row];
	cell.add_Label.hidden = FALSE;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;

	if(indexPath.row == 0)
	{
		cell.txt.hidden = FALSE;
		[cell.txt setPlaceholder:@"Required"];
		cell.txt.delegate = self;
		cell.txt.text = app.newIncident.title;
		textTitle = cell.txt;
		cell.accessoryType = UITableViewCellAccessoryNone; 
		NSLog(@"cell text: %@", cell.txt.text); 
	}
	else if(indexPath.row == 1)
	{
		cell.showDate.hidden = FALSE;
		df = [[NSDateFormatter alloc] init];
		[df setDateFormat:UI_DATE_FORMAT];
		cell.showDate.text = [NSString stringWithFormat:@"%@",[df stringFromDate:app.newIncident.datetime]];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; 
	}
	else if(indexPath.row == 2)
	{
		// TODO: why do we use showDate for the category picker label?
		cell.showDate.hidden = FALSE;
		cell.showDate.text = @"Select";
		if([app.newIncident.cat length]>0)
		{
			cell.showDate.text = app.newIncident.cat;
		}
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; 
	}
	else if(indexPath.row == 2)
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
