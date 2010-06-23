//
//  IncidentModel.h
//  UshahidiProj
//
//  Created by Paul Winkler on 6/23/10.
//  Copyright 2010 OpenPlans.
/*
** GNU Lesser General Public License Usage
** This file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: http://www.gnu.org/licenses/lgpl.html.
**
*/

#import <Foundation/Foundation.h>


@interface IncidentModel : NSObject {
	NSString *datetime,*cat,*lat,*lng;
	NSString *fname,*lname,*emailStr;
}

@property (nonatomic,retain) NSString *datetime,*cat,*lat,*lng;
@property (nonatomic,retain) NSString *fname,*lname,*emailStr;

// Class methods.
+(IncidentModel *) loadDraftOrCreateNew;

// Instance methods.
-(BOOL) saveDraft;

@end

