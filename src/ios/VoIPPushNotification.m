#import "VoIPPushNotification.h"
#import <Cordova/CDV.h>
#import <CallKit/CallKit.h>

@interface VoIPPushNotification()<CXProviderDelegate> {
    CXProvider *callProvider;
}
@end

@implementation VoIPPushNotification

@synthesize VoIPPushCallbackId;



- (void)init:(CDVInvokedUrlCommand*)command
{
  self.VoIPPushCallbackId = command.callbackId;
  NSLog(@"[objC] callbackId: %@", self.VoIPPushCallbackId);

  //http://stackoverflow.com/questions/27245808/implement-pushkit-and-test-in-development-behavior/28562124#28562124
  PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
  pushRegistry.delegate = self;
  pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    
    CXProviderConfiguration* config = [[CXProviderConfiguration alloc] initWithLocalizedName:@"VoIP Service"];
    config.supportsVideo = true;
    config.supportedHandleTypes = [NSSet setWithObjects:[NSNumber numberWithInteger:CXHandleTypePhoneNumber], nil];

    config.maximumCallsPerCallGroup = 1;
    // Create the provider and attach the custom delegate object
    // used by the app to respond to updates.
    callProvider = [[CXProvider alloc] initWithConfiguration:config];
    [callProvider setDelegate:self queue:nil];

}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type{
    if([credentials.token length] == 0) {
        NSLog(@"[objC] No device token!");
        return;
    }

    //http://stackoverflow.com/a/9372848/534755
    NSLog(@"[objC] Device token: %@", credentials.token);
    const unsigned *tokenBytes = [credentials.token bytes];
    NSString *sToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                         ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                         ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                         ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

    NSMutableDictionary* results = [NSMutableDictionary dictionaryWithCapacity:2];
    [results setObject:sToken forKey:@"deviceToken"];
    [results setObject:@"true" forKey:@"registration"];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:results];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]]; //[pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.VoIPPushCallbackId];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    NSDictionary *payloadDict = payload.dictionaryPayload[@"aps"];
    NSLog(@"[objC] didReceiveIncomingPushWithPayload: %@", payloadDict);

    NSString *message = payloadDict[@"alert"];
    NSLog(@"[objC] received VoIP msg: %@", message);
    
    
    NSUUID *uuid = [[NSUUID alloc] init];
//    NSString* uuid = @"20B0DDE7-6087-4607-842A-E97C72E4D522";
//    NSString *callerName = payload.dictionaryPayload[@"aps"][@"alert"][@"receiver_name"];
    NSString *handle = @"Life111";

    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:handle];
    callUpdate.hasVideo = true;

    [callProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError * _Nullable error) {
        if (error == nil) {
            //           let newCall = VoipCall(callUUID, phoneNumber: phoneNumber)
            //           self.callManager.addCall(newCall)
        }
//        completion()
    }];

    NSMutableDictionary* results = [NSMutableDictionary dictionaryWithCapacity:2];
    [results setObject:message forKey:@"function"];
    [results setObject:@"someOtherDataForField" forKey:@"someOtherField"];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:results];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.VoIPPushCallbackId];
}

@end
