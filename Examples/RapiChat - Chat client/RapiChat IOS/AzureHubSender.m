//
//  AzureHubSender.m
//  RapiChat iOS
//
//  Created by Jan on 08/09/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

#import "AzureHubSender.h"

#define HUBNAME @"RapiChat"
#define API_VERSION @"?api-version=2015-01"
#define HUBFULLACCESS @"Endpoint=sb://rapichat.servicebus.windows.net/;SharedAccessKeyName=DefaultFullSharedAccessSignature;SharedAccessKey=C2ecROm6T2pZa25KgLSfACDlilFL+3FD5jGmXQqmVLU="

@implementation AzureHubSender
NSString *HubEndpoint;
NSString *HubSasKeyName;
NSString *HubSasKeyValue;

-(id)init {
    self = [super init];
    [self ParseConnectionString];
    return self;
}

-(void)ParseConnectionString
{
    NSArray *parts = [HUBFULLACCESS componentsSeparatedByString:@";"];
    NSString *part;
    
    if ([parts count] != 3)
    {
        NSException* parseException = [NSException exceptionWithName:@"ConnectionStringParseException"
                                                              reason:@"Invalid full shared access connection string" userInfo:nil];
        
        @throw parseException;
    }
    
    for (part in parts)
    {
        if ([part hasPrefix:@"Endpoint"])
        {
            HubEndpoint = [NSString stringWithFormat:@"https%@",[part substringFromIndex:11]];
        }
        else if ([part hasPrefix:@"SharedAccessKeyName"])
        {
            HubSasKeyName = [part substringFromIndex:20];
        }
        else if ([part hasPrefix:@"SharedAccessKey"])
        {
            HubSasKeyValue = [part substringFromIndex:16];
        }
    }
}
-(NSString *)CF_URLEncodedString:(NSString *)inputString
{
    return (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)inputString,
                                                                        NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
}

-(void)sendNotification:(NSString *)text toChannel:(NSString *)channel {
    NSURLSession* session = [NSURLSession
                             sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                             delegate:nil delegateQueue:nil];
    
    // Apple Notification format of the notification message
    NSString *json = [NSString stringWithFormat:@"{\"aps\":{\"alert\":\"%@\"}}",
                      text];
    
    // Construct the message's REST endpoint
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/messages/%@", HubEndpoint,
                                       HUBNAME, API_VERSION]];
    
    // Generate the token to be used in the authorization header
    NSString* authorizationToken = [self generateSasToken:[url absoluteString]];
    
    //Create the request to add the APNs notification message to the hub
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    // Signify Apple notification format
    [request setValue:@"apple" forHTTPHeaderField:@"ServiceBusNotification-Format"];
    
    //Authenticate the notification message POST request with the SaS token
    [request setValue:authorizationToken forHTTPHeaderField:@"Authorization"];
    
    //Add the notification message body
    [request setHTTPBody:[json dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Send the REST request
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*) response;
                                          if (error || (httpResponse.statusCode != 200 && httpResponse.statusCode != 201))
                                          {
                                              NSLog(@"\nError status: %ld\nError: %@", (long)httpResponse.statusCode, error);
                                          }
                                          if (data != NULL)
                                          {
                                              NSXMLParser* xmlParser = [[NSXMLParser alloc] initWithData:data];
                                              [xmlParser setDelegate:self];
                                              [xmlParser parse];
                                          }
                                      }];
    [dataTask resume];
}

-(NSString*) generateSasToken:(NSString*)uri
{
    NSString *targetUri;
    NSString* utf8LowercasedUri = NULL;
    NSString *signature = NULL;
    NSString *token = NULL;
    
    @try
    {
        // Add expiration
        uri = [uri lowercaseString];
        utf8LowercasedUri = [self CF_URLEncodedString:uri];
        targetUri = [utf8LowercasedUri lowercaseString];
        NSTimeInterval expiresOnDate = [[NSDate date] timeIntervalSince1970];
        int expiresInMins = 60; // 1 hour
        expiresOnDate += expiresInMins * 60;
        UInt64 expires = trunc(expiresOnDate);
        NSString* toSign = [NSString stringWithFormat:@"%@\n%qu", targetUri, expires];
        
        // Get an hmac_sha1 Mac instance and initialize with the signing key
        const char *cKey  = [HubSasKeyValue cStringUsingEncoding:NSUTF8StringEncoding];
        const char *cData = [toSign cStringUsingEncoding:NSUTF8StringEncoding];
        unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
        CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
        NSData *rawHmac = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
        signature = [self CF_URLEncodedString:[rawHmac base64EncodedStringWithOptions:0]];
        
        // Construct authorization token string
        token = [NSString stringWithFormat:@"SharedAccessSignature sig=%@&se=%qu&skn=%@&sr=%@",
                 signature, expires, HubSasKeyName, targetUri];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception Generating SaS Token : %@ ***",[exception reason]);
    }
    @finally
    {
        if (utf8LowercasedUri != NULL)
            CFRelease((CFStringRef)utf8LowercasedUri);
        if (signature != NULL)
            CFRelease((CFStringRef)signature);
    }
    
    return token;
}

-(void)parserDidStartDocument:(NSXMLParser *)parser
{
    self.statusResult = @"";
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
 namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
   attributes:(NSDictionary *)attributeDict
{
    NSString * element = [elementName lowercaseString];
    NSLog(@"*** New element parsed : %@ ***",element);
    
    if ([element isEqualToString:@"code"] | [element isEqualToString:@"detail"])
    {
        self.currentElement = element;
    }
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)parsedString
{
    self.statusResult = [self.statusResult stringByAppendingString:
                         [NSString stringWithFormat:@"%@ : %@\n", self.currentElement, parsedString]];
}

-(void)parserDidEndDocument:(NSXMLParser *)parser
{
    // Set the status label text on the UI thread
    /*dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self.sendResults setText:self.statusResult];
                   });*/
}

@end
