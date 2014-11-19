/*
     File: DetailViewController.m
 Abstract: A simple UIViewController that shows a localized label that contains detail information, including height and date data, about the user-selected mountain.
  Version: 1.3
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "DetailViewController.h"
#import "Tr8n.h"
#import "UIViewController+Tr8n.h"


// key names for values in mountain dictionary entries
const NSString *kMountainNameString = @"name";
const NSString *kMountainHeightString = @"height";
const NSString *kMountainClimbedDateString = @"climbedDate";

@interface DetailViewController () {
    
	// Private formatter instances that we'll re-use
	NSNumberFormatter *numberFormatter;
	NSDateFormatter *dateFormatter;
}
@property (weak, nonatomic) IBOutlet UILabel *mountainDetails;
@end


@implementation DetailViewController

- (void) translationsLoaded {
    self.navigationItem.title = Tr8nLocalizedStringWithDescription(@"Detail", @"Details about the mountain");
    [self updateLabelWithMountainName:self.mountainDictionary[kMountainNameString]
                               height:self.mountainDictionary[kMountainHeightString]
                          climbedDate:self.mountainDictionary[kMountainClimbedDateString]];
    self.navigationItem.backBarButtonItem.title = Tr8nLocalizedStringWithDescription(@"Master", @"Main section of the app");
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
        
    [self updateLabelWithMountainName:self.mountainDictionary[kMountainNameString]
                               height:self.mountainDictionary[kMountainHeightString]
                          climbedDate:self.mountainDictionary[kMountainClimbedDateString]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(translationsLoaded)
                                                 name:Tr8nTranslationsLoadedNotification
                                               object:self.view.window];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentLocaleOrTimeZoneDidChange:)
                                                 name:NSCurrentLocaleDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentLocaleOrTimeZoneDidChange:)
                                                 name:NSSystemTimeZoneDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews {
    
    [self.mountainDetails setPreferredMaxLayoutWidth:self.mountainDetails.bounds.size.width];
    [self.view layoutIfNeeded];
}


#pragma mark - Notification Handler

- (void)currentLocaleOrTimeZoneDidChange:(NSNotification *)notif {
    
    // When user changed the locale (region format) or time zone in Settings, we are notified here to
    // update the date format in UI.
    //
    [self updateLabelWithMountainName:self.mountainDictionary[kMountainNameString]
                               height:self.mountainDictionary[kMountainHeightString]
                          climbedDate:self.mountainDictionary[kMountainClimbedDateString]];
}


#pragma mark - Helper Methods

- (void)updateLabelWithMountainName:(NSString *)name height:(NSNumber*)height climbedDate:(NSDate*)climbedDate {
    NSNumber *metricSystem = [[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem];
    BOOL usesMetricSystem = (metricSystem != nil && [metricSystem boolValue]);
    
	NSString *sentence = @"";
    NSNumber *actualHeight = height;
    
    if (usesMetricSystem)
        actualHeight = [NSNumber numberWithInt:(int)([height floatValue] * 3.280839895)];

    [NSNumberFormatter setDefaultFormatterBehavior:NSNumberFormatterBehavior10_4];
    if (numberFormatter == nil)
        numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];

    NSString *formattedHeight = [numberFormatter stringFromNumber: actualHeight];
    
    NSDictionary *tokens = @{
                             @"mountain_name": Tr8nLocalizedString(name),
                             @"num": @[actualHeight, formattedHeight]
                             };
    
	if (climbedDate != nil) {
        if (usesMetricSystem)
            sentence = @"{mountain_name} was first climbed on {date} and has a height of {num} meters";
        else
            sentence = @"{mountain_name} was first climbed on {date} and has a height of {num} feet";
        
        NSMutableDictionary *newTokens = [NSMutableDictionary dictionaryWithDictionary:tokens];
        NSString *date = Tr8nLocalizedDateWithFormat(climbedDate, @"MMMM d, yyyy");
        [newTokens setObject:date forKey:@"date"];
        tokens = newTokens;
	} else {
        if (usesMetricSystem)
            sentence = @"{mountain_name} has a height of {num} meters";
        else
            sentence = @"{mountain_name} has a height of {num} feet";
	}
    
    Tr8nLocalizeViewWithLabelAndTokens(self.mountainDetails, sentence, tokens);
    
	/* Note that the mountainDetails UILabel is defined in Interface Builder as
	 a multi-line UILabel.  This was done by setting the "Layout, # Lines" setting
	 to 0, and the "Font Size, Adjust to Fit" to off. */
//	self.mountainDetails.text = sentence;
	/* Note that by setting the text property on the mountainDetails UILabel,
	 it automatically gets invalidated so we do not need to call setNeedsDisplay */
}

@end
