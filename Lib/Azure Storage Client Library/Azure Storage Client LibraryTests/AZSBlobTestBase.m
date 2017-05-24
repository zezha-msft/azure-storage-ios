// -----------------------------------------------------------------------------------------
// <copyright file="AZSBlobTestBase.m" company="Microsoft">
//    Copyright 2015 Microsoft Corporation
//
//    Licensed under the MIT License;
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//      http://spdx.org/licenses/MIT
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
// </copyright>
// -----------------------------------------------------------------------------------------

#import "AZSBlobTestBase.h"
#import "AZSClient.h"
#import "AZSTestHelpers.h"

@implementation AZSBlobTestSpinWrapper

@end

@implementation AZSBlobTestBase

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    self.blobClient = [self.account getBlobClient];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

-(void)waitForCopyToCompleteWithBlob:(AZSCloudBlob *)blobToMonitor completionHandler:(void (^)(NSError *, BOOL))completionHandler
{
    [blobToMonitor downloadAttributesWithCompletionHandler:^(NSError *error) {
        if (error)
        {
            completionHandler(error, YES);
        }
        else
        {
            if (blobToMonitor.blobCopyState.copyStatus == AZSCopyStatusPending)
            {
                [NSThread sleepForTimeInterval:1.0];
                [self waitForCopyToCompleteWithBlob:blobToMonitor completionHandler:completionHandler];
            }
            else
            {
                completionHandler(nil, blobToMonitor.blobCopyState.copyStatus == AZSCopyStatusSuccess);
            }
        }
    }];
}

// TOASK this doesn't actually create the new thread, rename??
-(void)scheduleStreamInNewThreaAndRunWithWrapper:(AZSBlobTestSpinWrapper *)wrapper
{
    [wrapper.stream setDelegate:wrapper.delegate];
    [wrapper.stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [wrapper.stream open];
    
    while (!wrapper.delegate.streamFailed && (wrapper.stream.streamStatus != NSStreamStatusClosed))
    {
        BOOL loopSuccess = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        if (!loopSuccess)
        {
            break;
        }
    }
    
    [wrapper.stream close];
    [wrapper.stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    if (wrapper.completionHandler)
    {
        wrapper.completionHandler();
    }
}

@end
