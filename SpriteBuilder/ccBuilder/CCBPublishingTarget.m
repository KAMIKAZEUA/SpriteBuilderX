#import "CCBPublishingTarget.h"
#import "ProjectSettings.h"
#import "PublishRenamedFilesLookup.h"
#import "MiscConstants.h"


@implementation CCBPublishingTarget

- (id)init
{
    self = [super init];
    if (self)
    {
        self.publishEnvironment = kCCBPublishEnvironmentDevelop;
        self.publishedSpriteSheetFiles = [[NSMutableSet alloc] init];
        self.renamedFilesLookup = [[PublishRenamedFilesLookup alloc] init];
        self.platform = nil;
        //self.audioQuality = DEFAULT_AUDIO_QUALITY;
    }

    return self;
}

@end