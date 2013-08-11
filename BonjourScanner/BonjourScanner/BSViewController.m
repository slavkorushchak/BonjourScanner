//
//  BSViewController.m
//  BonjourScanner
//
//  Created by Slavko Rushchak on 8/10/13.
//  Copyright (c) 2013 Slavko Rushchak. All rights reserved.
//

#import "BSViewController.h"
#include <arpa/inet.h>

@interface NSNetService (BSViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService;
@end

@implementation NSNetService (BSViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService {
	return [[self name] localizedCaseInsensitiveCompare:[aService name]];
}
@end

@interface BSViewController() <UITableViewDataSource, UITableViewDelegate>
{
    NSString* searchingForServicesString;
    NSMutableArray* services;
}

@property (nonatomic, strong) UITableView* tableView;

@property (nonatomic, strong) NSNetServiceBrowser* netServiceBrowser;
@property (nonatomic, strong) NSNetService* currentResolve;

@end

@implementation BSViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.title = @"Bonjour Scanner";
        services = [[NSMutableArray alloc] init];
        searchingForServicesString = @"Searching ...";
	}
    
	return self;
}

- (void) initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self initTableView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self myRegistrationFunction:1934];
    [self refreshServicesList];
}

- (void) refreshServicesList
{
    BOOL canBeSearched = [self searchForServicesOfType:nil inDomain:nil];
    if (!canBeSearched) {
        NSLog(@"ERROR! can not init NSNetServiceBrowser");
    }
}

- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain {
	
	[self stopCurrentResolve];
	[_netServiceBrowser stop];
	[services removeAllObjects];
    
	NSNetServiceBrowser *aNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if(!aNetServiceBrowser) {
		return NO;
	}
    
	aNetServiceBrowser.delegate = self;
	self.netServiceBrowser = aNetServiceBrowser;
	[self.netServiceBrowser searchForServicesOfType:@"_music._tcp" inDomain:@""];
    //_services._dns-sd._udp.
    
	[self.tableView reloadData];
	return YES;
}

#pragma mark - UITableView delegate/datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSUInteger count = [services count];
	if (count == 0 && searchingForServicesString) {
		return 1;
    }
    
	return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellId = @"UITableViewCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellId];
	}
	
	NSUInteger count = [services count];
	if (count == 0 && searchingForServicesString) {
        cell.textLabel.text = searchingForServicesString;
		cell.textLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
		return cell;
	}
	
	NSNetService* service = [services objectAtIndex:indexPath.row];
	cell.textLabel.text = [service name];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"type : %@  /  domain : %@",
                                 service.type, service.domain];
	cell.detailTextLabel.textColor = [UIColor grayColor];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.currentResolve) {		
		[self stopCurrentResolve];
    }
	
	self.currentResolve = [services objectAtIndex:indexPath.row];
	[self.currentResolve setDelegate:self];

	[self.currentResolve resolveWithTimeout:0.0];
}

- (void)sortAndUpdateUI
{
	[services sortUsingSelector:@selector(localizedCaseInsensitiveCompareByName:)];
	[self.tableView reloadData];
}

- (void)stopCurrentResolve
{    
	[self.currentResolve stop];
	self.currentResolve = nil;
}

#pragma mark - NSNetServiceBrovser delegate
- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser
         didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing
{
	if (self.currentResolve && [service isEqual:self.currentResolve]) {
		[self stopCurrentResolve];
	}
    
	//[services removeObject:service];
	
	if (!moreComing) {
		[self sortAndUpdateUI];
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser
           didFindService:(NSNetService*)service moreComing:(BOOL)moreComing
{    
	[services addObject:service];
    
	if (!moreComing) {
		[self sortAndUpdateUI];
	}
}

#pragma mark - NSNetService delegate
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	[self stopCurrentResolve];
	[self.tableView reloadData];
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"Can not resolve service" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alert show];
}

- (void)netServiceDidResolveAddress:(NSNetService *)service
{
	// was never called for me
    
    assert(service == self.currentResolve);
	[self stopCurrentResolve];
    
    [self didResolveInstanceForService:service];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    
}

- (void)netServiceWillPublish:(NSNetService *)sender
{
    
}


- (void) myRegistrationFunction:(NSUInteger) port
{
    NSNetService *service;
    
    service = [[NSNetService alloc] initWithDomain:@""// 1
                                              type:@"_music._tcp"
                                              name:@""
                                              port:port];
    if(service) {
        [service setDelegate:self];
        [service publish];
    } else {
        NSLog(@"ERROR! Can not init the NSNetService object.");
    }
}

#pragma mark - parse resolve response 
- (NSString *)getStringFromAddressData:(NSData *)dataIn {
    struct sockaddr_in  *socketAddress = nil;
    NSString            *ipString = nil;
    
    socketAddress = (struct sockaddr_in *)[dataIn bytes];
    ipString = [NSString stringWithFormat: @"%s",
                inet_ntoa(socketAddress->sin_addr)];  ///problem here
    return ipString;
}

- (NSString *)copyStringFromTXTDict:(NSDictionary *)dict which:(NSString*)which
{
	if (!dict) {
        return nil;
    }
    
    NSData* data = [dict objectForKey:which];
	NSString *resultString = nil;
	if (data) {
		resultString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
	return resultString;
}

- (void)didResolveInstanceForService:(NSNetService*)service
{
	NSDictionary* dict = [NSNetService dictionaryFromTXTRecordData:[service TXTRecordData]];
	NSString *host = [service hostName];
	
	NSString* user = [self copyStringFromTXTDict:dict which:@"u"];
	NSString* pass = [self copyStringFromTXTDict:dict which:@"p"];
	
    NSString* addressesIPString = nil;
    if ([service addresses]) {
        for (NSData* ipData in [service addresses]) {
            NSString* addressString = [self getStringFromAddressData:ipData];
            if (addressString) {
                if (!addressesIPString) {
                    addressesIPString = addressString;
                } else {
                    addressesIPString = [NSString stringWithFormat:@"%@, %@", addressesIPString, addressString];
                }
            }
        }
    }

    NSString* portStr = @"";
	NSInteger port = [service port];
    if (port != 0 && port != 80) {
        portStr = [[NSString alloc] initWithFormat:@"%d",port];
    }
	
	NSString* path = [self copyStringFromTXTDict:dict which:@"path"];
	if (!path || [path length] == 0) {
        path = @"/";
	} else if (![[path substringToIndex:1] isEqual:@"/"]) {
        NSString *tempPath = [[NSString alloc] initWithFormat:@"/%@",path];
        path = tempPath;
	}
    
    NSString* alertMessage = [NSString stringWithFormat:@" host : %@\n user : %@\n password : %@\n port : %@ \n path : %@ \n addersses : %@", host, user, pass, portStr, path, addressesIPString];
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Service Data" message:alertMessage delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    
    NSArray *subviews = alert.subviews;
    UILabel *messageLabel = [subviews objectAtIndex:1];
    messageLabel.textAlignment = UITextAlignmentLeft;
    
    [alert show];
}
    
@end
