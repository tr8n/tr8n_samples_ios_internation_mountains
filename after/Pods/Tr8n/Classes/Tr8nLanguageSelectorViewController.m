/*
 *  Copyright (c) 2014 Translation Exchange, Inc. http://translationexchange.com All rights reserved.
 *
 *  _______                  _       _   _             ______          _
 * |__   __|                | |     | | (_)           |  ____|        | |
 *    | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __ | |__  __  _____| |__   __ _ _ __   __ _  ___
 *    | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \|  __| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
 *    | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | | |____ >  < (__| | | | (_| | | | | (_| |  __/
 *    |_|_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|______/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
 *                                                                                        __/ |
 *                                                                                       |___/
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */


#import "Tr8nLanguageSelectorViewController.h"
#import "Tr8n.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"
#import "Tr8n.h"
#import "Tr8nApplication.h"
#import "Tr8nApiClient.h"

@interface Tr8nLanguageSelectorViewController ()

@property(nonatomic, strong) IBOutlet UITableView *tableView;

@property(nonatomic, strong) NSMutableArray *languages;

- (IBAction) dismiss: (id)sender;

@end

@implementation Tr8nLanguageSelectorViewController
@synthesize tableView, languages;
@synthesize delegate;

+ (void) changeLanguageFromController:(UIViewController *) controller {
    Tr8nLanguageSelectorViewController *selector = [[Tr8nLanguageSelectorViewController alloc] init];
    selector.delegate = (id<Tr8nLanguageSelectorViewControllerDelegate>) controller;
    [controller presentViewController:selector animated: YES completion: nil];
}

- (id)init {
    self = [super init];
    if (self) {
        self.languages = [NSMutableArray array];
    }
    return self;
}

- (void) loadView {
    [super loadView];

    self.view.backgroundColor = [UIColor colorWithWhite:0.97f alpha:1.0f];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 25, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:Tr8nLocalizedString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(dismiss:)];
    
    UINavigationItem *titleItem = [[UINavigationItem alloc] initWithTitle:Tr8nLocalizedString(@"Select Language")];
    titleItem.leftBarButtonItem=doneButton;
    navBar.items = @[titleItem];
    [self.view addSubview:navBar];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 70, self.view.frame.size.width, self.view.frame.size.height - 70)];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = Tr8nLocalizedString(@"Loading Languages...");
    
    NSString *path = [NSString stringWithFormat:@"applications/%@/languages", [[Tr8n sharedInstance] currentApplication].key];
    [[[Tr8n sharedInstance] currentApplication].apiClient get:path params:@{} options:@{} success:^(id responseObject) {
        self.languages = [NSMutableArray array];
        NSDictionary *data = (NSDictionary *) responseObject;
        for (NSDictionary *attribs in [data objectForKey:@"results"]) {
            [self.languages addObject:[[Tr8nLanguage alloc] initWithAttributes:attribs]];
        }
        [self.tableView reloadData];

        hud.labelText = Tr8nLocalizedString(@"Languages updated");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            [hud hide:YES];
        });
        
    } failure:^(NSError *error) {
        NSLog(@"%@", [error description]);
    }];
}

-(IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [languages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"UITableViewCell"];
    }
    
    Tr8nLanguage *language = (Tr8nLanguage *)[self.languages objectAtIndex:indexPath.row];
//    if (![language.nativeName isEqualToString:language.englishName]) {
//        cell.textLabel.text = nil;
//        cell.textLabel.attributedText = Tr8nLocalizedAttributedStringWithTokens(@"{native_name} [small: {english_name}]", (@{
//          @"native_name": language.nativeName,
//          @"english_name": language.englishName,
//          @"small": @{
//            @"font": @{
//              @"family": @"Arial",
//              @"size": @12
//            },
//            @"color": @"gray"
//          }
//        }));
//    } else {
//        cell.textLabel.attributedText = nil;
//        cell.textLabel.text = language.nativeName;
//    }
    
    cell.detailTextLabel.text = language.nativeName;
    cell.textLabel.text = language.englishName;

//    __weak UITableViewCell *weakCell = cell;
//    [cell.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: language.flagUrl]]
//                          placeholderImage:nil
//                                   success:^(NSURLRequest *request,   NSHTTPURLResponse *response, UIImage *image) {
//        if (weakCell) {
//            weakCell.imageView.image = image;
//            [weakCell setNeedsLayout];
//        }
//    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
//        NSLog(@"Error: %@", error);
//    }];
    
    if ([[[Tr8n sharedInstance] currentLanguage].locale isEqualToString:language.locale]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Tr8nLanguage *language = (Tr8nLanguage *)[self.languages objectAtIndex:indexPath.row];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = Tr8nLocalizedString(@"Switching language...");

    [Tr8n changeLocale:language.locale success:^{
        if (delegate && [delegate respondsToSelector:@selector(tr8nLanguageSelectorViewController:didSelectLanguage:)]) {
            [delegate tr8nLanguageSelectorViewController:self didSelectLanguage:language];
        }
        
        hud.labelText = Tr8nLocalizedString(@"Language changed");

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            [hud hide:YES];
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    } failure:^(NSError *error) {
        [hud hide:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:Tr8nLocalizedString(@"Language Selector") message:Tr8nLocalizedString(@"Failed to change the language. Please try again later") delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }];
}

@end
