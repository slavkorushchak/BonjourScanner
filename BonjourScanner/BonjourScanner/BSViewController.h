//
//  BSViewController.h
//  BonjourScanner
//
//  Created by Slavko Rushchak on 8/10/13.
//  Copyright (c) 2013 Slavko Rushchak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BSViewController : UIViewController <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

- (void) refreshServicesList;
@end