//
//  BSViewController.m
//  BonjourScanner
//
//  Created by Slavko Rushchak on 8/10/13.
//  Copyright (c) 2013 Slavko Rushchak. All rights reserved.
//

#import "BSViewController.h"
#include <arpa/inet.h>


@interface BSViewController() <UITableViewDataSource, UITableViewDelegate>
{
    NSString* searchingForServicesString;
    
    NSMutableDictionary* services;
    
    NSMutableArray* protocolsArray;
}

@property (nonatomic, strong) UITableView* tableView;

@property (nonatomic, strong) NSNetServiceBrowser* netServiceBrowser;
@property (nonatomic, strong) NSNetServiceBrowser* netServiceBrowserSpecific;
@property (nonatomic, strong) NSNetService* currentResolve;

@end

@implementation BSViewController
#pragma mark - Initialization
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.title = @"Bonjour Scanner";
        services = [[NSMutableDictionary alloc] init];
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

- (void) initRefreshButton
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStyleBordered
                                                                                                  target:self action:@selector(refreshServicesList)];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self initTableView];
    [self initRefreshButton];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshServicesList];
}

#pragma mark - Search Bonjour services
- (void) refreshServicesList
{
    BOOL canBeSearched = [self searchForAllServices];
    if (!canBeSearched) {
        NSLog(@"ERROR! can not init NSNetServiceBrowser");
    }
}

- (BOOL)searchForAllServices
{	
	[self stopCurrentResolve];
	[_netServiceBrowser stop];
    [_netServiceBrowserSpecific stop];
	[services removeAllObjects];
    
	NSNetServiceBrowser *aNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if(!aNetServiceBrowser) {
		return NO;
	}
    
	aNetServiceBrowser.delegate = self;
	self.netServiceBrowser = aNetServiceBrowser;    
    [self.netServiceBrowser searchForServicesOfType:@"_services._dns-sd._udp." inDomain:@""];
    
	[self.tableView reloadData];
	return YES;
}

- (void) searchForSpecificType:(NSString*)type
{
    [self stopCurrentResolve];
    [_netServiceBrowser stop];
    [_netServiceBrowserSpecific stop];
    
	NSNetServiceBrowser *aNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if(!aNetServiceBrowser) {
		return;
	}
    
    aNetServiceBrowser.delegate = self;
	self.netServiceBrowserSpecific = aNetServiceBrowser;

	[aNetServiceBrowser searchForServicesOfType:type inDomain:@""];
}

- (void)stopCurrentResolve
{
	[self.currentResolve stop];
	self.currentResolve = nil;
}

#pragma mark - UITableView delegate/datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[services allKeys] count] > 0 ? [[services allKeys] count] : 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[services allKeys] count] > 0 ? [[services allKeys] objectAtIndex:section] : nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([services count] == 0) {
        return 1;
    }
    NSString* currentKey = [[services allKeys] objectAtIndex:section];
	NSUInteger count = [[services objectForKey:currentKey] count];
    
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
	
	NSUInteger count = [[services allValues] count];
	if (count == 0 && searchingForServicesString) {
        cell.textLabel.text = searchingForServicesString;
		cell.textLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
		return cell;
	}
	
    NSString* currentKey = [[services allKeys] objectAtIndex:indexPath.section];
	NSNetService* service = [[services objectForKey:currentKey] objectAtIndex:indexPath.row];
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
	
    NSString* currentKey = [[services allKeys] objectAtIndex:indexPath.section];
	self.currentResolve = [[services objectForKey:currentKey] objectAtIndex:indexPath.row];
	
    [self.currentResolve setDelegate:self];
	[self.currentResolve resolveWithTimeout:0.0];
}

#pragma mark - NSNetServiceBrovser delegate
- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser
         didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing
{
	if (self.currentResolve && [service isEqual:self.currentResolve]) {
		[self stopCurrentResolve];
	}
    
	[[services objectForKey:service.type] removeObject:service];
	
	if (!moreComing) {
		[self.tableView reloadData];
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser
           didFindService:(NSNetService*)service moreComing:(BOOL)moreComing
{    
	if (netServiceBrowser == self.netServiceBrowser) {
        NSString* name = service.name;
        NSArray* components = [service.type componentsSeparatedByString:@"."];
        NSString* protocol = nil;
        if ([components count] > 0) {
            protocol = (NSString*)[components objectAtIndex:0];
        }
        
        if (protocol && name) {
            if (!protocolsArray) {
                protocolsArray = [[NSMutableArray alloc] init];
            }
            [protocolsArray addObject:[NSString stringWithFormat:@"%@.%@.", name, protocol]]; 
        }
        
        if (!moreComing) {
            [self searchForSpecificType:protocolsArray[0]];
            [protocolsArray removeObjectAtIndex:0];
        }
        
        return;
    }
    
    if ([services objectForKey:service.type]) {
        [[services objectForKey:service.type] addObject:service];
    } else {
        NSMutableArray* sortedByType = [[NSMutableArray alloc] init];
        [sortedByType addObject:service];
        [services setObject:sortedByType forKey:service.type];
    }

	if (!moreComing) {
		[self.tableView reloadData];
        
        if ([protocolsArray count] > 0) {
            [self searchForSpecificType:protocolsArray[0]];
            [protocolsArray removeObjectAtIndex:0];
        }
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
    assert(service == self.currentResolve);
	[self stopCurrentResolve];
    
    [self didResolveInstanceForService:service];
}

#pragma mark - Parse resolve response
- (NSString *)getStringFromAddressData:(NSData *)dataIn
{
    struct sockaddr_in *socketAddress = nil;
    NSString *ipString = nil;
    
    socketAddress = (struct sockaddr_in *)[dataIn bytes];
    ipString = [NSString stringWithFormat: @"%s",
                inet_ntoa(socketAddress->sin_addr)];
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
