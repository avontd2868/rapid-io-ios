//
//  AzureHubSender.h
//  RapiChat iOS
//
//  Created by Jan on 08/09/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>

@interface AzureHubSender : NSObject <NSXMLParserDelegate>
@property (copy, nonatomic) NSString *statusResult;
@property (copy, nonatomic) NSString *currentElement;

-(void)sendNotification:(NSString*)text toChannel:(NSString*)channel;
@end
