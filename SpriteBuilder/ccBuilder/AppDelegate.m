/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2011 Viktor Lidholt
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "AppDelegate.h"
#import "CocosScene.h"
#import "SceneGraph.h"
#import "CCBGLView.h"
#import "NSFlippedView.h"
#import "CCBGlobals.h"
#import "cocos2d.h"
#import "CCBWriterInternal.h"
#import "CCBReaderInternal.h"
#import "CCBReaderInternalV1.h"
#import "CCBDocument.h"
#import "NewDocWindowController.h"
#import "CCBSpriteSheetParser.h"
#import "CCBUtil.h"
#import "StageSizeWindow.h"
#import "GuideGridSizeWindow.h"
#import "ResolutionSettingsWindow.h"
#import "PlugInManager.h"
#import "InspectorPosition.h"
#import "NodeInfo.h"
#import "PlugInNode.h"
#import "PlugInExport.h"
#import "TexturePropertySetter.h"
#import "PositionPropertySetter.h"
#import "ResourceManager.h"
#import "GuidesLayer.h"
#import "RulersLayer.h"
#import "NSString+RelativePath.h"
#import "CCBTransparentWindow.h"
#import "CCBTransparentView.h"
#import "NotesLayer.h"
#import "ResolutionSetting.h"
#import "ProjectSettingsWindowController.h"
#import "ProjectSettings.h"
#import "ResourceManagerOutlineHandler.h"
#import "ResourceManagerOutlineView.h"
#import "SavePanelLimiter.h"
#import "CCBWarnings.h"
#import "TaskStatusWindow.h"
#import "SequencerHandler.h"
#import "MainWindow.h"
#import "CCNode+NodeInfo.h"
#import "SequencerNodeProperty.h"
#import "SequencerSequence.h"
#import "SequencerSettingsWindow.h"
#import "SequencerDurationWindow.h"
#import "SequencerIdWindow.h"
#import "SequencerKeyframe.h"
#import "SequencerKeyframeEasing.h"
#import "SequencerKeyframeEasingWindow.h"
#import "SequencerUtil.h"
#import "SequencerStretchWindow.h"
#import "SequencerSoundChannel.h"
#import "SequencerCallbackChannel.h"
#import "SequencerJoints.h"
#import "SoundFileImageController.h"
#import "CustomPropSettingsWindow.h"
#import "CustomPropSetting.h"
#import "MainToolbarDelegate.h"
#import "InspectorSeparator.h"
#import "NodeGraphPropertySetter.h"
#import "CCBSplitHorizontalView.h"
#import "AboutWindow.h"
#import "CCBFileUtil.h"
#import "ResourceManagerUtil.h"
#import "SMTabBar.h"
#import "SMTabBarItem.h"
#import "ResourceManagerTilelessEditorManager.h"
#import "CCBImageBrowserView.h"
#import "PlugInNodeViewHandler.h"
#import "PropertyInspectorTemplateHandler.h"
#import "LocalizationEditorHandler.h"
#import "PhysicsHandler.h"
#import "CCBProjectCreator.h"
#import "CCTextureCache.h"
#import "CCLabelBMFont_Private.h"
#import "WarningTableViewHandler.h"
#import "CCNode+NodeInfo.h"
#import "CCNode_Private.h"
#import <ExceptionHandling/NSExceptionHandler.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <MacTypes.h>
#import "PlugInNodeCollectionView.h"
#import "SBErrors.h"
#import "NSArray+Query.h"
#import "SBUserDefaultsKeys.h"
#import "MiscConstants.h"
#import "FeatureToggle.h"
#import "AnimationPlaybackManager.h"
#import "NotificationNames.h"
#import "ResourceTypes.h"
#import "RMDirectory.h"
#import "RMResource.h"
#import "PackageImporter.h"
#import "PackageCreator.h"
#import "ResourceCommandController.h"
#import "ProjectSettings+Convenience.h"
#import "CCBDocumentDataCreator.h"
#import "CCBPublisherCacheCleaner.h"
#import "CCBPublisherController.h"
#import "ResourceManager+Publishing.h"
#import "CCNode+NodeInfo.h"
#import "PreviewContainerViewController.h"
#import "InspectorController.h"
#import "EditClassWindow.h"
#import "SettingsWindow.h"
#import "SettingsManager.h"
#import "PlatformSettings.h"

static const int CCNODE_INDEX_LAST = -1;

@interface AppDelegate()

@property (nonatomic, strong) CCBPublisherController *publisherController;
@property (nonatomic, strong) ResourceCommandController *resourceCommandController;

@end

@implementation DeviceBorder : NSObject

+ (DeviceBorder*) createWithFrameName:(NSString*)frameName andRotated:(BOOL)rotated andScale:(float)scale
{
    DeviceBorder* ret = [[DeviceBorder alloc] init];
    if(ret)
    {
        ret->_frameName = frameName;
        ret->_rotated = rotated;
        ret->_scale = scale;
    }
    return ret;
}

@end

@implementation AppDelegate

@synthesize window;
@synthesize projectSettings;
@synthesize currentDocument;
@synthesize cocosView;
@synthesize canEditContentSize;
@synthesize canEditCustomClass;
@synthesize hasOpenedDocument;
@synthesize defaultCanvasSize;
@synthesize projectOutlineHandler;
@synthesize showExtras;
@synthesize showGuides;
@synthesize showGuideGrid;
@synthesize showStickyNotes;
@synthesize snapToggle;
@synthesize snapGrid;
@synthesize snapToGuides;
@synthesize snapNode;
@synthesize guiView;
@synthesize guiWindow;
@synthesize menuContextKeyframe;
@synthesize menuContextKeyframeInterpol;
@synthesize menuContextKeyframeNoselection;
@synthesize outlineProject;
@synthesize errorDescription;
@synthesize selectedNodes;
@synthesize loadedSelectedNodes;
@synthesize panelVisibilityControl;
@synthesize localizationEditorHandler;
@synthesize physicsHandler;
@synthesize itemTabView;
@dynamic selectedNodeCanHavePhysics;
@synthesize playingBack;
@dynamic	showJoints;

static AppDelegate* sharedAppDelegate = nil;

#pragma mark Setup functions

+ (AppDelegate*) appDelegate
{
    return sharedAppDelegate;
}

//This function replaces the current CCNode visit with "customVisit" to ensure that 'hidden' flagged nodes are invisible.
//However it then proceeds to call the real '[CCNode visit]' (now renamed oldVisit).
void ApplyCustomNodeVisitSwizzle()
{
	
    Method origMethod = class_getInstanceMethod([CCNode class], @selector(visit:parentTransform:));
    Method newMethod = class_getInstanceMethod([CCNode class], @selector(customVisit:parentTransform:));
    
    IMP origImp = method_getImplementation(origMethod);
    IMP newImp = method_getImplementation(newMethod);
    
    class_replaceMethod([CCNode class], @selector(visit:parentTransform:), newImp, method_getTypeEncoding(newMethod));
    class_addMethod([CCNode class], @selector(oldVisit:parentTransform:), origImp, method_getTypeEncoding(origMethod));
}

- (void) setupCocos2d
{
    ApplyCustomNodeVisitSwizzle();
    // Insert code here to initialize your application
    CCDirectorMac *director = (CCDirectorMac*) [CCDirector sharedDirector];
	
	[director setDisplayStats:NO];
	[director setProjection:CCDirectorProjection2D];
    //[cocosView openGLContext];
    
	NSAssert(cocosView, @"cocosView is nil");
    
    // TODO: Add support for retina display
    // [cocosView setWantsBestResolutionOpenGLSurface:YES];
	[director setView:cocosView];
    
    [self updatePositionScaleFactor];
    
    [director reshapeProjection:cocosView.frame.size];
    
	// EXPERIMENTAL stuff.
	// 'Effects' don't work correctly when autoscale is turned on.
	// Use kCCDirectorResize_NoScale if you don't want auto-scaling.
	[director setResizeMode:kCCDirectorResize_NoScale];
	
	// Enable "moving" mouse event. Default no.
	//[window setAcceptsMouseMovedEvents:YES];
	
	[director runWithScene:[CocosScene sceneWithAppDelegate:self]];
	
	NSAssert( [NSThread currentThread] == [[CCDirector sharedDirector] runningThread],
			 @"cocos2d should run on the Main Thread. Compile SpriteBuilder with CC_DIRECTOR_MAC_THREAD=2");
}

- (void) setupSequenceHandler
{
    sequenceHandler = [[SequencerHandler alloc] initWithOutlineView:outlineHierarchy];
    sequenceHandler.scrubberSelectionView = scrubberSelectionView;
    sequenceHandler.timeDisplay = timeDisplay;
    sequenceHandler.timeScaleSlider = timeScaleSlider;
    sequenceHandler.scroller = timelineScroller;
    sequenceHandler.scrollView = sequenceScrollView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSoundImages:) name:kSoundFileImageLoaded object:nil];
    
    [self updateTimelineMenu];
    [sequenceHandler updateScaleSlider];
}

-(void)updateSoundImages:(NSNotification*)notice
{
    [outlineHierarchy reloadData];
}

- (void) setupTabBar
{
    // Create tabView
    tabView = [[NSTabView alloc] initWithFrame:NSMakeRect(0, 0, 500, 30)];
    [tabBar setTabView:tabView];
    [tabView setDelegate:tabBar];
    [tabBar setDelegate:self];
    
    // Settings for tabBar
    [tabBar setShowAddTabButton:NO];
    [tabBar setSizeCellsToFit:YES];
    [tabBar setUseOverflowMenu:YES];
    [tabBar setHideForSingleTab:NO];
    [tabBar setAllowsResizing:YES];
    [tabBar setAlwaysShowActiveTab:YES];
    [tabBar setAllowsScrubbing:YES];
    [tabBar setCanCloseOnlyTab:YES];
    
    [window setShowsToolbarButton:NO];
}

- (void) setupPlugInNodeView
{
    plugInNodeViewHandler  = [[PlugInNodeViewHandler alloc] initWithCollectionView:plugInNodeCollectionView];
}

- (void) setupProjectViewTabBar
{
    NSMutableArray* items = [NSMutableArray array];
    
    NSImage* imgFolder = [NSImage imageNamed:@"inspector-folder.png"];
    [imgFolder setTemplate:YES];
    SMTabBarItem* itemFolder = [[SMTabBarItem alloc] initWithImage:imgFolder tag:0];
    itemFolder.toolTip = @"File View";
    itemFolder.keyEquivalent = @"";
    [items addObject:itemFolder];
    
    NSImage* imgObjs = [NSImage imageNamed:@"inspector-objects.png"];
    [imgObjs setTemplate:YES];
    SMTabBarItem* itemObjs = [[SMTabBarItem alloc] initWithImage:imgObjs tag:1];
    itemObjs.toolTip = @"Tileless Editor View";
    itemObjs.keyEquivalent = @"";
    [items addObject:itemObjs];
    
    NSImage* imgNodes = [NSImage imageNamed:@"inspector-nodes.png"];
    [imgNodes setTemplate:YES];
    SMTabBarItem* itemNodes = [[SMTabBarItem alloc] initWithImage:imgNodes tag:2];
    itemNodes.toolTip = @"Node Library View";
    itemNodes.keyEquivalent = @"";
    [items addObject:itemNodes];
    
    NSImage* imgWarnings = [NSImage imageNamed:@"inspector-warning.png"];
    [imgWarnings setTemplate:YES];
    SMTabBarItem* itemWarnings = [[SMTabBarItem alloc] initWithImage:imgWarnings tag:3];
    itemWarnings.toolTip = @"Warnings view";
    itemWarnings.keyEquivalent = @"";
    [items addObject:itemWarnings];

    projectViewTabs.items = items;
    projectViewTabs.delegate = self;
}

typedef enum
{
	eItemViewTabType_Properties,
	eItemViewTabType_CodeConnections,
	eItemViewTabType_Physics,
	eItemViewTabType_Template
	
} eItemViewTabType;

- (void) setupItemViewTabBar
{
    NSMutableArray* items = [NSMutableArray array];
    
    NSImage* imgProps = [NSImage imageNamed:@"inspector-props.png"];
    [imgProps setTemplate:YES];
    SMTabBarItem* itemProps = [[SMTabBarItem alloc] initWithImage:imgProps tag:0];
    itemProps.toolTip = @"Item Properties";
    itemProps.keyEquivalent = @"";
	itemProps.tag = eItemViewTabType_Properties;
    [items addObject:itemProps];
    
    NSImage* imgCode = [NSImage imageNamed:@"inspector-codeconnections.png"];
    [imgCode setTemplate:YES];
    SMTabBarItem* itemCode = [[SMTabBarItem alloc] initWithImage:imgCode tag:0];
    itemCode.toolTip = @"Item Code Connections";
    itemCode.keyEquivalent = @"";
	itemCode.tag = eItemViewTabType_CodeConnections;
    [items addObject:itemCode];
    
    NSImage* imgPhysics = [NSImage imageNamed:@"inspector-physics"];
    [imgPhysics setTemplate:YES];
    SMTabBarItem* itemPhysics = [[SMTabBarItem alloc] initWithImage:imgPhysics tag:0];
    itemPhysics.toolTip = @"Item Physics";
    itemPhysics.keyEquivalent = @"";
	itemPhysics.tag = eItemViewTabType_Physics;
    [items addObject:itemPhysics];
    
    NSImage* imgTemplate = [NSImage imageNamed:@"inspector-template.png"];
    [imgTemplate setTemplate:YES];
    SMTabBarItem* itemTemplate = [[SMTabBarItem alloc] initWithImage:imgTemplate tag:0];
    itemTemplate.toolTip = @"Item Templates";
    itemTemplate.keyEquivalent = @"";
	itemTemplate.tag = eItemViewTabType_Template;
    [items addObject:itemTemplate];
    
    itemViewTabs.items = items;
    itemViewTabs.delegate = self;
}

- (void)tabBar:(SMTabBar *)tb didSelectItem:(SMTabBarItem *)item
{
    if (tb == projectViewTabs)
    {
        [projectTabView selectTabViewItemAtIndex:[projectViewTabs.items indexOfObject:item]];
    }
    else if (tb == itemViewTabs)
    {
        [itemTabView selectTabViewItemAtIndex:[itemViewTabs.items indexOfObject:item]];
    }
}

- (void) updateSmallTabBarsEnabled
{
    // Set enable for open project
    BOOL allEnable = (projectSettings != NULL);
    
    if (!allEnable)
    {
        // If project isn't open, set selected tab to the first one
        [projectViewTabs setSelectedItem:[projectViewTabs.items objectAtIndex:0]];
        [projectTabView selectTabViewItemAtIndex:0];
        
        [itemViewTabs setSelectedItem:[itemViewTabs.items objectAtIndex:0]];
        [itemTabView selectTabViewItemAtIndex:0];
    }
    
    // Update enable for project
    for (SMTabBarItem* item in projectViewTabs.items)
    {
        item.enabled = allEnable;
    }
    
    // Update enable depending on if object is selected
    BOOL itemEnable = (self.selectedNode != NULL);
	BOOL physicsEnabled = (!self.selectedNode.plugIn.isJoint)  && (![self.selectedNode.plugIn.nodeClassName isEqualToString:@"CCBFile"]);
	
    for (SMTabBarItem* item in itemViewTabs.items)
    {
		if(item.tag == eItemViewTabType_Physics && !physicsEnabled)
		{
			item.enabled = NO;
			continue;
		}
		
        item.enabled = allEnable && itemEnable;
    }
    
    BOOL templateEnable = (itemEnable && self.selectedNode.plugIn.supportsTemplates);
    SMTabBarItem* templateItem = [itemViewTabs.items objectAtIndex:3];
    templateItem.enabled = templateEnable;

    if (!templateEnable && [itemViewTabs selectedItem] == templateItem)
    {
        // If template isn't available select first tab instead
        [itemViewTabs setSelectedItem:[itemViewTabs.items objectAtIndex:0]];
        [itemTabView selectTabViewItemAtIndex:0];
    }
}

- (void) setupProjectTilelessEditor
{
    tilelessEditorManager = [[ResourceManagerTilelessEditorManager alloc] initWithImageBrowser:projectImageBrowserView];
    [tilelessEditorTableFilterView setDataSource:tilelessEditorManager];
    [tilelessEditorTableFilterView setDelegate:tilelessEditorManager];
    [tilelessEditorTableFilterView setBackgroundColor:[NSColor colorWithCalibratedRed:0.93 green:0.93 blue:0.93 alpha:2]];
    [tilelessEditorSplitView setDelegate:tilelessEditorManager];
}

- (void) setupResourceManager
{
    NSColor * color = [NSColor colorWithCalibratedRed:0.0f green:0.50f blue:0.50f alpha:1.0f];
    
    color = [color colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];

    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    
    NSColor * color2 = [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
    NSColor * calibratedColor = [color2 colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

    NSLog(@"R:%f G:%f B:%f A:%f",calibratedColor.redComponent, calibratedColor.greenComponent, calibratedColor.blueComponent, calibratedColor.alphaComponent);
    
    // Load resource manager
	[ResourceManager sharedManager].projectSettings = projectSettings;
    

    // Setup project display
    projectOutlineHandler = [[ResourceManagerOutlineHandler alloc] initWithOutlineView:outlineProject
                                                                               resType:kCCBResTypeNone
                                                                     previewController:_previewContainerViewController];
    projectOutlineHandler.projectSettings = projectSettings;
    resourceManagerSplitView.delegate = _previewContainerViewController;

    //Setup warnings outline
    warningHandler = [[WarningTableViewHandler alloc] init];
    
    self.warningTableView.delegate = warningHandler;
    self.warningTableView.target = warningHandler;
    self.warningTableView.dataSource = warningHandler;
    [self updateWarningsOutline];
}

- (void) setupGUIWindow
{
    NSRect frame = cocosView.frame;
    
    frame.origin = [cocosView convertPoint:NSZeroPoint toView:NULL];
    frame.origin.x += self.window.frame.origin.x;
    frame.origin.y += self.window.frame.origin.y;
    
    guiWindow = [[CCBTransparentWindow alloc] initWithContentRect:frame];
    
    guiView = [[CCBTransparentView alloc] initWithFrame:cocosView.frame];
    [guiWindow setContentView:guiView];
    guiWindow.delegate = self;
    
    guiWindow.backgroundColor = [NSColor clearColor];
    
    [window addChildWindow:guiWindow ordered:NSWindowAbove];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    [SBUserDefaults setObject:@YES forKey:@"ApplePersistenceIgnoreState"];
    [SBUserDefaults registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
    
    [self registerUserDefaults];

    [self registerNotificationObservers];

    
    // Initialize Audio
    //[OALSimpleAudio sharedInstance];

    [self setupFeatureToggle];
    
    selectedNodes = [[NSMutableArray alloc] init];
    loadedSelectedNodes = [[NSMutableArray alloc] init];
    
    sharedAppDelegate = self;
    
    [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask: NSLogUncaughtExceptionMask | NSLogUncaughtSystemExceptionMask | NSLogUncaughtRuntimeErrorMask];
    
    defaultCanvasSizes = [NSMutableDictionary dictionary];
    
    // iOS
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone.png" andRotated:YES andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(480, 320)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone.png" andRotated:NO andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(320, 480)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone.png" andRotated:YES andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(960, 640)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone.png" andRotated:NO andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(640, 960)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone5.png" andRotated:YES andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(568, 320)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone5.png" andRotated:NO andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(320, 568)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone5.png" andRotated:YES andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(1136, 640)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone5.png" andRotated:NO andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(640, 1136)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone6.png" andRotated:YES andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(667, 375)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone6.png" andRotated:NO andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(375, 667)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone6.png" andRotated:YES andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(1334, 750)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone6.png" andRotated:NO andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(750, 1334)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone6Plus.png" andRotated:YES andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(960, 540)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone6Plus.png" andRotated:NO andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(540, 960)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone6Plus.png" andRotated:YES andScale:4.0] forKey:[NSValue valueWithSize:CGSizeMake(1920, 1080)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-iphone6Plus.png" andRotated:NO andScale:4.0] forKey:[NSValue valueWithSize:CGSizeMake(1080, 1920)]];
    
    NSString *deviceName = @"frame_iPhoneX.png";
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:deviceName andRotated:YES andScale:1.75] forKey:[NSValue valueWithSize:CGSizeMake(1218, 562)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:deviceName andRotated:NO andScale:1.75] forKey:[NSValue valueWithSize:CGSizeMake(562, 1218)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:deviceName andRotated:YES andScale:3.5] forKey:[NSValue valueWithSize:CGSizeMake(2436, 1125)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:deviceName andRotated:NO andScale:3.5] forKey:[NSValue valueWithSize:CGSizeMake(1125, 2436)]];
    
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-ipad.png" andRotated:YES andScale:0.5] forKey:[NSValue valueWithSize:CGSizeMake(512, 384)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-ipad.png" andRotated:NO andScale:0.5] forKey:[NSValue valueWithSize:CGSizeMake(384, 512)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-ipad.png" andRotated:YES andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(1024, 768)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-ipad.png" andRotated:NO andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(768, 1024)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-ipad.png" andRotated:YES andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(2048, 1536)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-ipad.png" andRotated:NO andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(1536, 2048)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-ipad.png" andRotated:YES andScale:2.17] forKey:[NSValue valueWithSize:CGSizeMake(2224, 1668)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-ipad.png" andRotated:NO andScale:2.17] forKey:[NSValue valueWithSize:CGSizeMake(1668, 2224)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-ipad.png" andRotated:YES andScale:2.668] forKey:[NSValue valueWithSize:CGSizeMake(2732, 2048)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-ipad.png" andRotated:NO andScale:2.668] forKey:[NSValue valueWithSize:CGSizeMake(2048, 2732)]];
    
    // Fixed
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-fixed.png" andRotated:YES andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(568, 384)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-fixed.png" andRotated:NO andScale:2.0] forKey:[NSValue valueWithSize:CGSizeMake(384, 568)]];
    
    // Android
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-xsmall.png" andRotated:YES andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(320, 240)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-xsmall.png" andRotated:NO andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(240, 320)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-small.png" andRotated:YES andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(480, 340)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-small.png" andRotated:NO andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(340, 480)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-medium.png" andRotated:YES andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(800, 480)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-medium.png" andRotated:NO andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(480, 800)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-720p.png" andRotated:YES andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(1280, 720)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-720.png" andRotated:NO andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(720, 1280)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-720p.png" andRotated:YES andScale:0.667] forKey:[NSValue valueWithSize:CGSizeMake(854, 480)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-720.png" andRotated:NO andScale:0.667] forKey:[NSValue valueWithSize:CGSizeMake(480, 854)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-720p.png" andRotated:YES andScale:0.75] forKey:[NSValue valueWithSize:CGSizeMake(960, 540)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-720.png" andRotated:NO andScale:0.75] forKey:[NSValue valueWithSize:CGSizeMake(540, 960)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-1024x600.png" andRotated:YES andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(1024, 600)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-1024x600.png" andRotated:NO andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(600, 1024)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-1280x800.png" andRotated:YES andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(1280, 800)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-1280x800.png" andRotated:NO andScale:1.0] forKey:[NSValue valueWithSize:CGSizeMake(800, 1280)]];
    
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-2960x1440.png" andRotated:YES andScale:4.0] forKey:[NSValue valueWithSize:CGSizeMake(2960, 1440)]];
    [defaultCanvasSizes setObject:[DeviceBorder createWithFrameName:@"frame-android-2960x1440.png" andRotated:NO andScale:4.0] forKey:[NSValue valueWithSize:CGSizeMake(1440, 2960)]];
    
    [window setDelegate:self];

    [self setupTabBar];


    [self setupCocos2d];
    [self setupSequenceHandler];
    animationPlaybackManager.sequencerHandler = sequenceHandler;

    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
    
    CocosScene* cs = [CocosScene cocosScene];
    [cs setStageBorder:0];
    [self updateCanvasBorderMenu];
    //[self updateJSControlledMenu];
    //[self updateDefaultBrowser];
    // Load plug-ins
    //[[PlugInManager sharedManager] loadPlugIns];
    
    [self setupPlugInNodeView];
    [self setupProjectViewTabBar];
    [self setupItemViewTabBar];
    [self updateSmallTabBarsEnabled];
    [self setupResourceManager];
    [self setupGUIWindow];
    [self setupProjectTilelessEditor];
    [self setupExtras];
    [self setupResourceCommandController];

	
    [window restorePreviousOpenedPanels];

    [self.window makeKeyWindow];
    
    // Install default templates
    [_propertyInspectorTemplateHandler installDefaultTemplatesReplace:NO];
    [_propertyInspectorTemplateHandler loadTemplateLibrary];

    [InspectorController setSingleton:_inspectorController];
    [self setupInspectorController];
    [_inspectorController updateInspectorFromSelection];

	_applicationLaunchComplete = YES;
    
    if (YOSEMITE_UI)
    {
        [loopButton setBezelStyle:NSTexturedRoundedBezelStyle];
    }

    if (delayOpenFiles)
    {
        [self openFiles:delayOpenFiles];
        delayOpenFiles = nil;
    }
    else
    {
        [self openLastOpenProject];
    }
    
    // Check for first run
    if (![[SBUserDefaults objectForKey:@"completedFirstRun"] boolValue])
    {
        //[self showHelp:self];
        
        // First run completed
        [SBUserDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"completedFirstRun"];
    }

    [self toggleFeatures];
    [self scheduleAutoSaveTimer];
    
}

-(void) scheduleAutoSaveTimer {
    if (autoSaveTimer) {
        [autoSaveTimer invalidate];
        autoSaveTimer = nil;
    }
    if (SBSettings.enableBackup == YES) {
        autoSaveTimer = [NSTimer scheduledTimerWithTimeInterval:SBSettings.backupInterval
                                                         target:self
                                                       selector:@selector(checkAutoSave)
                                                       userInfo:nil
                                                        repeats:YES];
    }
}

- (void)checkAutoSave
{
    //CCLOG(@"checkAutoSave");
    // Save all CCB files
    NSArray* docs = [tabView tabViewItems];
    for (int i = 0; i < [docs count]; i++)
    {
        CCBDocument* doc = [(NSTabViewItem*) docs[i] identifier];
        if (doc.isBackupDirty)
        {
            if([doc.filePath isEqualToString:currentDocument.filePath])
            {
                doc.data = [self docDataFromCurrentNodeGraph];
                doc.extraData = [self extraDocDataFromCurrentNodeGraph];
            }
            [doc storeBackup];
            doc.isBackupDirty = NO;
        }
    }
    
}

- (void)setupInspectorController
{
    _inspectorController.appDelegate = self;
    _inspectorController.cocosScene = [CocosScene cocosScene];
    _inspectorController.sequenceHandler = [SequencerHandler sharedHandler];

    [_inspectorController setupInspectorPane];
}

- (void)setupResourceCommandController
{
    _resourceCommandController = [[ResourceCommandController alloc] init];
    _resourceCommandController.resourceManagerOutlineView = outlineProject;
    _resourceCommandController.window = window;
    _resourceCommandController.resourceManager = [ResourceManager sharedManager];
    _resourceCommandController.publishDelegate = self;

    outlineProject.actionTarget = _resourceCommandController;
}

- (void)toggleFeatures
{
    // Empty at the moment, but if there is something you'd like to toggle in the scope of the AppDelegate, add it here
}

- (void)setupFeatureToggle
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Features" ofType:@"plist"];
    NSDictionary *features = [NSDictionary dictionaryWithContentsOfFile:path];
    [[FeatureToggle sharedFeatures] loadFeaturesWithDictionary:features];
}

- (void)registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateEverythingAfterSettingsChanged) name:RESOURCE_PATHS_CHANGED object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadResources) name:RESOURCES_CHANGED object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removedDocumentWithPath:) name:RESOURCE_REMOVED object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deselectAll) name:ANIMATION_PLAYBACK_WILL_START object:nil];
}

- (void)registerUserDefaults
{
    NSDictionary *defaults = @{
            LAST_VISIT_LEFT_PANEL_VISIBLE : @(1),
            LAST_VISIT_BOTTOM_PANEL_VISIBLE : @(1),
            LAST_VISIT_RIGHT_PANEL_VISIBLE : @(1)};

    [SBUserDefaults registerDefaults:defaults];
}

- (void)openLastOpenProject
{
    NSString *filePath = [SBUserDefaults valueForKey:LAST_OPENED_PROJECT_PATH];
    if (filePath)
    {
        [self openProject:filePath];
    }
}

#pragma mark Notifications to user

- (void) modalDialogTitle: (NSString*)title message:(NSString*)msg
{
    NSAlert* alert = [NSAlert alertWithMessageText:title defaultButton:@"OK" alternateButton:NULL otherButton:NULL informativeTextWithFormat:@"%@",msg];
	[alert runModal];
}

- (void) modalDialogTitle: (NSString*)title message:(NSString*)msg disableKey:(NSString*)key
{
	
	NSAlert* alert = [NSAlert alertWithMessageText:title defaultButton:@"OK" alternateButton:NULL otherButton:NULL informativeTextWithFormat:@"%@",msg];
	
	[alert setShowsSuppressionButton:YES];
	[alert runModal];
	
}

- (void)modalStatusWindowStartWithTitle:(NSString *)title isIndeterminate:(BOOL)isIndeterminate onCancelBlock:(OnCancelBlock)onCancelBlock
{
    if (!modalTaskStatusWindow)
    {
        modalTaskStatusWindow = [[TaskStatusWindow alloc] initWithWindowNibName:@"TaskStatusWindow"];
    }

    modalTaskStatusWindow.indeterminate = isIndeterminate;
    modalTaskStatusWindow.onCancelBlock = onCancelBlock;
    modalTaskStatusWindow.window.title = title;
    [modalTaskStatusWindow.window center];
    [modalTaskStatusWindow.window makeKeyAndOrderFront:self];

    [[NSApplication sharedApplication] runModalForWindow:modalTaskStatusWindow.window];
}

- (void) modalStatusWindowFinish
{
    if (modalTaskStatusWindow) {
        modalTaskStatusWindow.indeterminate = YES;
        modalTaskStatusWindow.onCancelBlock = nil;
        [[NSApplication sharedApplication] stopModal];
        [modalTaskStatusWindow.window orderOut:self];
    }
    modalTaskStatusWindow = nil;
}

- (void) modalStatusWindowUpdateStatusText:(NSString*) text
{
    [modalTaskStatusWindow updateStatusText:text];
}


#pragma mark Handling the gui layer

- (void) resizeGUIWindow:(NSSize)size
{
    NSRect frame = guiView.frame;
    frame.size = size;
    guiView.frame = NSMakeRect(0, 0, frame.size.width, frame.size.height);
    
    frame = cocosView.frame;
    frame.origin = [cocosView convertPoint:NSZeroPoint toView:NULL];
    frame.origin.x += self.window.frame.origin.x;
    frame.origin.y += self.window.frame.origin.y;
    
    [guiWindow setFrameOrigin:frame.origin];
    
    
    frame = guiWindow.frame;
    frame.size = size;
    [guiWindow setFrame:frame display:YES];
}

#pragma mark Handling the tab bar

- (void) addTab:(CCBDocument*)doc
{
    NSTabViewItem *newItem = [[NSTabViewItem alloc] initWithIdentifier:doc];
	[newItem setLabel:[doc formattedName]];
	[tabView addTabViewItem:newItem];
    [tabView selectTabViewItem:newItem]; // this is optional, but expected behavior
}

- (void)tabView:(NSTabView*)tv didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] makeFirstResponder:[self window]];
    currentDocument.lastEditedProperty = nil;
    [self switchToDocument:[tabViewItem identifier]];
}

- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([[aTabView tabViewItems] count] == 0)
    {
        [self closeLastDocument];
    }
    
    [self updateDirtyMark];
}


- (BOOL)tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] makeFirstResponder:[self window]];
    currentDocument.lastEditedProperty = nil;
    CCBDocument* doc = [tabViewItem identifier];
    
    if (doc.isDirty)
    {
        NSAlert* alert = [NSAlert alertWithMessageText:
                          [NSString stringWithFormat: @"Do you want to save the changes you made in the document “%@”?",
                           [doc.filePath lastPathComponent]]
                                         defaultButton:@"Save"
                                       alternateButton:@"Cancel"
                                           otherButton:@"Don’t Save"
                             informativeTextWithFormat:@"Your changes will be lost if you don’t save them."];
        
        NSInteger result = [alert runModal];
        
        if (result == NSAlertDefaultReturn)
        {
            [self saveDocument:self];
            return YES;
        }
        else if (result == NSAlertAlternateReturn)
        {
            return NO;
        }
        else if (result == NSAlertOtherReturn)
        {
            [currentDocument removeBackup];
            return YES;
        }
    }
    [currentDocument removeBackup];
    return YES;
}

- (BOOL)tabView:(NSTabView *)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)tabBarControl
{
    return YES;
}

- (NSString *)tabView:(NSTabView *)aTabView toolTipForTabViewItem:(NSTabViewItem *)tabViewItem
{
    CCBDocument *doc = [tabViewItem identifier];
    return [doc.filePath relativePathFromBaseDirPath:[self.projectSettings.projectPath stringByDeletingLastPathComponent]];
}

#pragma mark Handling selections

- (BOOL) nodeHasCCBFileAncestor:(CCNode*)node
{
    while (node.parent != NULL)
    {
        if ([NSStringFromClass(node.parent.class) isEqualToString:@"CCBPCCBFile"])
        {
            return YES;
        }
        node = node.parent;
    }
    return NO;
}

- (void) setSelectedNodes:(NSArray*) selection
{
	
	//Ensure that the selected joint is on top.
	CCBPhysicsJoint* selectedJoint = [selection findFirst:^BOOL(CCNode * node, int idx) {
		return node.plugIn.isJoint;
	}];
	
	if(selectedJoint)
	{
		[[SceneGraph instance].joints.all forEach:^(CCNode * joint, int idx) {
			joint.zOrder = (joint == selectedJoint) ? 1 : 0;
		}];
		
		selection = [NSArray arrayWithObject:selectedJoint];
	}
	
	

	
    [self willChangeValueForKey:@"selectedNode"];
    [self willChangeValueForKey:@"selectedNodes"];
    [physicsHandler willChangeSelection];
    
    // Close the color picker
    [[NSColorPanel sharedColorPanel] close];
    
    if([[self window] firstResponder] != sequenceHandler.outlineHierarchy)
    {
        // Finish editing inspector
        if (![[self window] makeFirstResponder:[self window]])
        {
            return;
        }
    }
    
    
    // Remove any nodes that are part of sub ccb-files OR any nodes that are Locked.
    NSMutableArray* mutableSelection = [NSMutableArray arrayWithArray: selection];
    for (int i = mutableSelection.count -1; i >= 0; i--)
    {
        CCNode* node = [mutableSelection objectAtIndex:i];
        if ([self nodeHasCCBFileAncestor:node])
        {
            [mutableSelection removeObjectAtIndex:i];
        }
    }
    
    // Update selection
    [selectedNodes removeAllObjects];
    if (mutableSelection && mutableSelection.count > 0)
    {
        [selectedNodes addObjectsFromArray:mutableSelection];
        
        // Make sure all nodes have the same parent
        CCNode* lastNode = [selectedNodes objectAtIndex:selectedNodes.count-1];
        CCNode* parent = lastNode.parent;
        
        for (int i = selectedNodes.count -1; i >= 0; i--)
        {
            CCNode* node = [selectedNodes objectAtIndex:i];
            
            if (node.parent != parent)
            {
                [selectedNodes removeObjectAtIndex:i];
            }
        }
    }
    
    [sequenceHandler updateOutlineViewSelection];
    
    // Handle undo/redo
    if (currentDocument) currentDocument.lastEditedProperty = NULL;
    
    [self updateSmallTabBarsEnabled];
    [_propertyInspectorTemplateHandler updateTemplates];
    
    [self didChangeValueForKey:@"selectedNode"];
    [self didChangeValueForKey:@"selectedNodes"];
    
    physicsHandler.selectedNodePhysicsBody = self.selectedNode.nodePhysicsBody;
    [physicsHandler didChangeSelection];

    [animationPlaybackManager stop];
}

- (CCNode*) selectedNode
{
    if (selectedNodes.count == 1)
    {
        return [selectedNodes objectAtIndex:0];
    }
    else
    {
        return NULL;
    }
}

- (void)deselectAll
{
    self.selectedNodes = nil;
}

-(BOOL)selectedNodeCanHavePhysics
{
    if(!self.selectedNode)
        return NO;
    
    if(self.selectedNode.plugIn.isJoint)
        return NO;
    
    return YES;
}

#pragma mark Window Delegate

- (void) windowDidResignMain:(NSNotification *)notification
{
    if (notification.object == self.window)
    {
        CocosScene* cs = [CocosScene cocosScene];
    
        if (![[CCDirector sharedDirector] isPaused])
        {
            [[CCDirector sharedDirector] pause];
            cs.paused = YES;
        }
    }
}

- (void) windowDidBecomeMain:(NSNotification *)notification
{
    if (notification.object == self.window)
    {
        CocosScene* cs = [CocosScene cocosScene];
    
        if ([[CCDirector sharedDirector] isPaused])
        {
            [[CCDirector sharedDirector] resume];
            cs.paused = NO;
        }
    }
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    if (notification.object == guiWindow)
    {
        [guiView setSubviews:[NSArray array]];
        [[CocosScene cocosScene].notesLayer showAllNotesLabels];
    }
}

- (void) windowDidResize:(NSNotification *)notification
{
    [sequenceHandler updateScroller];
}


#pragma mark Populating menus

- (void) updateResolutionMenu
{
    if (!currentDocument) return;
    
    // Clear the menu
    [menuResolution removeAllItems];
    
    // Add all new resolutions
    int i = 0;
    for (ResolutionSetting* resolution in currentDocument.resolutions)
    {
        NSString* keyEquivalent = @"";
        if (i < 9)
            keyEquivalent = [NSString stringWithFormat:@"%d",i+1];
        else if(i < 18)
            keyEquivalent = [NSString stringWithFormat:@"%d",i-8];
        
        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:resolution.name action:@selector(menuResolution:) keyEquivalent:keyEquivalent];
        if(i > 8 && i<18)
            item.keyEquivalentModifierMask = NSEventModifierFlagOption;
        item.target = self;
        item.tag = i;
        
        [menuResolution addItem:item];
        if (i == currentDocument.currentResolution) item.state = NSOnState;
        
        i++;
    }
    ResolutionSetting *res = [currentDocument.resolutions objectAtIndex:currentDocument.currentResolution];
    selectedDevice.stringValue = [NSString stringWithFormat:@"%@ (%dx%d)",res.name, res.width,res.height];
}

- (void) updateTimelineMenu
{
    if (!currentDocument)
    {
        lblTimeline.stringValue = @"";
        lblTimelineChained.stringValue = @"";
        [menuTimelinePopup setEnabled:NO];
        [menuTimelineChainedPopup setEnabled:NO];
        return;
    }
    
    [menuTimelinePopup setEnabled:YES];
    [menuTimelineChainedPopup setEnabled:YES];
    
    // Clear menu
    [menuTimeline removeAllItems];
    [menuTimelineChained removeAllItems];
    
    int currentId = sequenceHandler.currentSequence.sequenceId;
    int chainedId = sequenceHandler.currentSequence.chainedSequenceId;
    
    // Add dummy item
    NSMenuItem* itemDummy = [[NSMenuItem alloc] initWithTitle:@"Dummy" action:NULL keyEquivalent:@""];
    [menuTimelineChained addItem:itemDummy];
    
    // Add empty option for chained seq
    NSMenuItem* itemCh = [[NSMenuItem alloc] initWithTitle: @"No Chained Timeline" action:@selector(menuSetChainedSequence:) keyEquivalent:@""];
    itemCh.target = sequenceHandler;
    itemCh.tag = -1;
    if (chainedId == -1) [itemCh setState:NSOnState];
    [menuTimelineChained addItem:itemCh];
    
    // Add separator item
    [menuTimelineChained addItem:[NSMenuItem separatorItem]];
    
    for (SequencerSequence* seq in currentDocument.sequences)
    {
        // Add to sequence selector
        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:seq.name action:@selector(menuSetSequence:) keyEquivalent:@""];
        item.target = sequenceHandler;
        item.tag = seq.sequenceId;
        if (currentId == seq.sequenceId) [item setState:NSOnState];
        [menuTimeline addItem:item];
        
        // Add to chained sequence selector
        itemCh = [[NSMenuItem alloc] initWithTitle: seq.name action:@selector(menuSetChainedSequence:) keyEquivalent:@""];
        itemCh.target = sequenceHandler;
        itemCh.tag = seq.sequenceId;
        if (chainedId == seq.sequenceId) [itemCh setState:NSOnState];
        [menuTimelineChained addItem:itemCh];
    }
    
    if (sequenceHandler.currentSequence) lblTimeline.stringValue = sequenceHandler.currentSequence.name;
    if (chainedId == -1)
    {
        lblTimelineChained.stringValue = @"No chained timeline";
    }
    else
    {
        for (SequencerSequence* seq in currentDocument.sequences)
        {
            if (seq.sequenceId == chainedId)
            {
                lblTimelineChained.stringValue = seq.name;
                break;
            }
        }
    }

    [animationPlaybackManager stop];
}

#pragma mark Document handling

- (BOOL) hasDirtyDocument
{
    NSArray* docs = [tabView tabViewItems];
    for (int i = 0; i < [docs count]; i++)
    {
        CCBDocument* doc = [(NSTabViewItem*)[docs objectAtIndex:i] identifier];
        if (doc.isDirty) return YES;
    }
    if ([[NSDocumentController sharedDocumentController] hasEditedDocuments])
    {
        return YES;
    }
    return NO;
}

- (void) updateDirtyMark
{
    [window setDocumentEdited:[self hasDirtyDocument]];
}

+ (void) findNodesByUUIDs:(NSArray*)UUIDs startFrom:(CCNode*)startNode result:(NSMutableArray*)result
{
    for(NSNumber* UUID in UUIDs)
    {
        if(startNode.UUID == [UUID unsignedIntegerValue])
        {
            [result addObject:startNode];
            break;
        }
    }
    if (![NSStringFromClass(startNode.class) isEqualToString:@"CCBPCCBFile"])
    {
        for(CCNode *child in startNode.children)
        {
            [self findNodesByUUIDs:UUIDs startFrom:child result:result];
        }
    }
}

typedef id (^GetNodeParamBlock)(CCNode*);
typedef void (^SetNodeParamBlock)(CCNode*, id);

+ (void) getNodesParams:(NSDictionary*) paramsFunction startFrom:(CCNode*)startNode result:(NSMutableDictionary*)result
{
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [paramsFunction enumerateKeysAndObjectsUsingBlock:^(NSString* key, id value, BOOL* stop) {
        id res = ((GetNodeParamBlock)value)(startNode);
        if(res)
            data[key] = res;
    }];
    if(data.count)
        [result setObject:data forKey:[[NSNumber numberWithUnsignedInteger:startNode.UUID] stringValue]];
    
    if (![NSStringFromClass(startNode.class) isEqualToString:@"CCBPCCBFile"])
        for(CCNode *child in startNode.children)
            [AppDelegate getNodesParams:paramsFunction startFrom:child result:result];
}

+ (void) applyNodesParams:(NSDictionary*) paramsFunction startFrom:(CCNode*)startNode params:(NSDictionary*)params
{
    [params enumerateKeysAndObjectsUsingBlock:^(NSNumber* UUID, NSDictionary *nodeParams, BOOL* stop) {
        if([UUID integerValue] == startNode.UUID)
        {
            [nodeParams enumerateKeysAndObjectsUsingBlock:^(NSString* key, id value, BOOL* stop) {
                id func = [paramsFunction objectForKey:key];
                if(func)
                    ((SetNodeParamBlock)func)(startNode, value);
            }];
        }
    }];
    
    if (![NSStringFromClass(startNode.class) isEqualToString:@"CCBPCCBFile"])
        for(CCNode *child in startNode.children)
            [AppDelegate applyNodesParams:paramsFunction startFrom:child params:params];
}

- (NSMutableDictionary*) docDataFromCurrentNodeGraph
{
    CCBDocumentDataCreator *dataCreator =
            [[CCBDocumentDataCreator alloc] initWithSceneGraph:[SceneGraph instance]
                                                      document:currentDocument
                                               projectSettings:projectSettings
                                                    sequenceId:sequenceHandler.currentSequence.sequenceId];
    return [dataCreator createData];
}

- (NSMutableDictionary*) extraDocDataFromCurrentNodeGraph
{
    NSMutableDictionary *extraData = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *lastSelectedNodesUUID = [[NSMutableArray alloc] init];
    for(CCNode *node in self.selectedNodes)
        [lastSelectedNodesUUID addObject:[NSNumber numberWithUnsignedInteger:node.UUID]];
    
    extraData[@"selectedNodes"] = lastSelectedNodesUUID;
    
    NSMutableDictionary *nodesParams = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *paramsFunctions = [[NSMutableDictionary alloc] init];
    
    paramsFunctions[@"expanded"] = ^id(CCNode* node) {
        if([[node extraPropForKey:@"isExpanded"] boolValue])
            return [NSNumber numberWithBool:YES];
        else
            return nil;
    };
    
    [AppDelegate getNodesParams:paramsFunctions startFrom:[SceneGraph instance].rootNode result:nodesParams];
    
    extraData[@"nodesParams"] = nodesParams;
    
    [extraData setObject:@(currentDocument.currentResolution) forKey:@"currentResolution"];
    [extraData setObject:[NSNumber numberWithInt:[[CocosScene cocosScene] stageBorder]] forKey:@"stageBorder"];
    [extraData setObject:[NSNumber numberWithInt:currentDocument.stageColor] forKey:@"stageColor"];
    [extraData setObject:@(sequenceHandler.currentSequence.sequenceId) forKey:@"currentSequenceId"];

    self.currentDocument.stageZooms = self.currentDocument.stageZooms ? self.currentDocument.stageZooms : [NSMutableDictionary dictionary];
    self.currentDocument.stageScrollOffsets = self.currentDocument.stageScrollOffsets ? self.currentDocument.stageScrollOffsets : [NSMutableDictionary dictionary];
    [extraData setObject:self.currentDocument.stageZooms forKey:@"stageZooms"];
    [extraData setObject:self.currentDocument.stageScrollOffsets forKey:@"stageScrollOffsets"];
    
    return extraData;
}

- (void) prepareForDocumentSwitch
{
    [self.window makeKeyWindow];
		
    if (![self hasOpenedDocument]) return;
    currentDocument.data = [self docDataFromCurrentNodeGraph];
    currentDocument.extraData = [self extraDocDataFromCurrentNodeGraph];

}

- (NSMutableArray*) updateResolutions:(NSMutableArray*) resolutions forDocDimensionType:(int) type
{
    NSMutableArray* updatedResolutions = [NSMutableArray array];
    
    if (type == kCCBDocDimensionsTypeNode)
    {
        [updatedResolutions addObject:[ResolutionSetting settingPhone]];
        [updatedResolutions addObject:[ResolutionSetting settingPhoneHd]];
        [updatedResolutions addObject:[ResolutionSetting settingTabletHd]];
    }
    else if (type == kCCBDocDimensionsTypeLayer)
    {
        [updatedResolutions addObject:[ResolutionSetting settingPhone]];
        [updatedResolutions addObject:[ResolutionSetting settingPhoneHd]];
        [updatedResolutions addObject:[ResolutionSetting settingTabletHd]];
    }
    else if (type == kCCBDocDimensionsTypeFullScreen)
    {
        if (projectSettings.defaultOrientation == kCCBOrientationLandscape || projectSettings.defaultOrientation == kCCBOrientationUniversal)
        {
            // Full screen landscape
            [updatedResolutions addObject:[ResolutionSetting setting_iPhone5Landscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPhone6Landscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPhone6PlusLandscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPhoneXLandscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPadLandscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPadRetinaLandscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPadPro10Landscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPadPro12Landscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_Android1280x720Landscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_Android960x540Landscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_Android800x480Landscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_Android1024x600Landscape]];
            [updatedResolutions addObject:[ResolutionSetting setting_Android1280x800Landscape]];
        }
        if (projectSettings.defaultOrientation == kCCBOrientationPortrait || projectSettings.defaultOrientation == kCCBOrientationUniversal)
        {
            // Full screen portrait
            [updatedResolutions addObject:[ResolutionSetting setting_iPhone5Portrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPhone6Portrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPhone6PlusPortrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPhoneXPortrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPadPortrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPadRetinaPortrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPadPro10Portrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_iPadPro12Portrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_Android1280x720Portrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_Android854x480Portrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_Android960x540Portrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_Android800x480Portrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_Android1024x600Portrait]];
            [updatedResolutions addObject:[ResolutionSetting setting_Android1280x800Portrait]];
        }
    }
    
    return updatedResolutions;
}

- (void) replaceDocumentData:(NSMutableDictionary*)doc extraData:(NSMutableDictionary*)extraData
{
//    SceneGraph* g = [SceneGraph instance];
    
    [loadedSelectedNodes removeAllObjects];
    
    BOOL centered = [[doc objectForKey:@"centeredOrigin"] boolValue];
    
    // Check for jsControlled
    jsControlled = [[doc objectForKey:@"jsControlled"] boolValue];
    
    int docDimType = [[doc objectForKey:@"docDimensionsType"] intValue];
    //if (docDimType == kCCBDocDimensionsTypeNode) centered = YES;
    //else centered = NO;
    
    if(docDimType > kCCBDocDimensionsTypeLayer)
        docDimType = kCCBDocDimensionsTypeFullScreen;
    
    if (docDimType == kCCBDocDimensionsTypeLayer || docDimType == kCCBDocDimensionsTypeNode) self.canEditStageSize = YES;
    else self.canEditStageSize = NO;
    
    if (docDimType == kCCBDocDimensionsTypeFullScreen)
        self.canEditResolutions = YES;
    else
        self.canEditResolutions = NO;
    
    // Setup stage & resolutions
    NSMutableArray* serializedResolutions = [doc objectForKey:@"resolutions"];
    if (serializedResolutions)
    {
        NSMutableArray* resolutions = [NSMutableArray array];
        /*if((docDimType == kCCBDocDimensionsTypeNode) || (docDimType == kCCBDocDimensionsTypeLayer))
             resolutions = [self updateResolutions:resolutions forDocDimensionType:docDimType];
        else*/
        {
            // Load resolutions
            for (id serRes in serializedResolutions)
            {
                ResolutionSetting* resolution = [[ResolutionSetting alloc] initWithSerialization:serRes];
                [resolutions addObject:resolution];
            }
        }
        
        // Save in current document
        currentDocument.resolutions = resolutions;
        currentDocument.docDimensionsType = docDimType;
        id currentResolutionObject = [extraData objectForKey:@"currentResolution"];
        
        //try to load old format
        if(!currentResolutionObject)
            currentResolutionObject = [doc objectForKey:@"currentResolution"];
        
        if(currentResolutionObject)
        {
            int currentResolution = [currentResolutionObject intValue];
            currentResolution = clampf(currentResolution, 0, resolutions.count - 1);
            currentDocument.currentResolution = currentResolution;
        }
        else
        {
            currentDocument.currentResolution = 1;
        }
        
        ResolutionSetting* resolution = [resolutions objectAtIndex:currentDocument.currentResolution];
        
        if (![doc objectForKey:@"sceneScaleType"]) {
            currentDocument.sceneScaleType = kCCBSceneScaleTypeDEFAULT;
        } else {
            currentDocument.sceneScaleType = [[doc objectForKey:@"sceneScaleType"] intValue];
        }
        [self updatePositionScaleFactor];
        
        // Update CocosScene
        [[CocosScene cocosScene] setStageSize:CGSizeMake(resolution.width / resolution.resourceScale, resolution.height / resolution.resourceScale) centeredOrigin: centered];
        
    }
    else
    {
        // Support old files where the current width and height was stored
        int stageW = [[doc objectForKey:@"stageWidth"] intValue];
        int stageH = [[doc objectForKey:@"stageHeight"] intValue];
        
        [[CocosScene cocosScene] setStageSize:CGSizeMake(stageW, stageH) centeredOrigin:centered];
        
        // Setup a basic resolution and attach it to the current document
        ResolutionSetting* resolution = [[ResolutionSetting alloc] init];
        resolution.width = stageW;
        resolution.height = stageH;
        resolution.centeredOrigin = centered;
        
        NSMutableArray* resolutions = [NSMutableArray arrayWithObject:resolution];
        currentDocument.resolutions = resolutions;
        currentDocument.currentResolution = 0;
    }
    [self updateResolutionMenu];
    
    ResolutionSetting* resolution = [currentDocument.resolutions objectAtIndex:currentDocument.currentResolution];
    
    // Stage border
    id stageBorderObject = [extraData objectForKey:@"stageBorder"];
    
    //try to load old format
    if(!stageBorderObject)
        stageBorderObject = [doc objectForKey:@"stageBorder"];
    
    if(stageBorderObject)
    {
        [[CocosScene cocosScene] setStageBorder:[stageBorderObject intValue]];
    }
    
    // Stage color
    NSNumber *stageColorObject = [extraData objectForKey: @"stageColor"];
    
    //try to load old format
    if(!stageColorObject)
        stageColorObject = [doc objectForKey: @"stageColor"];
    
    int stageColor;
    if (stageColorObject != nil)
    {
        stageColor = [stageColorObject intValue];
    }
    else
    {
        if (currentDocument.docDimensionsType == kCCBDocDimensionsTypeNode)
        {
            stageColor = kCCBCanvasColorLightGray;
        }
        else
        {
            stageColor = kCCBCanvasColorBlack;
        }
    }
    currentDocument.stageColor = stageColor;
    [self updateStageColor];
    [self updateBgColor];
    [self updateMainStageColor];
    [menuItemStageColor setEnabled: currentDocument.docDimensionsType != kCCBDocDimensionsTypeFullScreen];

    // Setup sequencer timelines
    NSMutableArray* serializedSequences = [doc objectForKey:@"sequences"];
    if (serializedSequences)
    {
        // Load from the file
        id currentSequenceIdObject = [extraData objectForKey:@"currentSequenceId"];
        
        //try to load old format
        if(!currentSequenceIdObject)
            currentSequenceIdObject = [doc objectForKey:@"currentSequenceId"];
        
        int currentSequenceId = [currentSequenceIdObject intValue];
        SequencerSequence* currentSeq = NULL;
        
        NSMutableArray* sequences = [NSMutableArray array];
        for (id serSeq in serializedSequences)
        {
            SequencerSequence* seq = [[SequencerSequence alloc] initWithSerialization:serSeq];
            [sequences addObject:seq];
            
            if (seq.sequenceId == currentSequenceId)
            {
                currentSeq = seq;
            }
        }
        
        currentDocument.sequences = sequences;
        sequenceHandler.currentSequence = currentSeq;
    }
    else
    {
        // Setup a default timeline
        NSMutableArray* sequences = [NSMutableArray array];
    
        SequencerSequence* seq = [[SequencerSequence alloc] init];
        seq.name = @"Default Timeline";
        seq.sequenceId = 0;
        seq.autoPlay = YES;
        [sequences addObject:seq];
    
        currentDocument.sequences = sequences;
        sequenceHandler.currentSequence = seq;
    }
    
    // Process contents
    CCNode* loadedRoot = [CCBReaderInternal nodeGraphFromDocumentDictionary:doc parentSize:CGSizeMake(resolution.width, resolution.height)];
    
    NSMutableArray* loadedJoints = [NSMutableArray array];
    if(doc[@"joints"] != nil)
    {
        for (NSDictionary * jointDict in doc[@"joints"])
        {
            CCNode * joint = [CCBReaderInternal nodeGraphFromDictionary:jointDict parentSize:CGSizeMake(resolution.width, resolution.height) withParentGraph:loadedRoot fileVersion:kCCBFileFormatVersion];
            
            if(joint)
            {
                [loadedJoints addObject:joint];
            }
        }
    }
    
    // Replace open document
    [self deselectAll];
    
    SceneGraph * g = [SceneGraph setInstance:[[SceneGraph alloc] initWithProjectSettings:projectSettings]];
    [g.joints deserialize:doc[@"SequencerJoints"]];
    g.rootNode = loadedRoot;
    
    [loadedJoints forEach:^(CCBPhysicsJoint * child, int idx) {
        [g.joints addJoint:child];
    }];

	[CCBReaderInternal postDeserializationFixup:g.rootNode];

    
    [[CocosScene cocosScene] replaceSceneNodes:g];
    [outlineHierarchy reloadData];
    [sequenceHandler updateOutlineViewSelection];
    [_inspectorController updateInspectorFromSelection];
    
    [sequenceHandler updateExpandedForNode:g.rootNode];
    [sequenceHandler.outlineHierarchy expandItem:g.joints];
    
    // Setup guides
    id guides = [doc objectForKey:@"guides"];
    if (guides)
    {
        [[CocosScene cocosScene].guideLayer loadSerializedGuides:guides];
    }
    else
    {
        [[CocosScene cocosScene].guideLayer removeAllGuides];
    }
    
    // Setup notes
    id notes = [doc objectForKey:@"notes"];
    if (notes)
    {
        [[CocosScene cocosScene].notesLayer loadSerializedNotes:notes];
    }
    else
    {
        [[CocosScene cocosScene].notesLayer removeAllNotes];
    }
    
    // Restore Grid Spacing
    id gridspaceWidth  = [doc objectForKey:@"gridspaceWidth"];
    id gridspaceHeight = [doc objectForKey:@"gridspaceHeight"];
    if (gridspaceWidth && gridspaceHeight) {
        CGSize gridspace = CGSizeMake([gridspaceWidth intValue],[gridspaceHeight intValue]);
        [[CocosScene cocosScene].guideLayer setGridSize:gridspace];
    }
    
    id gridOffsetWidth  = [doc objectForKey:@"gridOffsetWidth"];
    id gridOffsetHeight = [doc objectForKey:@"gridOffsetHeight"];
    if (gridOffsetWidth && gridOffsetHeight) {
        CGPoint gridOffset = ccp([gridOffsetWidth intValue],[gridOffsetHeight intValue]);
        [[CocosScene cocosScene].guideLayer setGridOffset:gridOffset];
    }

    // Restore selections
    self.selectedNodes = loadedSelectedNodes;
    
    NSArray *lastSelectedNodesUUID = [extraData objectForKey:@"selectedNodes"];
    if(lastSelectedNodesUUID && lastSelectedNodesUUID.count)
    {
        NSMutableArray *lastSelectedNodes = [[NSMutableArray alloc] init];
        SceneGraph* g = [SceneGraph instance];
        [AppDelegate findNodesByUUIDs:lastSelectedNodesUUID startFrom:g.rootNode result:lastSelectedNodes];
        [self setSelectedNodes:lastSelectedNodes];
    }
    
    
    NSMutableDictionary *nodesParams = [extraData objectForKey:@"nodesParams"];
    if(nodesParams)
    {
        NSMutableDictionary *paramsFunctions = [[NSMutableDictionary alloc] init];
        paramsFunctions[@"expanded"] = ^void(CCNode* node, id value) {
            if([value boolValue])
            {
                [sequenceHandler.outlineHierarchy expandItem:node];
            }
        };
        
        [AppDelegate applyNodesParams:paramsFunctions startFrom:[SceneGraph instance].rootNode params:nodesParams];
    }
    
    //[self updateJSControlledMenu];
    [self updateCanvasBorderMenu];
    
    self.currentDocument.stageZooms = [extraData objectForKey:@"stageZooms"] ?
                                        [extraData objectForKey:@"stageZooms"] : [NSMutableDictionary dictionary];
    
    self.currentDocument.stageScrollOffsets = [extraData objectForKey:@"stageScrollOffsets"] ?
                                                [extraData objectForKey:@"stageScrollOffsets"]:[NSMutableDictionary dictionary];
        
}

-(void) recalculateSceneScale:(CCBDocument *) doc {
    
    if(doc.docDimensionsType == kCCBDocDimensionsTypeFullScreen)
    {
        if (doc.sceneScaleType > kCCBSceneScaleTypeCUSTOM) {
            [self recallcScalesForScaleType:doc.sceneScaleType forDocument:doc];
        } else
        if (doc.sceneScaleType == kCCBSceneScaleTypeDEFAULT) {
            [self recallcScalesForScaleType:projectSettings.sceneScaleType forDocument:doc];
        }
    }
}

- (void)recallcScalesForScaleType:(CCBSceneScaleType) scaleType forDocument:(CCBDocument *) doc {
    for (ResolutionSetting* resolution in doc.resolutions) {
        [ResolutionSettingsWindow recallcScale:resolution
                              designResolution:CGSizeMake([AppDelegate appDelegate].projectSettings.designSizeWidth,
                                                          [AppDelegate appDelegate].projectSettings.designSizeHeight)
                                designResScale:[AppDelegate appDelegate].projectSettings.designResourceScale
                                     scaleType:scaleType];
    }
}


- (void) switchToDocument:(CCBDocument*) document forceReload:(BOOL)forceReload
{
    if (!forceReload && [document.filePath isEqualToString:currentDocument.filePath]) return;

    [animationPlaybackManager stop];

    [self prepareForDocumentSwitch];
    
    self.currentDocument = document;
    
    [self replaceDocumentData:document.data extraData:document.extraData];
    [self recalculateSceneScale:document];
    [self updateResolutionMenu];
    [self updateTimelineMenu];
    //[self updateStateOriginCenteredMenu];
    
    NSString *zoomKey = [NSString stringWithFormat:@"zoom_%d",self.currentDocument.currentResolution];
    float zoomValue = [self.currentDocument.stageZooms valueForKey:zoomKey] ? [[self.currentDocument.stageZooms valueForKey:zoomKey] floatValue] : 0.44;
    [[CocosScene cocosScene] setStageZoom:zoomValue];
    
    NSString *offsetKeyX = [NSString stringWithFormat:@"offset_x_%d",self.currentDocument.currentResolution];
    NSString *offsetKeyY = [NSString stringWithFormat:@"offset_y_%d",self.currentDocument.currentResolution];
    CGPoint offsetValue = CGPointMake([[self.currentDocument.stageScrollOffsets valueForKey:offsetKeyX] floatValue],
                                      [[self.currentDocument.stageScrollOffsets valueForKey:offsetKeyY] floatValue]);
    [[CocosScene cocosScene] setScrollOffset: offsetValue];
    
    
    // Make sure timeline is up to date
    [sequenceHandler updatePropertiesToTimelinePosition];
}

-(void)fixupUUID:(CCBDocument*)doc dict:(NSMutableDictionary*)dict
{
    if(!dict[@"UUID"])
    {
        dict[@"UUID"] = @(doc.UUID);
        [doc getAndIncrementUUID];
    }
    
    if(dict[@"children"])
    {
        for (NSMutableDictionary * child in dict[@"children"])
        {
            [self fixupUUID:doc dict:child];
        }
        
    }
}


-(void)fixupDoc:(CCBDocument*) doc
{
    //If UUID is unset, it means the doc is out of date. Fixup.
    if(doc.UUID == 0x0)
    {
        doc.UUID = 0x1;
        [self fixupUUID:doc dict: doc.data[@"nodeGraph"]];

    }
}

- (void) switchToDocument:(CCBDocument*) document
{
    [self switchToDocument:document forceReload:NO];
}

- (void) addDocument:(CCBDocument*) doc
{
    [self addTab:doc];
}

- (void) closeLastDocument
{
    [self deselectAll];
    
    SceneGraph * g = [SceneGraph setInstance:[[SceneGraph alloc] initWithProjectSettings:projectSettings]];
    [[CocosScene cocosScene] replaceSceneNodes: g];
    [[CocosScene cocosScene] setStageSize:CGSizeMake(0, 0) centeredOrigin:YES];
    [[CocosScene cocosScene].guideLayer removeAllGuides];
    [[CocosScene cocosScene].notesLayer removeAllNotes];
    [[CocosScene cocosScene].rulerLayer mouseExited:NULL];
    [self setupExtras]; // Reset
    self.currentDocument = NULL;
    sequenceHandler.currentSequence = NULL;
    
    [self updateTimelineMenu];
    [outlineHierarchy reloadData];
    
    //[resManagerPanel.window setIsVisible:NO];
    
    self.hasOpenedDocument = NO;
    selectedDevice.stringValue = @"";
}

- (CCBDocument*) findDocumentFromFile:(NSString*)file
{
    NSArray* items = [tabView tabViewItems];
    for (int i = 0; i < [items count]; i++)
    {
        CCBDocument* doc = [(NSTabViewItem*)[items objectAtIndex:i] identifier];
        if ([doc.filePath isEqualToString:file]) return doc;
    }
    return NULL;
}

- (NSTabViewItem*) tabViewItemFromDoc:(CCBDocument*)docRef
{
    NSArray* items = [tabView tabViewItems];
    for (int i = 0; i < [items count]; i++)
    {
        CCBDocument* doc = [(NSTabViewItem*)[items objectAtIndex:i] identifier];
        if (doc == docRef) return [items objectAtIndex:i];
    }
    return NULL;
}

// A path can be a folder not only a file. Set includeViewWithinFolderPath to YES to return
// the first view that is within a given folder path
- (NSTabViewItem *)tabViewItemFromPath:(NSString *)path includeViewWithinFolderPath:(BOOL)includeViewWithinFolderPath
{
	NSArray *items = [tabView tabViewItems];
	for (NSUInteger i = 0; i < [items count]; i++)
	{
		CCBDocument *doc = [(NSTabViewItem *) [items objectAtIndex:i] identifier];
		if ([doc.filePath isEqualToString:path]
			|| (includeViewWithinFolderPath && [doc isWithinPath:path]))
		{
			return [items objectAtIndex:i];
		}
	}
	return NULL;
}

- (void) checkForTooManyDirectoriesInCurrentDoc
{
    if (!currentDocument) return;
    
    if ([ResourceManager sharedManager].tooManyDirectoriesAdded)
    {
        // Close document if it has too many sub directories
        NSTabViewItem* item = [self tabViewItemFromDoc:currentDocument];
        [tabView removeTabViewItem:item];
        
        [ResourceManager sharedManager].tooManyDirectoriesAdded = NO;
        
        // Notify the user
        [[AppDelegate appDelegate] modalDialogTitle:@"Too Many Directories" message:@"You have created or opened a file which is in a directory with very many sub directories. Please save your ccb-files in a directory together with the resources you use in your project."];
    }
}

- (BOOL) checkForTooManyDirectoriesInCurrentProject
{
    if (!projectSettings) return NO;
    
    if ([ResourceManager sharedManager].tooManyDirectoriesAdded)
    {
        [self closeProject];
        
        [ResourceManager sharedManager].tooManyDirectoriesAdded = NO;
        
        // Notify the user
        [[AppDelegate appDelegate] modalDialogTitle:@"Too Many Directories" message:@"You have created or opened a project which is in a directory with very many sub directories. Please save your project-files in a directory together with the resources you use in your project."];
        return NO;
    }
    return YES;
}

- (void) updateResourcePathsFromProjectSettings
{
    [[ResourceManager sharedManager] setActiveDirectoriesWithFullReset:[projectSettings absoluteResourcePaths]];
}

- (void) closeProject
{
    [self saveOpenedDocumentsForProject];
    while ([tabView numberOfTabViewItems] > 0)
    {
        NSTabViewItem* item = [self tabViewItemFromDoc:currentDocument];
        if (!item) return;
        
        if ([self tabView:tabView shouldCloseTabViewItem:item])
        {
            [tabView removeTabViewItem:item];
        }
        else
        {
            // Aborted close project
            return;
        }
    }
    
    [window setTitle:@"SpriteBuilder"];
    
    [self.projectSettings store];

    // Remove resource paths
    self.projectSettings = NULL;
    [ResourceManager sharedManager].projectSettings = NULL;
    [[ResourceManager sharedManager] removeAllDirectories];
    
    // Remove language file
    localizationEditorHandler.managedFile = NULL;
    
    [self updateWarningsButton];
    [self updateSmallTabBarsEnabled];
    
    self.window.representedFilename = @"";
    self.openedProjectFileName = nil;
}

- (BOOL) openProject:(NSString*) fileName
{
    if (![fileName hasSuffix:@".spritebuilder"] && ![fileName hasSuffix:@".ccbproj"])
    {
        return NO;
    }

    [self closeProject];
    
    if ([fileName hasSuffix:@".ccbproj"])
    {
        fileName = [fileName stringByDeletingLastPathComponent];
    }

    // Add to recent list of opened documents
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:fileName]];
    
    // Convert folder to actual project file
    NSString* projName = [[fileName lastPathComponent] stringByDeletingPathExtension];
    fileName = [[fileName stringByAppendingPathComponent:projName] stringByAppendingPathExtension:@"ccbproj"];
    
    self.openedProjectFileName = fileName;
    // Load the project file
    NSMutableDictionary* projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:fileName];
    if (!projectDict)
    {
        [self modalDialogTitle:@"Invalid Project File" message:@"Failed to open the project. File may be missing or invalid."];
        return NO;
    }
    
    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithSerialization:projectDict];
    if (!projectSettings)
    {
        [self modalDialogTitle:@"Invalid Project File" message:@"Failed to open the project. File is invalid or is created with a newer version of SpriteBuilder."];
        return NO;
    }
    projectSettings.projectPath = fileName;
    [projectSettings store];

    // inject new project settings
    self.projectSettings = projectSettings;
    _resourceCommandController.projectSettings = projectSettings;
    projectOutlineHandler.projectSettings = projectSettings;
    [ResourceManager sharedManager].projectSettings = projectSettings;

    // Update resource paths
    [self updateResourcePathsFromProjectSettings];

    // Update Node Plugins list
	[plugInNodeViewHandler showNodePlugins];
	
    BOOL success = [self checkForTooManyDirectoriesInCurrentProject];
    if (!success)
    {
        return NO;
    }

    // Load or create language file
    NSString* langFile = [[ResourceManager sharedManager].mainActiveDirectoryPath stringByAppendingPathComponent:@"Strings.json"];
    localizationEditorHandler.managedFile = langFile;
    
    // Update the title of the main window
    [window setTitle:[NSString stringWithFormat:@"%@ - SpriteBuilderX", [[fileName stringByDeletingLastPathComponent] lastPathComponent]]];
    
    if (SBSettings.restoreOpenedDocuments) {
        // Open last closed documents
        NSMutableArray *openedDocs = [SBSettings.openedDocuments objectForKey:self.openedProjectFileName];
        if (openedDocs.count > 1) {
            //from 1, because 0 it's selected item
            for (int i = 1; i < openedDocs.count; i++) {
                NSString *openedCCB = [openedDocs objectAtIndex:i];
            
            //for (NSString *openedCCB in openedDocs) {
                if ([openedCCB hasSuffix:@".ccb"] && [[NSFileManager defaultManager] fileExistsAtPath:openedCCB]) {
                    [self openFile:openedCCB];
                }
            }
            //and select last active
            NSArray *docsTabs = [tabView tabViewItems];
            for (int i = 0; i < docsTabs.count; i++) {
                CCBDocument *doc = [(NSTabViewItem*) docsTabs[i] identifier];
                if ([doc.filePath isEqualToString:[openedDocs objectAtIndex:0]]) {
                    [tabView selectTabViewItem:docsTabs[i]];
                }
            }
        }
    }
    
    [self updateWarningsButton];
    [self updateSmallTabBarsEnabled];

    self.window.representedFilename = [fileName stringByDeletingLastPathComponent];

    [self.menuPublishPlatform removeAllItems];
    [self addMenuItemIntoPlatformSettings:@"Default"];
    [self addMenuItemIntoPlatformSettings:@"All"];
    for (PlatformSettings *platformSettings in projectSettings.platformsSettings) {
        [self addMenuItemIntoPlatformSettings: platformSettings.name];
    }
    
    return YES;
}

-(void) addMenuItemIntoPlatformSettings:(NSString *) title {
    NSMenuItem *platformMenuItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    [self.menuPublishPlatform addItem:platformMenuItem];
}

- (void) openFile:(NSString*)filePath
{
	[(CCGLView*)[[CCDirector sharedDirector] view] lockOpenGLContext];
    
    // Check if file is already open
    CCBDocument* openDoc = [self findDocumentFromFile:filePath];
    if (openDoc)
    {
        [tabView selectTabViewItem:[self tabViewItemFromDoc:openDoc]];
        return;
    }
    
    [self prepareForDocumentSwitch];
    
    CCBDocument *newDoc = [[CCBDocument alloc] initWithContentsOfFile:filePath andProjectSettings:projectSettings];

    [self switchToDocument:newDoc];
     
    [self addDocument:newDoc];
    self.hasOpenedDocument = YES;
    
    [self checkForTooManyDirectoriesInCurrentDoc];
    
    // Remove selections
    //physicsHandler.selectedNodePhysicsBody = NULL;
    //[self setSelectedNodes:NULL];
    
	[(CCGLView*)[[CCDirector sharedDirector] view] unlockOpenGLContext];
}

- (void) saveFile:(NSString*) fileName
{
    [[self window] makeFirstResponder:[self window]];
    currentDocument.lastEditedProperty = nil;
    currentDocument.data = [self docDataFromCurrentNodeGraph];
    currentDocument.extraData = [self extraDocDataFromCurrentNodeGraph];
    [currentDocument removeBackup];
    currentDocument.filePath = fileName;
    [currentDocument store];
    
    currentDocument.isDirty = NO;
    currentDocument.isBackupDirty = NO;
    NSTabViewItem* item = [self tabViewItemFromDoc:currentDocument];
    
    if (item)
    {
        [tabBar setIsEdited:NO ForTabViewItem:item];
        [self updateDirtyMark];
    }
        
    //[currentDocument.undoManager removeAllActions];
    //currentDocument.lastEditedProperty = NULL;
    
    // Generate preview
    
    // Reset to first frame in first timeline in first resolution
    /*
    float currentTime = sequenceHandler.currentSequence.timelinePosition;
    int currentResolution = currentDocument.currentResolution;
    SequencerSequence* currentSeq = sequenceHandler.currentSequence;
    
    sequenceHandler.currentSequence = [currentDocument.sequences objectAtIndex:0];
    sequenceHandler.currentSequence.timelinePosition = 0;
    [self reloadResources];
    [PositionPropertySetter refreshAllPositions];
    */
    
    // Save preview
    NSString *filePath = [SBSettings miscFilesPathForFile:fileName projectPathDir:self.projectSettings.projectPathDir];
    [[CocosScene cocosScene] savePreviewToFile:[filePath stringByAppendingPathExtension:MISC_FILE_PPNG]];
    
    // Restore resolution and timeline
    /*
    currentDocument.currentResolution = currentResolution;
    sequenceHandler.currentSequence = currentSeq;
    [self reloadResources];
    [PositionPropertySetter refreshAllPositions];
    sequenceHandler.currentSequence.timelinePosition = currentTime;
    */
    
    [projectOutlineHandler updateSelectionPreview];
    
    if ([projectSettings.platformsSettings count] != 0 && SBSettings.autoPublish) {
        [self publishStartAsync:YES silent:YES];
    }
}

- (void) generatePreviewForDirectory:(RMDirectory*) dir
{
    NSArray* arr = [dir resourcesForType:kCCBResTypeCCBFile];
    
    for (id item in arr)
    {
        if ([item isKindOfClass:[RMResource class]])
        {
            @autoreleasepool
            {
                RMResource* res = item;
                
                if (res.type == kCCBResTypeCCBFile)
                {
                    [self openFile:res.filePath];
                    NSString *filePath = [SBSettings miscFilesPathForFile:res.filePath projectPathDir:self.projectSettings.projectPathDir];
                    [[CocosScene cocosScene] savePreviewToFile:[filePath stringByAppendingPathExtension:MISC_FILE_PPNG]];
                    CCBDocument* oldDoc = [self findDocumentFromFile:res.filePath];
                    if (oldDoc)
                    {
                        NSTabViewItem* item = [self tabViewItemFromDoc:oldDoc];
                        if (item) [tabView removeTabViewItem:item];
                    }
                }
                else if (res.type == kCCBResTypeDirectory)
                {
                    RMDirectory* subDir = res.data;
                    [self generatePreviewForDirectory:subDir];
                }
            }
        }
    }

}

- (IBAction) generatePreview:(id)sender
{
    ResourceManager* rm = [ResourceManager sharedManager];
    for(RMDirectory *dir in rm.activeDirectories)
    {
        [self generatePreviewForDirectory:dir];
    }
}

- (void) refreshDirectory:(RMDirectory*) dir
{
    NSArray* arr = [dir resourcesForType:kCCBResTypeCCBFile];
    
    for (id item in arr)
    {
        if ([item isKindOfClass:[RMResource class]])
        {
            @autoreleasepool
            {
                RMResource* res = item;
                
                if (res.type == kCCBResTypeCCBFile)
                {
                    CCBDocument *newDoc = [[CCBDocument alloc] initWithContentsOfFile:res.filePath andProjectSettings:projectSettings];
                    CCNode* loadedRoot = [CCBReaderInternal nodeGraphFromDocumentDictionary:newDoc.data parentSize:CGSizeZero];
                    NSMutableDictionary* nodeGraph = [CCBWriterInternal dictionaryFromCCObject:loadedRoot];
                    [newDoc.data setObject:nodeGraph forKey:@"nodeGraph"];
                    [newDoc store];
                }
                else if (res.type == kCCBResTypeDirectory)
                {
                    RMDirectory* subDir = res.data;
                    [self refreshDirectory:subDir];
                }
            }
        }
    }
    
}

- (IBAction) refreshAllFiles:(id)sender
{
    ResourceManager* rm = [ResourceManager sharedManager];
    for(RMDirectory *dir in rm.activeDirectories)
    {
        [self refreshDirectory:dir];
    }
}

- (IBAction)moveMiscFiles:(id)sender {
    ResourceManager* rm = [ResourceManager sharedManager];
    for(RMDirectory *dir in rm.activeDirectories) {
        [self moveMiscFilesInDirectory:dir];
    }
}

- (void) moveMiscFilesInDirectory:(RMDirectory*) dir {
    NSArray* arr = [dir resourcesForType:kCCBResTypeCCBFile];
    
    for (id item in arr) {
        if ([item isKindOfClass:[RMResource class]]) {
            @autoreleasepool {
                RMResource* res = item;
                if (res.type == kCCBResTypeCCBFile) {
                    CCBDocument *newDoc = [[CCBDocument alloc] initWithContentsOfFile:res.filePath
                                                                   andProjectSettings:projectSettings];
                    [newDoc copyMiscFile];
                }
                else if (res.type == kCCBResTypeDirectory) {
                    RMDirectory* subDir = res.data;
                    [self moveMiscFilesInDirectory:subDir];
                }
            }
        }
    }
}

- (void) newFile:(NSString*) fileName type:(int)type resolutions: (NSMutableArray*) resolutions layerWidth:(float) width layerHeight:(float) height
{
    BOOL centered = NO;
    if (//type == kCCBNewDocTypeNode ||
        type == kCCBNewDocTypeParticleSystem ||
        type == kCCBNewDocTypeSprite) centered = YES;
    
    int docDimType = kCCBDocDimensionsTypeNode;
    if (type == kCCBNewDocTypeScene) docDimType = kCCBDocDimensionsTypeFullScreen;
    else if (type == kCCBNewDocTypeLayout) docDimType = kCCBDocDimensionsTypeNode;
    else if (type == kCCBNewDocTypeLayer) docDimType = kCCBDocDimensionsTypeLayer;
    
    NSString* class = NULL;
    if (type == kCCBNewDocTypeNode ||
        type == kCCBNewDocTypeLayer) class = @"CCNode";
    else if (type == kCCBNewDocTypeScene) class = @"CCNode";
    else if (type == kCCBNewDocTypeSprite) class = @"CCSprite";
    else if (type == kCCBNewDocTypeParticleSystem) class = @"CCParticleSystem";
    else if (type == kCCBNewDocTypeLayout) class = @"CCLayoutBox";
    
    resolutions = [self updateResolutions:resolutions forDocDimensionType:docDimType];
    
    ResolutionSetting* resolution = [resolutions objectAtIndex:0];
    CGSize stageSize = CGSizeMake(resolution.width, resolution.height);
    
    // Close old doc if neccessary
    CCBDocument* oldDoc = [self findDocumentFromFile:fileName];
    if (oldDoc)
    {
        NSTabViewItem* item = [self tabViewItemFromDoc:oldDoc];
        if (item) [tabView removeTabViewItem:item];
    }
    
    [self prepareForDocumentSwitch];
    
    [[CocosScene cocosScene].notesLayer removeAllNotes];
    
    [self deselectAll];
    [[CocosScene cocosScene] setStageSize:stageSize centeredOrigin:centered];
    
    if (type == kCCBNewDocTypeScene)
    {
        [[CocosScene cocosScene] setStageBorder:0];
    }
    else
    {
        [[CocosScene cocosScene] setStageBorder:1];
    }
    
    // Create new node
    SceneGraph * g = [SceneGraph setInstance:[[SceneGraph alloc] initWithProjectSettings:projectSettings]];
    g.rootNode = [[PlugInManager sharedManager] createDefaultNodeOfType:class];
    g.joints.node = [CCNode node];
    [[CocosScene cocosScene] replaceSceneNodes:g];
    
    if (type == kCCBNewDocTypeScene)
    {
        // Set default contentSize to 100% x 100% for scenes
        [PositionPropertySetter setSize:NSMakeSize(1, 1) type:CCSizeTypeNormalized forNode:[CocosScene cocosScene].rootNode prop:@"contentSize"];
    }
    else if (type == kCCBNewDocTypeLayer)
    {
        for(ResolutionSetting* resolution in resolutions)
        {
            resolution.width = width * resolution.resourceScale;
            resolution.height = height * resolution.resourceScale;
        }
        [[CocosScene cocosScene] setStageSize:CGSizeMake(width, height) centeredOrigin:centered];
        // Set contentSize to w x h in scaled coordinates for layers
        [PositionPropertySetter setSize:NSMakeSize(0, 0) type:CCSizeTypePoints forNode:[CocosScene cocosScene].rootNode prop:@"contentSize"];
    }
    else if (type == kCCBNewDocTypeNode)
    {
        for(ResolutionSetting* resolution in resolutions)
        {
            resolution.width = width * resolution.resourceScale;
            resolution.height = height * resolution.resourceScale;
        }
        [[CocosScene cocosScene] setStageSize:CGSizeMake(width, height) centeredOrigin:centered];
        // Set contentSize to w x h in scaled coordinates for layers
        [PositionPropertySetter setSize:NSMakeSize(width, height) type:CCSizeTypeUIPoints forNode:[CocosScene cocosScene].rootNode prop:@"contentSize"];
    }
    [outlineHierarchy reloadData];
    [sequenceHandler updateOutlineViewSelection];
    [_inspectorController updateInspectorFromSelection];
    
    self.currentDocument = [[CCBDocument alloc] init];
    self.currentDocument.resolutions = resolutions;
    self.currentDocument.currentResolution = 1;
    self.currentDocument.docDimensionsType = docDimType;
    self.currentDocument.projectSettings = projectSettings;
    
    if (type == kCCBNewDocTypeNode)
    {
        self.currentDocument.stageColor = kCCBCanvasColorLightGray;
    }
    else
    {
        self.currentDocument.stageColor = kCCBCanvasColorBlack;
    }

    [self updateResolutionMenu];
    
    [self saveFile:fileName];
    
    [self addDocument:currentDocument];
    
    // Setup a default timeline
    NSMutableArray* sequences = [NSMutableArray array];
    
    SequencerSequence* seq = [[SequencerSequence alloc] init];
    seq.name = @"Default Timeline";
    seq.sequenceId = 0;
    seq.autoPlay = YES;
    [sequences addObject:seq];
    
    currentDocument.sequences = sequences;
    sequenceHandler.currentSequence = seq;
    
    
    self.hasOpenedDocument = YES;
    
    //[self updateStateOriginCenteredMenu];
    
    [[CocosScene cocosScene] setStageZoom:0.44];
    [[CocosScene cocosScene] setScrollOffset:ccp(0,0)];
    
    [self checkForTooManyDirectoriesInCurrentDoc];

    [[ResourceManager sharedManager] updateForNewFile:fileName];
}


- (NSString*) findProject:(NSString*) path
{
	NSString* projectFile = nil;
	NSFileManager* fm = [NSFileManager defaultManager];
    
	NSArray* files = [fm contentsOfDirectoryAtPath:path error:NULL];
	for( NSString* file in files )
	{
		if( [file hasSuffix:@".ccbproj"] )
		{
			projectFile = [path stringByAppendingPathComponent:file];
			break;
		}
	}
	return projectFile;
}

- (void)openFiles:(NSArray*)filenames
{
	for( NSString* filename in filenames )
	{
		[self openProject:filename];		
	}
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	// must wait for resource manager & rest of app to have completed the launch process before opening file(s)
	if (_applicationLaunchComplete == NO)
	{
		NSAssert(delayOpenFiles == NULL, @"This shouldn't be set to anything since this value will only get applied once.");
		delayOpenFiles = [[NSMutableArray alloc] initWithArray:filenames];
	}
	else 
	{
		[self openFiles:filenames];
	}
}

- (IBAction)menuResetSpriteBuilder:(id)sender
{
    NSAlert* alert = [NSAlert alertWithMessageText:@"Reset SpriteBuilder" defaultButton:@"Cancel" alternateButton:@"Reset SpriteBuilder" otherButton:NULL informativeTextWithFormat:@"Are you sure you want to reset SpriteBuilder? This action will remove all your custom template and settings and cannot be undone."];
    [alert setAlertStyle:NSWarningAlertStyle];
    NSInteger result = [alert runModal];
    if (result == NSAlertDefaultReturn) return;
    
    [self setSelectedNodes:NULL];
    [self menuCleanCacheDirectories:sender];
    [_propertyInspectorTemplateHandler installDefaultTemplatesReplace:YES];
    [_propertyInspectorTemplateHandler loadTemplateLibrary];
    
    [NSUserDefaults resetStandardUserDefaults];
}

#pragma mark Undo

- (void) revertToState:(id)state
{
    NSMutableArray *lastSelectedNodesUUID = [[NSMutableArray alloc] init];
    for(CCNode *node in self.selectedNodes)
    {
        [lastSelectedNodesUUID addObject:[NSNumber numberWithInteger:node.UUID]];
    }

    [self saveUndoState];
    [self replaceDocumentData:state extraData:[self extraDocDataFromCurrentNodeGraph]];
    [sequenceHandler updatePropertiesToTimelinePosition];
    
    if(lastSelectedNodesUUID.count)
    {
        NSMutableArray *lastSelectedNodes = [[NSMutableArray alloc] init];
        SceneGraph* g = [SceneGraph instance];
        [AppDelegate findNodesByUUIDs:lastSelectedNodesUUID startFrom:g.rootNode result:lastSelectedNodes];
        [self setSelectedNodes:lastSelectedNodes];
    }
    
}

- (void) saveUndoStateWillChangeProperty:(NSString*)prop
{
    if (!currentDocument
        || (prop && [currentDocument.lastEditedProperty isEqualToString:prop]))
    {
        return;
    }

    currentDocument.isDirty = YES;
    currentDocument.isBackupDirty = YES;
    currentDocument.lastEditedProperty = prop;

    NSMutableDictionary* doc = [self docDataFromCurrentNodeGraph];
    [currentDocument.undoManager registerUndoWithTarget:self selector:@selector(revertToState:) object:doc];

    NSTabViewItem* item = [self tabViewItemFromDoc:currentDocument];
    [tabBar setIsEdited:YES ForTabViewItem:item];

    [self updateDirtyMark];
}

- (void) saveUndoState
{
    [self saveUndoStateWillChangeProperty:NULL];
}

#pragma mark Menu options

- (BOOL) addCCObject:(CCNode *)child toParent:(CCNode*)parent atIndex:(int)index
{
	if (!child || !parent)
	{
		return NO;
	}

	NSError *error;
	if (![self canChildBeAddedToParent:child parent:parent error:&error])
	{
		self.errorDescription = error.localizedDescription;
		return NO;
	}
    
    //[self saveUndoState];
    
    // Add object and change zOrder of objects after this child
    if (index == CCNODE_INDEX_LAST)
    {
        // Add at end of array
		[parent addChild:child z:[parent.children count]];
    }
    else
    {
        // Update zValues of children after this node
        NSArray* children = parent.children;
        for (NSUInteger i = (NSUInteger)index; i < [children count]; i++)
        {
            CCNode *aChild = children[i];
            aChild.zOrder += 1;
        }
		[parent addChild:child z:index];
        [parent sortAllChildren];
    }
    
    if(parent.hidden)
    {
        child.hidden = YES;
    }

    //Set an unset UUID
    if(child.UUID == 0x0)
    {
		child.UUID = [currentDocument getAndIncrementUUID];
    }
    
    [outlineHierarchy reloadData];
    //this setSelected cause moveNodeOnCopy in doPasteAsChild:(BOOL)asChild works wrong...
    //now all should be fixed.
    //[self setSelectedNodes:@[child]];
    //[_inspectorController updateInspectorFromSelection];
    
    return YES;
}

- (BOOL)canChildBeAddedToParent:(CCNode *)child parent:(CCNode *)parent error:(NSError **)error
{
	NodeInfo *parentInfo = parent.userObject;
    NodeInfo *childInfo = child.userObject;

	if (!parentInfo.plugIn.canHaveChildren)
	{
		if (error)
		{
			NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"You cannot add children to a %@", parentInfo.plugIn.nodeClassName] };
			*error = [NSError errorWithDomain:SBErrorDomain code:SBNodeDoesNotSupportChildrenError userInfo:errorDictionary];
		}
		return NO;
	}

	if ([self doesToBeAddedChildRequireSpecificParent:child parent:parent])
	{
		if (error)
		{
			NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"A %@ must be added to a %@", childInfo.plugIn.nodeClassName, childInfo.plugIn.requireParentClass] };
			*error = [NSError errorWithDomain:SBErrorDomain code:SBChildRequiresSpecificParentError userInfo:errorDictionary];
		}
		return NO;
	}

	if ([self doesParentPermitChildToBeAdded:parent child:child])
	{
		if (error)
		{
			NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"You cannot add a %@ to a %@", childInfo.plugIn.nodeClassName, parentInfo.plugIn.nodeClassName] };
			*error = [NSError errorWithDomain:SBErrorDomain code:SBParentDoesNotPermitSpecificChildrenError userInfo:errorDictionary];
		}
		return NO;
	}
	return YES;
}

- (BOOL)doesParentPermitChildToBeAdded:(CCNode *)parent child:(CCNode *)child
{
	NodeInfo *parentInfo = parent.userObject;
    NodeInfo *childInfo = child.userObject;

	NSArray*requiredChildren = parentInfo.plugIn.requireChildClass;
	return (requiredChildren
			&& [requiredChildren indexOfObject:childInfo.plugIn.nodeClassName] == NSNotFound);
}

- (BOOL)doesToBeAddedChildRequireSpecificParent:(CCNode *)toBeAddedChild parent:(CCNode *)parent
{
	NodeInfo* nodeInfoParent = parent.userObject;
    NodeInfo* nodeInfo = toBeAddedChild.userObject;

	NSString* requireParentClass = nodeInfo.plugIn.requireParentClass;
	return (requireParentClass
			&& ![requireParentClass isEqualToString: nodeInfoParent.plugIn.nodeClassName]);
}

- (BOOL) addCCObject:(CCNode *)obj toParent:(CCNode *)parent
{
    return [self addCCObject:obj toParent:parent atIndex:CCNODE_INDEX_LAST];
}

- (BOOL) addCCObject:(CCNode*)obj asChild:(BOOL)asChild
{
    SceneGraph* g = [SceneGraph instance];
    
    CCNode* parent;
    int index = CCNODE_INDEX_LAST;
    if (!self.selectedNode)
    {
        parent = g.rootNode;
    }
    else if (self.selectedNode == g.rootNode)
    {
        parent = g.rootNode;
    }
    else
    {
        parent = self.selectedNode.parent;
        index = 0;
        for (CCNode * child in parent.children)
        {
            ++index;
            if(child == self.selectedNode)
            {
                break;
            }
        }
    }
    
    if (asChild)
    {
        parent = self.selectedNode;
        index = CCNODE_INDEX_LAST;
        
        if(!parent && !g.rootNode)
            return NO;
        
        if (!parent)
        {
            self.selectedNodes = [NSArray arrayWithObject: g.rootNode];
        }
    }

    BOOL success = [self addCCObject:obj toParent:parent atIndex:index];
    
    if (!success && !asChild)
    {
        // If failed to add the object, attempt to add it as a child instead
        return [self addCCObject:obj asChild:YES];
    }
    
    return success;
}

-(void) loadDefaultOptionsForNewSprite:(CCNode *) node {
    node.anchorPoint = ccp(SBSettings.defaultSpriteAnchorX,SBSettings.defaultSpriteAnchorY);
    CCPositionType defaultPosType;
    defaultPosType.xUnit = SBSettings.defaultSpritePositionUnit;
    defaultPosType.yUnit = SBSettings.defaultSpritePositionUnit;
    defaultPosType.corner = CCPositionReferenceCornerBottomLeft;
    node.positionType = defaultPosType;
}

- (CCNode*) addPlugInNodeNamed:(NSString*)name asChild:(BOOL) asChild
{
    [animationPlaybackManager stop];
    CCLOG(@"Plugin name: %@",name);
    self.errorDescription = NULL;
    CCNode* node = [[PlugInManager sharedManager] createDefaultNodeOfType:name];
    if ([name isEqualToString:@"CCSprite"]) {
        [self loadDefaultOptionsForNewSprite:node];
    }
    BOOL success = [self addCCObject:node asChild:asChild];
    
    if (!success && self.errorDescription)
    {
        node = NULL;
        [self modalDialogTitle:@"Failed to Add Object" message:self.errorDescription];
    }
    
    return node;
}

- (void) dropAddSpriteNamed:(NSString*)spriteFile inSpriteSheet:(NSString*)spriteSheetFile at:(CGPoint)pt parent:(CCNode*)parent
{
    [animationPlaybackManager stop];

    NodeInfo* info = parent.userObject;
    PlugInNode* plugIn = info.plugIn;
    
    if (!spriteFile) spriteFile = @"";
    if (!spriteSheetFile) spriteSheetFile = @"";
    
    NSString* class = plugIn.dropTargetSpriteFrameClass;
    NSString* prop = plugIn.dropTargetSpriteFrameProperty;
    
    CCLOG(@"Drop class: %@",class);
    
    if (class && prop) {
        // Create the node
        CCNode* node = [[PlugInManager sharedManager] createDefaultNodeOfType:class];
        
        // Round position
        pt.x = roundf(pt.x);
        pt.y = roundf(pt.y);
        
        // Set its position
        [PositionPropertySetter setPosition:NSPointFromCGPoint(pt) forNode:node prop:@"position"];
        
        [CCBReaderInternal setProp:prop
                            ofType:@"SpriteFrame"
                           toValue:[NSArray arrayWithObjects:spriteSheetFile, spriteFile, nil]
                           forNode:node
                        parentSize:CGSizeZero
                   withParentGraph:nil
                       fileVersion:kCCBFileFormatVersion];
        
        if ([class isEqualToString:@"CCSprite"]) {
            [self loadDefaultOptionsForNewSprite:node];
        }
        
        // Set it's displayName to the name of the spriteFile
        node.displayName = [[spriteFile lastPathComponent] stringByDeletingPathExtension];
        [self addCCObject:node toParent:parent];
    }
}

- (void) dropAddSpriteNamed:(NSString*)spriteFile inSpriteSheet:(NSString*)spriteSheetFile at:(CGPoint)pt
{
    // Sprite dropped in working canvas
    
    CCNode* node = self.selectedNode;
    if (!node || node.plugIn.isJoint)
        node = [CocosScene cocosScene].rootNode;
    
    CCNode* parent = node.parent;
    NodeInfo* info = parent.userObject;
    
    if (info.plugIn.acceptsDroppedSpriteFrameChildren)
    {
        [self dropAddSpriteNamed:spriteFile inSpriteSheet:spriteSheetFile at:[parent convertToNodeSpace:pt] parent:parent];
        return;
    }
    
    info = node.userObject;
    if (info.plugIn.acceptsDroppedSpriteFrameChildren)
    {
        [self dropAddSpriteNamed:spriteFile inSpriteSheet:spriteSheetFile at:[node convertToNodeSpace:pt] parent:node];
    }
}

//------------------ View --------------------
-(void) setSortCustomProperties:(BOOL)sortCustomProperties {
    SBSettings.sortCustomProperties = sortCustomProperties;
    SBSettings.save;
    [_inspectorController updateInspectorFromSelection];
}

-(BOOL) sortCustomProperties {
    return SBSettings.sortCustomProperties;
}

-(void) setShowRulers:(BOOL)showRulers {
    SBSettings.showRulers = showRulers;
    SBSettings.save;
    [CocosScene cocosScene].rulerLayer.visible = showRulers;
}

-(BOOL) showRulers {
    return SBSettings.showRulers;
}

-(void) setShowPrefabs:(BOOL)showPrefabs {
    SBSettings.showPrefabs = showPrefabs;
    SBSettings.save;
    [_inspectorController updateInspectorFromSelection];
}

-(BOOL)showPrefabs {
    return SBSettings.showPrefabs;
}

-(void) setShowPrefabPreview:(BOOL)showPrefabPreview {
    SBSettings.showPrefabPreview = showPrefabPreview;
    SBSettings.save;
    [self.outlineProject reloadData];
}

-(BOOL)showPrefabPreview {
    return SBSettings.showPrefabPreview;
}

-(BOOL)showJoints
{
	return ![SceneGraph instance].joints.node.hidden;
}

-(void)setShowJoints:(BOOL)showJoints
{
	[SceneGraph instance].joints.node.hidden = !showJoints;
	[sequenceHandler.outlineHierarchy reloadItem:[SceneGraph instance].joints reloadChildren:YES];
}

-(void)setFilterString:(NSString*)filterString
{
    if(filterTimer) {
        [filterTimer invalidate];
        filterTimer = nil;
    }
    _filterString = filterString;
    projectOutlineHandler.filter = filterString;
    [outlineProject reloadData];
    if(filterString && ![filterString isEqualToString:@""])
        [outlineProject expandItem:nil expandChildren:YES];
}

-(void)setFilterStringByTimer:(NSTimer*)timer
{
    [self setFilterString:timer.userInfo];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    if(filterTimer)
    {
        [filterTimer invalidate];
    }
    filterTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(setFilterStringByTimer:)
                                   userInfo:textField.stringValue
                                    repeats:YES];
    
}


-(void)addJoint:(NSString*)jointName at:(CGPoint)pt
{
    SceneGraph* g = [SceneGraph instance];
    
    CCNode* addedNode = [[PlugInManager sharedManager] createDefaultNodeOfType:jointName];
    addedNode.UUID = [[AppDelegate appDelegate].currentDocument getAndIncrementUUID];

    
    [g.joints addJoint:(CCBPhysicsJoint*)addedNode];
    

    [PositionPropertySetter setPosition:[addedNode.parent convertToNodeSpace:pt] forNode:addedNode prop:@"position"];
    
    [outlineHierarchy reloadData];
    [self setSelectedNodes: [NSArray arrayWithObject: addedNode]];
    [_inspectorController updateInspectorFromSelection];
}

- (void) gotoAutoplaySequence
{
	SequencerSequence * autoPlaySequence = [currentDocument.sequences findFirst:^BOOL(SequencerSequence * sequence, int idx) {
		return sequence.autoPlay;
	}];
	
	if(autoPlaySequence)
	{
		sequenceHandler.currentSequence = autoPlaySequence;
		sequenceHandler.currentSequence.timelinePosition = 0.0f;
	}
}

- (void) dropAddPlugInNodeNamed:(NSString*) nodeName at:(CGPoint)pt
{
    PlugInNode* pluginDescription = [[PlugInManager sharedManager] plugInNodeNamed:nodeName];
    if(pluginDescription.isJoint)
    {
		if(!sequenceHandler.currentSequence.autoPlay || sequenceHandler.currentSequence.timelinePosition != 0.0f)
		{
			[self modalDialogTitle:@"Changing Timeline" message:@"In order to add a new joint, you must be viewing the first frame of the 'autoplay' timeline." disableKey:@"AddJointSetSequencer"];
			
		
			[self gotoAutoplaySequence];
		}

		
        [self addJoint:nodeName at:pt];
        return;
    }
    
    // New node was dropped in working canvas
    CCNode* addedNode = [self addPlugInNodeNamed:nodeName asChild:NO];
    
        
    // Set position
    if (addedNode)
    {
        [PositionPropertySetter setPosition:[addedNode.parent convertToNodeSpace:pt] forNode:addedNode prop:@"position"];
        [_inspectorController updateInspectorFromSelection];
    }
}

- (void) dropAddPlugInNodeNamed:(NSString *)nodeName parent:(CCNode*)parent index:(int)idx
{
    CCNode* node = [[PlugInManager sharedManager] createDefaultNodeOfType:nodeName];
    if ([nodeName isEqualToString:@"CCSprite"]) {
        [self loadDefaultOptionsForNewSprite:node];
    }
    [self addCCObject:node toParent:parent atIndex:idx];
}

- (void) dropAddCCBFileNamed:(NSString*)ccbFile at:(CGPoint)pt parent:(CCNode*)parent
{
    if (!parent)
    {
        if (self.selectedNode != [CocosScene cocosScene].rootNode)
        {
            parent = self.selectedNode.parent;
        }
        if (!parent) parent = [CocosScene cocosScene].rootNode;
        
        pt = [parent convertToNodeSpace:pt];
    }
    
    CCNode* node = [[PlugInManager sharedManager] createDefaultNodeOfType:@"CCBFile"];
    [NodeGraphPropertySetter setNodeGraphForNode:node andProperty:@"ccbFile" withFile:ccbFile parentSize:parent.contentSize];
    [PositionPropertySetter setPosition:NSPointFromCGPoint(pt) type:CCPositionTypePoints forNode:node prop:@"position"];
    [PositionPropertySetter setPositionType:CCPositionTypeUIPoints oldPositionType:CCPositionTypePoints forNode:node prop:@"position"];
    node.displayName = [[ccbFile lastPathComponent] stringByDeletingPathExtension];
    [self loadDefaultOptionsForNewSprite:node];
    [self addCCObject:node toParent:parent];    
}

- (IBAction) copy:(id) sender
{
    //Copy warnings.
    if([[self window] firstResponder] == _warningTableView)
    {
        CCBWarning * warning = projectSettings.lastWarnings.warnings[_warningTableView.selectedRow];
        NSString * stringToWrite = warning.description;
        NSPasteboard* cb = [NSPasteboard generalPasteboard];
        
        [cb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [cb setString:stringToWrite forType:NSStringPboardType];
        return;
    }
    
    if([[self window] firstResponder] != sequenceHandler.outlineHierarchy)
    {
        // Copy keyframes
        NSArray* keyframes = [sequenceHandler selectedKeyframesForCurrentSequence];
        if ([keyframes count] > 0)
        {
            NSMutableSet* propsSet = [NSMutableSet set];
            NSMutableSet* seqsSet = [NSMutableSet set];
            BOOL duplicatedProps = NO;
            BOOL hasNodeKeyframes = NO;
            BOOL hasChannelKeyframes = NO;
            
            for (int i = 0; i < keyframes.count; i++)
            {
                SequencerKeyframe* keyframe = [keyframes objectAtIndex:i];
                
                NSValue* seqVal = [NSValue valueWithPointer:(__bridge const void *)(keyframe.parent)];
                if (![seqsSet containsObject:seqVal])
                {
                    NSString* propName = keyframe.name;
                    
                    if (propName)
                    {
                        if ([propsSet containsObject:propName])
                        {
                            duplicatedProps = YES;
                            break;
                        }
                        [propsSet addObject:propName];
                        [seqsSet addObject:seqVal];
                        
                        hasNodeKeyframes = YES;
                    }
                    else
                    {
                        hasChannelKeyframes = YES;
                    }
                }
            }
            
            if (duplicatedProps)
            {
                [self modalDialogTitle:@"Failed to Copy" message:@"You can only copy keyframes from one node."];
                return;
            }
            
            if (hasChannelKeyframes && hasNodeKeyframes)
            {
                [self modalDialogTitle:@"Failed to Copy" message:@"You cannot copy sound/callback keyframes and node keyframes at once."];
                return;
            }
            
            NSString* clipType = kClipboardKeyFrames;
            if (hasChannelKeyframes)
            {
                clipType = kClipboardChannelKeyframes;
            }
            
            // Serialize keyframe
            NSMutableArray* serKeyframes = [NSMutableArray array];
            for (SequencerKeyframe* keyframe in keyframes)
            {
                [serKeyframes addObject:[keyframe serialization]];
            }
            NSData* clipData = [NSKeyedArchiver archivedDataWithRootObject:serKeyframes];
            NSPasteboard* cb = [NSPasteboard generalPasteboard];
            [cb declareTypes:[NSArray arrayWithObject:clipType] owner:self];
            [cb setData:clipData forType:clipType];
            
            return;
        }
    }
    
    
    // Copy node
    if (self.selectedNodes.count == 0)
        return;
    
    if(self.selectedNode.plugIn.isJoint)
        return;
    
    NSMutableArray *serArray = [NSMutableArray array];
    
    // Serialize selected node
    for(CCNode* node in self.selectedNodes)
    {
        [serArray addObject:[CCBWriterInternal dictionaryFromCCObject:node]];
    }
    //NSMutableDictionary* clipDict = [CCBWriterInternal dictionaryFromCCObject:self.selectedNode];
    NSData* clipData = [NSKeyedArchiver archivedDataWithRootObject:serArray];
    NSPasteboard* cb = [NSPasteboard generalPasteboard];
    
    [cb declareTypes:[NSArray arrayWithObjects:@"com.cocosbuilder.node", nil] owner:self];
    [cb setData:clipData forType:@"com.cocosbuilder.node"];
}

-(void)updateUUIDs:(CCNode*)node
{
    node.UUID = [currentDocument getAndIncrementUUID];
	[node postCopyFixup];
    
    if (![NSStringFromClass(node.class) isEqualToString:@"CCBPCCBFile"])
    {
        for (CCNode * child in node.children) {
            [self updateUUIDs:child];
        }
    }
}

- (void) doPasteAsChild:(BOOL)asChild
{
    NSPasteboard* cb = [NSPasteboard generalPasteboard];
    NSString* type = [cb availableTypeFromArray:[NSArray arrayWithObjects:@"com.cocosbuilder.node", nil]];
    
    if (type)
    {
        [self saveUndoState];
        
        [animationPlaybackManager stop];

        NSData* clipData = [cb dataForType:type];
        
        NSMutableArray *serArray = [NSKeyedUnarchiver unarchiveObjectWithData:clipData];
        
        NSArray* selecetdNodes = [self.selectedNodes copy];
        NSMutableArray *copiedNodes = [NSMutableArray array];
        // Serialize selected node
        for(NSDictionary* clipDict in serArray)
        {
            self.selectedNodes = [selecetdNodes copy];
            CGSize parentSize;
            if (asChild) parentSize = self.selectedNode.contentSize;
            else parentSize = self.selectedNode.parent.contentSize;
            
            CCNode* clipNode = [CCBReaderInternal nodeGraphFromDictionary:clipDict
                                                               parentSize:parentSize
                                                              fileVersion:kCCBFileFormatVersion];
            [CCBReaderInternal postDeserializationFixup:clipNode];
            [self updateUUIDs:clipNode];
            
            [self addCCObject:clipNode asChild:asChild];
            [copiedNodes addObject:clipNode];
            
            if (SBSettings.moveNodeOnCopy && !asChild) {
                //move copied node's to see it copied
                CGPoint pointPos = ccpAdd(clipNode.positionInPoints, ccp(clipNode.contentSize.width * 0.25, clipNode.contentSize.height * -0.25));
                clipNode.position = [clipNode convertPositionFromPoints:pointPos type:clipNode.positionType];
            }
        }
        //after copy-pastle multiple nodes make all them selected
        self.selectedNodes = copiedNodes;
        
        //We might have copy/cut/pasted and body. Fix it up.
        [SceneGraph fixupReferences];
    }
}

- (IBAction) paste:(id) sender
{
    if (!currentDocument) return;
    
    // Paste keyframes
    NSPasteboard* cb = [NSPasteboard generalPasteboard];
    NSString* type = [cb availableTypeFromArray:[NSArray arrayWithObjects:kClipboardKeyFrames, kClipboardChannelKeyframes, nil]];
    
    if (type)
    {
        if (!self.selectedNode && [type isEqualToString:kClipboardKeyFrames])
        {
            [self modalDialogTitle:@"Paste Failed" message:@"You need to select a node to paste keyframes"];
            return;
        }
            
        // Unarchive keyframes
        NSData* clipData = [cb dataForType:type];
        NSMutableArray* serKeyframes = [NSKeyedUnarchiver unarchiveObjectWithData:clipData];
        NSMutableArray* keyframes = [NSMutableArray array];
        
        // Save keyframes and find time of first kf
        float firstTime = MAXFLOAT;
        for (id serKeyframe in serKeyframes)
        {
            SequencerKeyframe* keyframe = [[SequencerKeyframe alloc] initWithSerialization:serKeyframe];
            if (keyframe.time < firstTime)
            {
                firstTime = keyframe.time;
            }
            [keyframes addObject:keyframe];
        }
            
        // Adjust times and add keyframes
        SequencerSequence* seq = sequenceHandler.currentSequence;
        
        for (SequencerKeyframe* keyframe in keyframes)
        {
            // Adjust time
            keyframe.time = [seq alignTimeToResolution:keyframe.time - firstTime + seq.timelinePosition];
            
            // Add the keyframe
            if ([type isEqualToString:kClipboardKeyFrames])
            {
                [self.selectedNode addKeyframe:keyframe forProperty:keyframe.name atTime:keyframe.time sequenceId:seq.sequenceId];
            }
            else if ([type isEqualToString:kClipboardChannelKeyframes])
            {
                if (keyframe.type == kCCBKeyframeTypeCallbacks)
                {
                    [seq.callbackChannel.seqNodeProp setKeyframe:keyframe];
                }
                else if (keyframe.type == kCCBKeyframeTypeSoundEffects)
                {
                    [seq.soundChannel.seqNodeProp setKeyframe:keyframe];
                }
                [keyframe.parent deleteKeyframesAfterTime:seq.timelineLength];
                [[SequencerHandler sharedHandler] redrawTimeline];
            }

            [[SequencerHandler sharedHandler] deleteDuplicateKeyframesForCurrentSequence];
        }
        
    }
    
    // Paste nodes
    [self doPasteAsChild:NO];
}

- (IBAction) pasteAsChild:(id)sender
{
    [self doPasteAsChild:YES];
}

- (void) deleteNode:(CCNode*)node
{
    SceneGraph* g = [SceneGraph instance];

    if (!node
        || node == g.rootNode)
    {
        return;
    }

    //[self saveUndoState];
    
    CCNode *nextSelection = nil;
    
    // Change zOrder of nodes after this one
    int zOrder = node.zOrder;
    NSArray* siblings = [node.parent children];
    for (int i = zOrder+1; i < [siblings count]; i++)
    {
        CCNode* sibling = siblings[i];
        if(!nextSelection)
            nextSelection = sibling;
        sibling.zOrder -= 1;
    }
    
    if(!nextSelection && [siblings count] && zOrder-1>=0)
        nextSelection = siblings[zOrder-1];
    
    if(!nextSelection)
        nextSelection = node.parent;
    
    CCNode *parent = node.parent;
    
    [node removeFromParentAndCleanup:NO];
    
    [parent sortAllChildren];
    [outlineHierarchy reloadData];
    
    //[self setSelectedNodes:@[nextSelection]];
    //[sequenceHandler updateOutlineViewSelection];

    [[NSNotificationCenter defaultCenter] postNotificationName:SCENEGRAPH_NODE_DELETED object:node];
}

- (IBAction) delete:(id) sender
{
    // First attempt to delete selected keyframes
	if ([sequenceHandler deleteSelectedKeyframesForCurrentSequence])
	{
		return;
	}

	// Then delete the selected node
    NSArray* nodesToDelete = [NSArray arrayWithArray:self.selectedNodes];
    for (CCNode* node in nodesToDelete)
    {
        [self deleteNode:node];
    }
    [self setSelectedNodes:NULL];
}

- (IBAction) cut:(id) sender
{
    SceneGraph* g = [SceneGraph instance];
    if (self.selectedNode == g.rootNode)
    {
        [self modalDialogTitle:@"Failed to cut object" message:@"The root node cannot be removed"];
        return;
    }
    
    [self copy:sender];
    [self delete:sender];
}

- (void) moveSelectedObjectWithDelta:(CGPoint)delta
{
    if (self.selectedNodes.count == 0) return;
    
    for (CCNode* selectedNode in self.selectedNodes)
    {
        if(selectedNode.locked)
            continue;
        
        [self saveUndoStateWillChangeProperty:@"position"];
        
        // Get and update absolute position
        CGPoint absPos = selectedNode.positionInPoints;
        absPos = ccpAdd(absPos, delta);
        
        // Convert to relative position
        //CGSize parentSize = [PositionPropertySetter getParentSize:selectedNode];
        //CCPositionType positionType = [PositionPropertySetter positionTypeForNode:selectedNode prop:@"position"];
        NSPoint newPos = [selectedNode convertPositionFromPoints:absPos type:selectedNode.positionType];
        //NSPoint newPos = [PositionPropertySetter calcRelativePositionFromAbsolute:NSPointFromCGPoint(absPos) type:positionType];
        
        // Update the selected node
        [PositionPropertySetter setPosition:newPos forNode:selectedNode prop:@"position"];
        [PositionPropertySetter addPositionKeyframeForNode:selectedNode];
        
        [_inspectorController refreshProperty:@"position"];
    }
}

- (IBAction)menuSlightObject:(id)sender {
    int dir = (int)[sender tag];
    
    if (self.selectedNodes.count == 0) return;
    
    CGPoint delta = CGPointZero;
    if (dir == 0) delta = ccp(-0.1, 0);
    else if (dir == 1) delta = ccp(0.1, 0);
    else if (dir == 2) delta = ccp(0, 0.1);
    else if (dir == 3) delta = ccp(0, -0.1);
    
    [self moveSelectedObjectWithDelta:delta];
}


- (IBAction) menuNudgeObject:(id)sender
{
    int dir = (int)[sender tag];
    
    if (self.selectedNodes.count == 0) return;
    
    CGPoint delta = CGPointZero;
    if (dir == 0) delta = ccp(-1, 0);
    else if (dir == 1) delta = ccp(1, 0);
    else if (dir == 2) delta = ccp(0, 1);
    else if (dir == 3) delta = ccp(0, -1);
    
    [self moveSelectedObjectWithDelta:delta];
}

- (IBAction) menuMoveObject:(id)sender
{
    int dir = (int)[sender tag];
    
    if (self.selectedNodes.count == 0) return;
    
    CGPoint delta = CGPointZero;
    if (dir == 0) delta = ccp(-10, 0);
    else if (dir == 1) delta = ccp(10, 0);
    else if (dir == 2) delta = ccp(0, 10);
    else if (dir == 3) delta = ccp(0, -10);
    
    [self moveSelectedObjectWithDelta:delta];
}

- (IBAction) saveDocumentAs:(id)sender
{
    if (!currentDocument) return;
    
    NSSavePanel* saveDlg = [NSSavePanel savePanel];
    [saveDlg setAllowedFileTypes:[NSArray arrayWithObject:@"ccb"]];
	__block SavePanelLimiter* limiter = [[SavePanelLimiter alloc] initWithPanel:saveDlg];
    
    [saveDlg beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSOKButton)
        {
            NSString *filename = [[saveDlg URL] path];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0),
                           dispatch_get_main_queue(), ^{
                [(CCGLView*)[[CCDirector sharedDirector] view] lockOpenGLContext];
                
                // Save file to new path
                [self saveFile:filename];
                
                // Close document
                [tabView removeTabViewItem:[self tabViewItemFromDoc:currentDocument]];
                
                // Open newly created document
                [self openFile:filename];
                
                [(CCGLView*)[[CCDirector sharedDirector] view] unlockOpenGLContext];
            });
        }
		
		// ensures the limiter remains in memory until the block finishes
		limiter = nil;
    }];
}

- (IBAction) saveDocument:(id)sender
{
    // Finish editing inspector
    if (![[self window] makeFirstResponder:[self window]])
    {
        return;
    }
    
    if (currentDocument && currentDocument.filePath)
    {
        [self saveFile:currentDocument.filePath];
    }
    else
    {
        [self saveDocumentAs:sender];
    }
}

- (IBAction) saveAllDocuments:(id)sender
{
    // Save all JS files
    //[[NSDocumentController sharedDocumentController] saveAllDocuments:sender]; //This API have no effects
    NSArray* JSDocs = [[NSDocumentController sharedDocumentController] documents];
    for (int i = 0; i < [JSDocs count]; i++)
    {
        NSDocument* doc = JSDocs[i];
        if (doc.isDocumentEdited)
        {
            [doc saveDocument:sender];
        }
    }
    
    // Save all CCB files
    CCBDocument* oldCurDoc = currentDocument;
    NSArray* docs = [tabView tabViewItems];
    for (int i = 0; i < [docs count]; i++)
    {
        CCBDocument* doc = [(NSTabViewItem*) docs[i] identifier];
         if (doc.isDirty)
         {
             [self switchToDocument:doc forceReload:NO];
             [self saveDocument:sender];
         }
    }
    [self switchToDocument:oldCurDoc forceReload:NO];
}

- (void)checkForDirtyDocumentAndPublishAsync:(BOOL)async
{
    [[self window] makeFirstResponder:[self window]];
    currentDocument.lastEditedProperty = nil;
    if ([projectSettings.platformsSettings count] == 0)
    {
        if(async)
            [self modalDialogTitle:@"Published Failed" message:@"There are no configured publish target platforms. Please check your Publish Settings."];
        
        return;
    }
    
    // Check if there are unsaved documents
    if ([self hasDirtyDocument])
    {
        NSInteger result = NSAlertDefaultReturn;
        if(async)
        {
            NSAlert* alert = [NSAlert alertWithMessageText:@"Publish Project" defaultButton:@"Save All" alternateButton:@"Cancel" otherButton:@"Don't Save" informativeTextWithFormat:@"There are unsaved documents. Do you want to save before publishing?"];
            [alert setAlertStyle:NSWarningAlertStyle];
            result = [alert runModal];
        }
        
        switch (result) {
            case NSAlertDefaultReturn:
                [self saveAllDocuments:nil];
                // Falling through to publish
            case NSAlertOtherReturn:
                // Open progress window and publish
                [self publishStartAsync:async silent:NO];
                break;
            default:
                break;
        }
    }
    else
    {
        [self publishStartAsync:async silent:NO];
    }
}

- (void)publishStartAsync:(BOOL)async silent:(BOOL) silent
{
    self.publisherController = [[CCBPublisherController alloc] init];
    _publisherController.projectSettings = projectSettings;
    _publisherController.packageSettings = [[ResourceManager sharedManager] loadAllPackageSettings];
    _publisherController.oldResourcePaths = [[ResourceManager sharedManager] oldResourcePaths];

    id __weak selfWeak = self;
    _publisherController.finishBlock = ^(CCBPublisher *aPublisher, CCBWarnings *someWarnings)
    {
        [selfWeak publisher:aPublisher finishedWithWarnings:someWarnings];
    };

    modalTaskStatusWindow = [[TaskStatusWindow alloc] initWithWindowNibName:@"TaskStatusWindow"];
    _publisherController.taskStatusUpdater = modalTaskStatusWindow;

    // Open progress window and publish
    if (async)
    {
        [_publisherController startAsync:YES];
        if (!silent) {
            [self modalStatusWindowStartWithTitle:@"Publishing" isIndeterminate:NO onCancelBlock:^
            {
                [_publisherController cancel];
            }];
            [self modalStatusWindowUpdateStatusText:@"Starting up..."];
        }
    }
    else
    {
        [_publisherController startAsync:NO];
    }

    [animationPlaybackManager stop];
}

- (void)publisher:(CCBPublisher *)publisher finishedWithWarnings:(CCBWarnings *)warnings
{
    [self modalStatusWindowFinish];
    
    // Update project view
    projectSettings.lastWarnings = warnings;
    [outlineProject reloadData];
    
    // Update warnings button in toolbar
    [self updateWarningsButton];
    
    if (warnings.warnings.count)
    {
        [projectViewTabs selectBarButtonIndex:3];
    }
}

- (IBAction) menuPublishProject:(id)sender
{
    [self checkForDirtyDocumentAndPublishAsync:YES];
}

- (IBAction) menuCleanCacheDirectories:(id)sender
{
    [CCBPublisherCacheCleaner cleanWithProjectSettings:projectSettings];
}

// Temporary utility function until new publish system is in place
- (IBAction)menuUpdateCCBsInDirectory:(id)sender
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    
    [openDlg beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSOKButton)
        {
            NSArray* files = [openDlg URLs];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0),
                           dispatch_get_main_queue(), ^{
                [(CCGLView*)[[CCDirector sharedDirector] view] lockOpenGLContext];
                
                for (int i = 0; i < [files count]; i++)
                {
                    NSString* dirName = [[files objectAtIndex:i] path];
                    
                    NSArray* arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirName error:NULL];
                    for(NSString* file in arr)
                    {
                        if ([file hasSuffix:@".ccb"])
                        {
                            NSString* absPath = [dirName stringByAppendingPathComponent:file];
                            [self openFile:absPath];
                            [self saveFile:absPath];
                            //[self publishDocument:NULL];
                            [self performClose:sender];
                        }
                    }
                }
                
                [(CCGLView*)[[CCDirector sharedDirector] view] unlockOpenGLContext];
            });
        }
    }];
}

- (IBAction)menuSBSettings:(id)sender {
    SettingsWindow *settingsWindow = [SettingsWindow new];
    if ([settingsWindow runModalSheetForWindow:window]) {
        [self scheduleAutoSaveTimer];
    } else {
        //press "esc" or "cancel" in project settings
        //do nothing
    }
}


- (IBAction)menuProjectSettings:(id)sender
{
    if (!projectSettings)
    {
        return;
    }

    NSMutableDictionary *projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:self.openedProjectFileName];
    self.editedProjectSettings = [[ProjectSettings alloc] initWithSerialization:projectDict];
    self.editedProjectSettings.projectPath = self.openedProjectFileName;
    ProjectSettingsWindowController *settingsWindowController = [[ProjectSettingsWindowController alloc]
                                                                 initWithProjectSettings:self.editedProjectSettings];
    
    settingsWindowController.projectSettings = self.editedProjectSettings;
    
    if ([settingsWindowController runModalSheetForWindow:window]) {
        self.projectSettings = NULL;
        [ResourceManager sharedManager].projectSettings = NULL;
        [[ResourceManager sharedManager] removeAllDirectories];
        
        self.projectSettings = self.editedProjectSettings;
        self.projectSettings.projectPath = self.openedProjectFileName;
        
        _resourceCommandController.projectSettings = self.projectSettings;
        projectOutlineHandler.projectSettings = self.projectSettings;
        [ResourceManager sharedManager].projectSettings = self.projectSettings;
        
        NSArray *docsTabs = [tabView tabViewItems];
        for (int i = 0; i < docsTabs.count; i++) {
            CCBDocument *doc = [(NSTabViewItem*) docsTabs[i] identifier];
            doc.projectSettings = self.projectSettings;
        }
        
        [self updateEverythingAfterSettingsChanged];
    } else {
        //press "esc" or "cancel" in project settings
        //do nothing
    }
}

- (void)updateEverythingAfterSettingsChanged
{
    [self.projectSettings store];
    [self updateResourcePathsFromProjectSettings];
    [CCBPublisherCacheCleaner cleanWithProjectSettings:projectSettings];
    [self reloadResources];
    [self setResolution:0];
}

- (IBAction) openDocument:(id)sender
{
    // Create the File Open Dialog
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];

    NSArray *allowedFileTypes = currentDocument
        ? @[@"spritebuilder", PACKAGE_NAME_SUFFIX]
        : @[@"spritebuilder"];
    [openDlg setAllowedFileTypes:allowedFileTypes];

    [openDlg beginSheetModalForWindow:window completionHandler:^(NSInteger result)
    {
        if (result == NSOKButton)
        {
            NSArray* files = [openDlg URLs];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^
            {
                for (int i = 0; i < [files count]; i++)
                {
                    NSString *fileName = [[files objectAtIndex:i] path];
                    if ([fileName hasSuffix:PACKAGE_NAME_SUFFIX])
                    {
                        PackageImporter *packageImporter = [[PackageImporter alloc] init];
                        packageImporter.projectSettings = projectSettings;
                        [packageImporter importPackagesWithPaths:@[fileName] error:NULL];
                    }
                    else
                    {
                        [self openProject:fileName];
                    }
                }
            });
        }
    }];
}

- (IBAction) menuCloseProject:(id)sender
{
    [self closeProject];
}


-(void) createNewProject
{
    // Accepted create document, prompt for place for file
    NSSavePanel* saveDlg = [NSSavePanel savePanel];
    [saveDlg setAllowedFileTypes:[NSArray arrayWithObject:@"spritebuilder"]];
    //saveDlg.message = @"Save your project file in the same directory as your projects resources.";

    // Configure the accessory view
    [saveDlg setAccessoryView:saveDlgAccessoryView];
    [saveDlgLanguagePopup removeAllItems];
    [saveDlgLanguagePopup addItemsWithTitles:@[@"C++"]];
    saveDlgLanguagePopup.target = self;

    [saveDlg beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSOKButton)
        {
            NSString* fileName = [[saveDlg URL] path];
            NSString* fileNameRaw = [fileName stringByDeletingPathExtension];
            
            // Check validity of file name
            NSCharacterSet* invalidChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
            if ([[fileNameRaw lastPathComponent] rangeOfCharacterFromSet:invalidChars].location == NSNotFound)
            {
                // Create directory
                [[NSFileManager defaultManager] createDirectoryAtPath:fileName withIntermediateDirectories:NO attributes:NULL error:NULL];
                
                
                // Create project file
                NSString* projectName = [fileNameRaw lastPathComponent];
                fileName = [[fileName stringByAppendingPathComponent:projectName] stringByAppendingPathExtension:@"ccbproj"];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0),
                               dispatch_get_main_queue(), ^{
                                   CCBProjectCreator * creator = [[CCBProjectCreator alloc] init];
                                   if ([creator createDefaultProjectAtPath:fileName])
                                   {
                                       [self openProject:[fileNameRaw stringByAppendingPathExtension:@"spritebuilder"]];
                                   }
                                   else
                                   {
                                       [self modalDialogTitle:@"Failed to Create Project" message:@"Failed to create the project, make sure you are saving it to a writable directory."];
                                   }
                               });
            }
            else
            {
                [self modalDialogTitle:@"Failed to Create Project" message:@"Failed to create the project, make sure to only use letters and numbers for the file name (no spaces allowed)."];
            }
        }
    }];
}

- (IBAction) menuNewProject:(id)sender
{
	[self createNewProject];
}


- (IBAction) menuNewPackage:(id)sender
{
    [_resourceCommandController newPackage:sender];
}

- (IBAction) newFolder:(id)sender
{
    [_resourceCommandController newFolder:nil];
}

- (IBAction) newDocument:(id)sender
{
    [_resourceCommandController newFile:nil];
}

- (IBAction) performClose:(id)sender
{
    if (!currentDocument) return;
    NSTabViewItem* item = [self tabViewItemFromDoc:currentDocument];
    if (!item) return;
    
    if ([self tabView:tabView shouldCloseTabViewItem:item])
    {
        [tabView removeTabViewItem:item];
    }
}

- (void) removedDocumentWithPath:(NSNotification *)notification
{
    NSString *path = [notification object][@"filepath"];

    NSTabViewItem* item = [self tabViewItemFromPath:path includeViewWithinFolderPath:YES];
    if (item)
    {
        [tabView removeTabViewItem:item];
    }
}

- (void) renamedDocumentPathFrom:(NSString*)oldPath to:(NSString*)newPath
{
    NSTabViewItem* item = [self tabViewItemFromPath:oldPath includeViewWithinFolderPath:NO];
    CCBDocument* doc = [item identifier];
    doc.filePath = newPath;
    [item setLabel:doc.formattedName];
}

- (void)renamedResourcePathFrom:(NSString *)fromPath toPath:(NSString *)toPath
{
    NSArray *items = [tabView tabViewItems];
   	for (NSUInteger i = 0; i < [items count]; i++)
   	{
   		CCBDocument *doc = [(NSTabViewItem *) [items objectAtIndex:i] identifier];
        if ([doc.filePath rangeOfString:fromPath].location != NSNotFound)
        {
            NSString *newFileName = [doc.filePath stringByReplacingOccurrencesOfString:fromPath withString:toPath];
            doc. filePath = newFileName;
        }
   	}
}

- (IBAction) menuSelectBehind:(id)sender
{
    [[CocosScene cocosScene] selectBehind];
}

- (IBAction) menuDeselect:(id)sender
{
    [self setSelectedNodes:NULL];
}

- (IBAction) undo:(id)sender
{
    if (!currentDocument) return;
    [currentDocument.undoManager undo];
    currentDocument.lastEditedProperty = NULL;
}

- (IBAction) redo:(id)sender
{
    if (!currentDocument) return;
    [currentDocument.undoManager redo];
    currentDocument.lastEditedProperty = NULL;
}

- (DeviceBorder*) orientedDeviceTypeForSize:(CGSize)size
{
    return [defaultCanvasSizes objectForKey:[NSValue valueWithSize:size]];
}

- (void) updatePositionScaleFactor
{
    ResolutionSetting* res = [currentDocument.resolutions objectAtIndex:currentDocument.currentResolution];
    
    if (!res)
    {
        res = [[ResolutionSetting alloc] init];
        res.resourceScale = 1;
    }
	
    if([CCDirector sharedDirector].contentScaleFactor != res.resourceScale)
    {
        [[CCTextureCache sharedTextureCache] removeAllTextures];
        [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFrames];
        FNTConfigRemoveCache();
    }

    [CCDirector sharedDirector].contentScaleFactor = res.resourceScale;
    [CCDirector sharedDirector].UIScaleFactor = res.mainScale;
    [[CCFileUtils sharedFileUtils] setMacContentScaleFactor:res.resourceScale];
				
    // Setup the rulers with the new contentScale
    [[CocosScene cocosScene].rulerLayer setup];
}

- (void) setResolution:(int)r
{
    ResolutionSetting* res = [currentDocument.resolutions objectAtIndex:currentDocument.currentResolution];
    float oldSize = self.projectSettings.defaultOrientation == kCCBOrientationLandscape?res.height:res.width;
    
    
    currentDocument.currentResolution = r;
    
    [self updatePositionScaleFactor];
    
    res = [currentDocument.resolutions objectAtIndex:currentDocument.currentResolution];
    float curSize = self.projectSettings.defaultOrientation == kCCBOrientationLandscape?res.height:res.width;
    if(oldSize != 0 && curSize != 0)
        [CocosScene cocosScene].stageZoom *= oldSize/curSize;
    
    //
    // No need to call setStageSize here, since it gets called from reloadResources
    //
    //CocosScene* cs = [CocosScene cocosScene];
    //ResolutionSetting* resolution = [currentDocument.resolutions objectAtIndex:r];
    //[cs setStageSize:CGSizeMake(resolution.width, resolution.height) centeredOrigin:[cs centeredOrigin]];
    
    [self updateResolutionMenu];
    [self reloadResources];
    
    // Update size of root node
    //[PositionPropertySetter refreshAllPositions];
}

- (IBAction) menuEditStageSize:(id)sender
{
    if (!currentDocument) return;
    
    ResolutionSetting* setting = [currentDocument.resolutions objectAtIndex:currentDocument.currentResolution];
    
    StageSizeWindow* wc = [[StageSizeWindow alloc] initWithWindowNibName:@"StageSizeWindow"];
    wc.wStage = setting.width / setting.resourceScale;
    wc.hStage = setting.height / setting.resourceScale;
    
    int success = [wc runModalSheetForWindow:window];
    if (success)
    {
        [self saveUndoStateWillChangeProperty:@"*stageSize"];
        
        for(ResolutionSetting* resolution in currentDocument.resolutions)
        {
            resolution.width = wc.wStage * resolution.resourceScale;
            resolution.height = wc.hStage * resolution.resourceScale;
        }
        
        //currentDocument.resolutions = [self updateResolutions:currentDocument.resolutions forDocDimensionType:kCCBDocDimensionsTypeLayer];
        [self updateResolutionMenu];
        [self setResolution:currentDocument.currentResolution];
    }
}


- (IBAction) menuEditResolutionSettings:(id)sender
{
    if (!currentDocument) return;
    
    ResolutionSettingsWindow* wc = [[ResolutionSettingsWindow alloc] initWithWindowNibName:@"ResolutionSettingsWindow"];
    [wc copyResolutions: currentDocument.resolutions];
    
    wc.sceneScaleType = currentDocument.sceneScaleType;
    
    int success = [wc runModalSheetForWindow:window];
    if (success)
    {
        if(currentDocument.currentResolution<[wc.resolutions count])
            [self setResolution:currentDocument.currentResolution];
        else
            [self setResolution:[wc.resolutions count] - 1];
        currentDocument.sceneScaleType = wc.sceneScaleType;
        currentDocument.resolutions = wc.resolutions;
        [self updateResolutionMenu];
        [self updateCanvasBorderMenu];
        currentDocument.isDirty = YES;
    }
}

- (IBAction)menuResolution:(id)sender
{
    if (!currentDocument) return;
    
    [self setResolution:(int)[sender tag]];
    [self updateCanvasBorderMenu];
}

- (IBAction)copyCustomPropSettings:(id)sender {
    [self isMenuEditCustomPropSettingsAvailable];
    [[self window] makeFirstResponder:[self window]];
    
    self.customProperties = [NSMutableArray array];
    for (CustomPropSetting* setting in self.selectedNode.customProperties) {
        [self.customProperties addObject:[setting copy]];
    }
}

- (IBAction)pastleCustomPropSettings:(id)sender {
    [self isMenuEditCustomPropSettingsAvailable];
    [[self window] makeFirstResponder:[self window]];

    [self saveUndoState];

    NSMutableArray *forRemove = [NSMutableArray array];
    NSMutableArray *customProperties = [NSMutableArray array];
    for (CustomPropSetting *setting in self.customProperties) {
        [customProperties addObject:[setting copy]];
    }
    
    for (CustomPropSetting *settingsCopy in customProperties) {
        for (CustomPropSetting *settingsNode in self.selectedNode.customProperties) {
            if ([settingsCopy.name isEqualToString:settingsNode.name]) {
                [forRemove addObject:settingsCopy];
            }
        }
    }
    
    //check for replace-merge action
    if (self.selectedNode.customProperties.count) {
        NSAlert* alert = [NSAlert alertWithMessageText:@"Object already has some properties"
                                         defaultButton:@"Merge"
                                       alternateButton:@"Cancel"
                                           otherButton:@"Replace All"
                             informativeTextWithFormat:@"Merge will only add new unique properties. Replace will remove all current properties."];
    
        [alert setAlertStyle:NSWarningAlertStyle];
        NSInteger result = [alert runModal];
        
        bool proceed = NO;
        //Merge
        if (result == NSAlertDefaultReturn) {
            proceed = YES;
            [customProperties removeObjectsInArray:forRemove];
        }
        //Cancel
        if (result == NSAlertAlternateReturn) {
            //do nothing
            //CCLOG(@"Cancel");
        }
        //Replace
        if (result == NSAlertOtherReturn) {
            proceed = YES;
            [self.selectedNode.customProperties removeAllObjects];
        }
        if (proceed) {
            for (CustomPropSetting* setting in customProperties) {
                [self.selectedNode.customProperties addObject:[setting copy]];
            }
        }
    } else {
        //object has not properties at all
        //so just add them
        for (CustomPropSetting* setting in customProperties) {
            [self.selectedNode.customProperties addObject:[setting copy]];
        }
    }
    
    [_inspectorController updateInspectorFromSelection];
}

- (IBAction)menuEditCustomPropSettings:(id)sender {

    if (![self isMenuEditCustomPropSettingsAvailable]) return;
    //fix bug with Custom Properties:
    //- start start typing/changing any value in any property
    //- right after click "Edit Custom Properties" button and change "Property name" to any, for property which was just edited value
    //- click "Done" and SBX will crash
    [[self window] makeFirstResponder:[self window]];
    
    CustomPropSettingsWindow* wc = [[CustomPropSettingsWindow alloc] initWithWindowNibName:@"CustomPropSettingsWindow"];
    [wc copySettingsForNode:self.selectedNode];
    
    int success = [wc runModalSheetForWindow:window];
    if (success)
    {
        [self saveUndoStateWillChangeProperty:@"*customPropSettings"];
        self.selectedNode.customProperties = wc.settings;
        [_inspectorController updateInspectorFromSelection];
    }
}

-(BOOL) isMenuEditCustomPropSettingsAvailable {
    if (!currentDocument) NO;
    if (self.selectedNode) NO;
    
    NSString* customClass = [self.selectedNode extraPropForKey:@"customClass"];
    if (!customClass || [customClass isEqualToString:@""])
    {
        [self modalDialogTitle:@"Custom Class Needed" message:@"To add custom properties to a node you need to use a custom class."];
        return NO;
    }
    return YES;
}

- (IBAction)menuEditClass:(id)sender
{
    if (!currentDocument) return;
    if (!self.selectedNode) return;
    if (self.selectedNode == [SceneGraph instance].rootNode) return;

    CCNode* selectedNode = self.selectedNode;
    
    NSMutableDictionary* dict = [CCBWriterInternal dictionaryFromCCObject:selectedNode];
    
    EditClassWindow* wc = [[EditClassWindow alloc] initWithWindowNibName:@"EditClassWindow"];
    wc.className = [dict objectForKey:@"baseClass"];
    wc.haveChildren = selectedNode.children.count>0;
    int success = [wc runModalSheetForWindow:window];
    if (success)
    {
        [dict setObject:wc.className forKey:@"baseClass"];
        CCNode* clipNode = [CCBReaderInternal nodeGraphFromDictionary:dict parentSize:selectedNode.parent.contentSize fileVersion:kCCBFileFormatVersion];
        [CCBReaderInternal postDeserializationFixup:clipNode];
        [self addCCObject:clipNode asChild:NO];
        [self deleteNode:selectedNode];
        [SceneGraph fixupReferences];
    }
}

/*
- (void) updateStateOriginCenteredMenu
{
    CocosScene* cs = [CocosScene cocosScene];
    BOOL centered = [cs centeredOrigin];
    
    if (centered) [menuItemStageCentered setState:NSOnState];
    else [menuItemStageCentered setState:NSOffState];
}
 */

- (IBAction) menuSetStateOriginCentered:(id)sender
{
    CocosScene* cs = [CocosScene cocosScene];
    BOOL centered = ![cs centeredOrigin];
    
    [self saveUndoState];
    [cs setStageSize:[cs stageSize] centeredOrigin:centered];
    
    //[self updateStateOriginCenteredMenu];
}

- (void) updateCanvasBorderMenu
{
    CocosScene* cs = [CocosScene cocosScene];
    int tag = [cs stageBorder];
    [CCBUtil setSelectedSubmenuItemForMenu:menuCanvasBorder tag:tag];
}

- (void) updateWarningsButton
{
    [self updateWarningsOutline];
}

- (void) updateWarningsOutline
{
    [warningHandler updateWithWarnings:projectSettings.lastWarnings];
    [self.warningTableView reloadData];
}

- (IBAction) menuSetCanvasBorder:(id)sender
{
    CocosScene* cs = [CocosScene cocosScene];
    
    int tag = (int)[sender tag];
    [cs setStageBorder:tag];
}

- (void) updateStageColor
{
    CocosScene* cs = [CocosScene cocosScene];
    int color = currentDocument.stageColor;

    [cs setStageColor: color forDocDimensionsType: currentDocument.docDimensionsType];
    
    for (NSMenuItem *item in menuItemStageColor.submenu.itemArray)
    {
        item.state = NSOffState;
    }
    
    [menuItemStageColor.submenu itemWithTag: color].state = NSOnState;
}

- (IBAction) menuSetStageColor:(id)sender
{
    [self saveUndoStateWillChangeProperty:@"*stageColor"];
    currentDocument.stageColor = [sender tag];
    [self updateStageColor];
}

- (IBAction) menuSetBgColor:(id)sender {
    SBSettings.bgLayerColor = [sender tag];
    [self updateBgColor];
}

- (void) updateBgColor {
    CocosScene* cs = [CocosScene cocosScene];
    int color = SBSettings.bgLayerColor;
    [cs setBgColor:color];
    
    for (NSMenuItem *item in menuItemBgColor.submenu.itemArray)
    {
        item.state = NSOffState;
    }
    
    [menuItemBgColor.submenu itemWithTag: color].state = NSOnState;
}

- (IBAction)menuSetMainStageColor:(id)sender {
    SBSettings.mainStageColor = [sender tag];
    [self updateMainStageColor];
}

- (void) updateMainStageColor {
    
    for (NSMenuItem *item in menuItemMainStageColor.submenu.itemArray) {
        item.state = NSOffState;
    }
    CocosScene* cs = [CocosScene cocosScene];
    int stageColor = currentDocument.stageColor;
    int mainStageColor = SBSettings.mainStageColor;
    int finalColor = (mainStageColor == -1) ? stageColor : mainStageColor;
    [cs setStageColor: finalColor forDocDimensionsType: currentDocument.docDimensionsType];
    [menuItemMainStageColor.submenu itemWithTag: mainStageColor].state = NSOnState;
}

- (IBAction) menuZoomIn:(id)sender
{
    CocosScene* cs = [CocosScene cocosScene];
    
    float maxZoom = 8;
    ResolutionSetting* res = [currentDocument.resolutions objectAtIndex:currentDocument.currentResolution];
    if(res.width!=0&&res.height!=0)
        maxZoom /= (self.projectSettings.defaultOrientation == kCCBOrientationLandscape?res.height:res.width) / 768.0;
    
    float zoom = [cs stageZoom];
    zoom *= 1.05;
    if (zoom > 8) zoom = 8;
    [cs setStageZoom:zoom];
    [self.currentDocument.stageZooms setValue:@(zoom) forKey:[NSString stringWithFormat:@"zoom_%d",self.currentDocument.currentResolution]];
}

- (IBAction) menuZoomOut:(id)sender
{
    CocosScene* cs = [CocosScene cocosScene];
    //I have levels 8000px height, zoom out please
    float minZoom = 0.013f;
    ResolutionSetting* res = [currentDocument.resolutions objectAtIndex:currentDocument.currentResolution];
    if(res.width!=0&&res.height!=0)
        minZoom /= (self.projectSettings.defaultOrientation == kCCBOrientationLandscape?res.height:res.width) / 768.0;
    
    float zoom = [cs stageZoom];
    zoom *= 1/1.05f;
    if (zoom < minZoom) zoom = minZoom;
    [cs setStageZoom:zoom];
    [self.currentDocument.stageZooms setValue:@(zoom) forKey:[NSString stringWithFormat:@"zoom_%d",self.currentDocument.currentResolution]];
}

- (IBAction) menuResetView:(id)sender
{
    CocosScene* cs = [CocosScene cocosScene];
    cs.scrollOffset = ccp(0,0);
    [cs setStageZoom:0.44];
    
    [self.currentDocument.stageZooms setValue:@(0.44) forKey:[NSString stringWithFormat:@"zoom_%d",self.currentDocument.currentResolution]];
    [self.currentDocument.stageScrollOffsets setValue:@(0) forKey:[NSString stringWithFormat:@"offset_x_%d",self.currentDocument.currentResolution]];
    [self.currentDocument.stageScrollOffsets setValue:@(0) forKey:[NSString stringWithFormat:@"offset_y_%d",self.currentDocument.currentResolution]];
}

- (IBAction) pressedToolSelection:(id)sender
{
    CocosScene* cs = [CocosScene cocosScene];
    NSSegmentedControl* sc = sender;
    
    cs.currentTool = [sc selectedSegment];
}

- (int) uniqueSequenceIdFromSequences:(NSArray*) seqs
{
    int maxId = -1;
    for (SequencerSequence* seqCheck in seqs)
    {
        if (seqCheck.sequenceId > maxId) maxId = seqCheck.sequenceId;
    }
    return maxId + 1;
}

- (IBAction)menuTimelineSettings:(id)sender
{
    if (!currentDocument) return;
    
    SequencerSettingsWindow* wc = [[SequencerSettingsWindow alloc] initWithWindowNibName:@"SequencerSettingsWindow"];
    [wc copySequences:currentDocument.sequences];
    
    int success = [wc runModalSheetForWindow:window];
    
    if (success)
    {
        // Successfully updated timeline settings
        
        // Check for deleted timelines
        for (SequencerSequence* seq in currentDocument.sequences)
        {
            BOOL foundSeq = NO;
            for (SequencerSequence* newSeq in wc.sequences)
            {
                if (seq.sequenceId == newSeq.sequenceId)
                {
                    foundSeq = YES;
                    break;
                }
            }
            if (!foundSeq)
            {
                // Sequence deleted, remove from all nodes
                [sequenceHandler deleteSequenceId:seq.sequenceId];
            }
        }
        
        // Assign id:s to new sequences
        for (SequencerSequence* seq in wc.sequences)
        {
            if (seq.sequenceId == -1)
            {
                // Find a unique id
                seq.sequenceId = [self uniqueSequenceIdFromSequences:wc.sequences];
            }
        }
    
        // Update the timelines
        currentDocument.sequences = wc.sequences;
        sequenceHandler.currentSequence = [currentDocument.sequences objectAtIndex:0];

        [animationPlaybackManager stop];
    }
}

- (IBAction)menuTimelineNew:(id)sender
{
    if (!currentDocument) return;
    
    // Create new sequence and assign unique id
    SequencerSequence* newSeq = [[SequencerSequence alloc] init];
    newSeq.name = @"Untitled Timeline";
    newSeq.sequenceId = [self uniqueSequenceIdFromSequences:currentDocument.sequences];
    
    // Add it to list
    [currentDocument.sequences addObject:newSeq];
    
    // and set it to current
    sequenceHandler.currentSequence = newSeq;

    [animationPlaybackManager stop];
}

- (IBAction)menuTimelineDuplicate:(id)sender
{
    if (!currentDocument) return;
    
    // Duplicate current timeline
    int newSeqId = [self uniqueSequenceIdFromSequences:currentDocument.sequences];
    SequencerSequence* newSeq = [sequenceHandler.currentSequence duplicateWithNewId:newSeqId];
    
    // Add it to list
    [currentDocument.sequences addObject:newSeq];
    
    // and set it to current
    sequenceHandler.currentSequence = newSeq;

    [animationPlaybackManager stop];
}

- (IBAction)menuTimelineDuration:(id)sender
{
    if (!currentDocument) return;
    
    SequencerDurationWindow* wc = [[SequencerDurationWindow alloc] initWithWindowNibName:@"SequencerDurationWindow"];
    wc.duration = sequenceHandler.currentSequence.timelineLength;
    
    int success = [wc runModalSheetForWindow:window];
    if (success)
    {
        [sequenceHandler deleteKeyframesForCurrentSequenceAfterTime:wc.duration];
        sequenceHandler.currentSequence.timelineLength = wc.duration;
        [_inspectorController updateInspectorFromSelection];
        [animationPlaybackManager stop];
    }
}

- (IBAction)menuTimelineId:(id)sender
{
    if (!currentDocument) return;
    
    SequencerIdWindow* wc = [[SequencerIdWindow alloc] initWithWindowNibName:@"SequencerIdWindow"];
    int currentSequenceId = sequenceHandler.currentSequence.sequenceId;
    wc.sequenceId = currentSequenceId;
    
    int success = [wc runModalSheetForWindow:window];
    if (success && currentSequenceId != wc.sequenceId)
    {
        for (SequencerSequence* seqCheck in currentDocument.sequences)
        {
            if (seqCheck.sequenceId == wc.sequenceId)
                return;
        }
        
        NSMutableArray *newSequences = [NSMutableArray array];
        
        SequencerSequence* newSeq = [sequenceHandler.currentSequence duplicateWithNewId:wc.sequenceId];
        newSeq.name = sequenceHandler.currentSequence.name;
        for (SequencerSequence* seq in [AppDelegate appDelegate].currentDocument.sequences)
        {
            if (seq.chainedSequenceId == sequenceHandler.currentSequence.sequenceId)
            {
                seq.chainedSequenceId = newSeq.sequenceId;
            }
            if(seq.sequenceId != sequenceHandler.currentSequence.sequenceId)
            {
                [newSequences addObject:seq];
            }
        }
        [[CocosScene cocosScene].rootNode deleteSequenceId:sequenceHandler.currentSequence.sequenceId];
        [sequenceHandler deleteSequenceId:currentSequenceId];
        [currentDocument.sequences addObject:newSeq];
        sequenceHandler.currentSequence = newSeq;
        [newSequences addObject:newSeq];
        currentDocument.sequences = newSequences;
        [animationPlaybackManager stop];
    }
}


- (IBAction) menuOpenResourceManager:(id)sender
{
    //[resManagerPanel.window setIsVisible:![resManagerPanel.window isVisible]];
}

- (void) reloadResources
{
    if (!currentDocument) return;
    
    currentDocument.projectSettings = self.projectSettings;
    
    [[CCTextureCache sharedTextureCache] removeAllTextures];
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFrames];
    FNTConfigRemoveCache();
    
    [self switchToDocument:currentDocument forceReload:YES];
    [sequenceHandler updatePropertiesToTimelinePosition];
}

- (IBAction) menuAlignToPixels:(id)sender
{
    if (!currentDocument) return;
    if (self.selectedNodes.count == 0) return;
    
    [self saveUndoStateWillChangeProperty:@"*align"];
    
    // Check if node can have children
    for (CCNode* c in self.selectedNodes)
    {
        if(c.locked)
            continue;
        
        CCPositionType positionType = [PositionPropertySetter positionTypeForNode:c prop:@"position"];
        if (positionType.xUnit != CCPositionUnitNormalized)
        {
            CGPoint pos = NSPointToCGPoint([PositionPropertySetter positionForNode:c prop:@"position"]);
            pos = ccp(roundf(pos.x), pos.y);
            [PositionPropertySetter setPosition:NSPointFromCGPoint(pos) forNode:c prop:@"position"];
            [PositionPropertySetter addPositionKeyframeForNode:c];
        }
        if (positionType.yUnit != CCPositionUnitNormalized)
        {
            CGPoint pos = NSPointToCGPoint([PositionPropertySetter positionForNode:c prop:@"position"]);
            pos = ccp(pos.x, roundf(pos.y));
            [PositionPropertySetter setPosition:NSPointFromCGPoint(pos) forNode:c prop:@"position"];
            [PositionPropertySetter addPositionKeyframeForNode:c];
        }
    }
    
    [_inspectorController refreshProperty:@"position"];
}

- (void) menuAlignObjectsCenter:(id)sender alignmentType:(int)alignmentType
{
    // Find position
    float alignmentValue = 0;
    
    for (CCNode* node in self.selectedNodes)
    {
        if (alignmentType == kCCBAlignHorizontalCenter)
        {
            alignmentValue += node.positionInPoints.x;
        }
        else if (alignmentType == kCCBAlignVerticalCenter)
        {
            alignmentValue += node.positionInPoints.y;
        }
    }
    alignmentValue = alignmentValue/self.selectedNodes.count;
    
    // Align objects
    for (CCNode* node in self.selectedNodes)
    {
        if(node.locked)
            continue;
        
        CGPoint newAbsPosition = node.positionInPoints;
        if (alignmentType == kCCBAlignHorizontalCenter)
        {
            newAbsPosition.x = alignmentValue;
        }
        else if (alignmentType == kCCBAlignVerticalCenter)
        {
            newAbsPosition.y = alignmentValue;
        }
        
        NSPoint newRelPos = [node convertPositionFromPoints:newAbsPosition type:node.positionType];
        
        //CCPositionType posType = [PositionPropertySetter positionTypeForNode:node prop:@"position"];
        //NSPoint newRelPos = [PositionPropertySetter calcRelativePositionFromAbsolute:NSPointFromCGPoint(newAbsPosition) type:posType parentSize:node.parent.contentSize];
        
        [PositionPropertySetter setPosition:newRelPos forNode:node prop:@"position"];
        [PositionPropertySetter addPositionKeyframeForNode:node];
    }
}

- (void) menuAlignObjectsEdge:(id)sender alignmentType:(int)alignmentType
{
    CGFloat x;
    CGFloat y;
    
    int nAnchor = self.selectedNodes.count - 1;
    CCNode* nodeAnchor = [self.selectedNodes objectAtIndex:nAnchor];
    
    for (int i = 0; i < self.selectedNodes.count - 1; ++i)
    {
        CCNode* node = [self.selectedNodes objectAtIndex:i];
        
        if(node.locked)
            continue;
        
        CGPoint newAbsPosition = node.position;
        
        switch (alignmentType)
        {
            case kCCBAlignLeft:
                x = nodeAnchor.positionInPoints.x
                - nodeAnchor.contentSize.width * nodeAnchor.scaleX * nodeAnchor.anchorPoint.x;
                
                newAbsPosition.x = x
                + node.contentSize.width * node.scaleX * node.anchorPoint.x;
                break;
            case kCCBAlignRight:
                x = nodeAnchor.positionInPoints.x
                + nodeAnchor.contentSize.width * nodeAnchor.scaleX * nodeAnchor.anchorPoint.x;
                
                newAbsPosition.x = x
                - node.contentSize.width * node.scaleX * node.anchorPoint.x;
                break;
            case kCCBAlignTop:
                y = nodeAnchor.positionInPoints.y
                + nodeAnchor.contentSize.height * nodeAnchor.scaleY * nodeAnchor.anchorPoint.y;
                
                newAbsPosition.y = y
                - node.contentSize.height * node.scaleY * node.anchorPoint.y;
                break;
            case kCCBAlignBottom:
                y = nodeAnchor.positionInPoints.y
                - nodeAnchor.contentSize.height * nodeAnchor.scaleY * nodeAnchor.anchorPoint.y;
                
                newAbsPosition.y = y
                + node.contentSize.height * node.scaleY * node.anchorPoint.y;
                break;
        }
        
        //CCPositionType posType = [PositionPropertySetter positionTypeForNode:node prop:@"position"];
        //NSPoint newRelPos = [PositionPropertySetter calcRelativePositionFromAbsolute:NSPointFromCGPoint(newAbsPosition) type:posType parentSize:node.parent.contentSize];
        
        NSPoint newRelPos = [node convertPositionFromPoints:newAbsPosition type:node.positionType];
        
        [PositionPropertySetter setPosition:newRelPos forNode:node prop:@"position"];
        [PositionPropertySetter addPositionKeyframeForNode:node];
    }
 }

- (void) menuAlignObjectsAcross:(id)sender alignmentType:(int)alignmentType
{
    CGFloat x;
    CGFloat cxNode;
    CGFloat xMin;
    CGFloat xMax;
    CGFloat cxTotal;
    CGFloat cxInterval;
    
    if (self.selectedNodes.count < 3)
        return;
    
    cxTotal = 0.0f;
    xMin = FLT_MAX;
    xMax = FLT_MIN;
    
    for (int i = 0; i < self.selectedNodes.count; ++i)
    {
        CCNode* node = [self.selectedNodes objectAtIndex:i];
        

        
        cxNode = node.contentSize.width * node.scaleX;
        
        x = node.positionInPoints.x - cxNode * node.anchorPoint.x;
        
        if (xMin > x)
            xMin = x;
        
        if (xMax < x + cxNode)
            xMax = x + cxNode;
        
        cxTotal += cxNode;
    }
    
    cxInterval = (xMax - xMin - cxTotal) / (self.selectedNodes.count - 1);
    
    x = xMin;
    
    NSArray* sortedNodes = [self.selectedNodes sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CCNode* lhs = obj1;
        CCNode* rhs = obj2;
        if (lhs.positionInPoints.x < rhs.position.x)
            return NSOrderedAscending;
        if (lhs.positionInPoints.x > rhs.position.x)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    for (int i = 0; i < self.selectedNodes.count; ++i)
    {
        CCNode* node = [sortedNodes objectAtIndex:i];
        
        if(node.locked)
            continue;
        
        CGPoint newAbsPosition = node.positionInPoints;
        
        cxNode = node.contentSize.width * node.scaleX;
        
        newAbsPosition.x = x + cxNode * node.anchorPoint.x;
        
        x = x + cxNode + cxInterval;
        
        //int posType = [PositionPropertySetter positionTypeForNode:node prop:@"position"];
        //NSPoint newRelPos = [PositionPropertySetter calcRelativePositionFromAbsolute:NSPointFromCGPoint(newAbsPosition) type:posType parentSize:node.parent.contentSize];
        NSPoint newRelPos = [node convertPositionFromPoints:newAbsPosition type:node.positionType];
        
        [PositionPropertySetter setPosition:newRelPos forNode:node prop:@"position"];
        [PositionPropertySetter addPositionKeyframeForNode:node];
    }
}


- (void) menuAlignObjectsDown:(id)sender alignmentType:(int)alignmentType
{
    CGFloat y;
    CGFloat cyNode;
    CGFloat yMin;
    CGFloat yMax;
    CGFloat cyTotal;
    CGFloat cyInterval;
    
    if (self.selectedNodes.count < 3)
        return;
    
    cyTotal = 0.0f;
    yMin = FLT_MAX;
    yMax = FLT_MIN;
    
    for (int i = 0; i < self.selectedNodes.count; ++i)
    {
        CCNode* node = [self.selectedNodes objectAtIndex:i];
        
        if(node.locked)
            continue;
        
        cyNode = node.contentSize.height * node.scaleY;
        
        y = node.positionInPoints.y - cyNode * node.anchorPoint.y;
        
        if (yMin > y)
            yMin = y;
        
        if (yMax < y + cyNode)
            yMax = y + cyNode;
        
        cyTotal += cyNode;
    }
    
    cyInterval = (yMax - yMin - cyTotal) / (self.selectedNodes.count - 1);
    
    y = yMin;
    
    NSArray* sortedNodes = [self.selectedNodes sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CCNode* lhs = obj1;
        CCNode* rhs = obj2;
        if (lhs.position.y < rhs.position.y)
            return NSOrderedAscending;
        if (lhs.position.y > rhs.position.y)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];

    for (int i = 0; i < self.selectedNodes.count; ++i)
    {
        CCNode* node = [sortedNodes objectAtIndex:i];
        
        CGPoint newAbsPosition = node.positionInPoints;
        
        cyNode = node.contentSize.height * node.scaleY;
        
        newAbsPosition.y = y + cyNode * node.anchorPoint.y;
        
        y = y + cyNode + cyInterval;
        
        //int posType = [PositionPropertySetter positionTypeForNode:node prop:@"position"];
        //NSPoint newRelPos = [PositionPropertySetter calcRelativePositionFromAbsolute:NSPointFromCGPoint(newAbsPosition) type:posType parentSize:node.parent.contentSize];
        NSPoint newRelPos = [node convertPositionFromPoints:newAbsPosition type:node.positionType];
        
        [PositionPropertySetter setPosition:newRelPos forNode:node prop:@"position"];
        [PositionPropertySetter addPositionKeyframeForNode:node];
    }
}

- (void) menuAlignObjectsSize:(id)sender alignmentType:(int)alignmentType
{
    /*
    CGFloat x;
    CGFloat y;
    
    int nAnchor = self.selectedNodes.count - 1;
    CCNode* nodeAnchor = [self.selectedNodes objectAtIndex:nAnchor];
 
    for (int i = 0; i < self.selectedNodes.count - 1; ++i)
    {
        CCNode* node = [self.selectedNodes objectAtIndex:i];
        
        switch (alignmentType)
        {
            case kCCBAlignSameWidth:
                x = nodeAnchor.contentSize.width * nodeAnchor.scaleX;
                if (abs(x) >= 0.0001f)
                    x /= node.contentSize.width;
                y = node.scaleY;
                break;
            case kCCBAlignSameHeight:
                x = node.scaleX;
                y = nodeAnchor.contentSize.height * nodeAnchor.scaleY;
                if (abs(y) >= 0.0001f)
                    y /= node.contentSize.height;
                break;
            case kCCBAlignSameSize:
                x = nodeAnchor.contentSize.width * nodeAnchor.scaleX;
                if (abs(x) >= 0.0001f)
                    x /= node.contentSize.width;
                y = nodeAnchor.contentSize.height * nodeAnchor.scaleY;
                if (abs(y) >= 0.0001f)
                    y /= node.contentSize.height;
                break;
        }

        int posType = [PositionPropertySetter positionTypeForNode:node prop:@"scale"];
        
        [PositionPropertySetter setScaledX:x Y:y type:posType forNode:node prop:@"scale"];
        [PositionPropertySetter addPositionKeyframeForNode:node];
    }
     */
}


- (IBAction) menuAlignObjects:(id)sender
{
    if (!currentDocument)
        return;
    
    if (self.selectedNodes.count <= 1)
        return;
    
    [self saveUndoStateWillChangeProperty:@"*align"];
    
    int alignmentType = [sender tag];
    
    switch (alignmentType)
    {
        case kCCBAlignHorizontalCenter:
        case kCCBAlignVerticalCenter:
            [self menuAlignObjectsCenter:sender alignmentType:alignmentType];
            break;
        case kCCBAlignLeft:
        case kCCBAlignRight:
        case kCCBAlignTop:
        case kCCBAlignBottom:
            [self menuAlignObjectsEdge:sender alignmentType:alignmentType];
            break;
        case kCCBAlignAcross:
            [self menuAlignObjectsAcross:sender alignmentType:alignmentType];
            break;
        case kCCBAlignDown:
            [self menuAlignObjectsDown:sender alignmentType:alignmentType];
            break;
        case kCCBAlignSameSize:
        case kCCBAlignSameWidth:
        case kCCBAlignSameHeight:
            [self menuAlignObjectsSize:sender alignmentType:alignmentType];
            break;
    }
}


- (IBAction)menuArrange:(id)sender
{
    int type = [sender tag];
    
    CCNode* node = self.selectedNode;
    CCNode* parent = node.parent;
    NSArray* siblings = [node.parent children];
    
    // Check bounds
    if ((type == kCCBArrangeSendToBack || type == kCCBArrangeSendBackward)
        && node.zOrder == 0)
    {
        NSBeep();
        return;
    }
    
    if ((type == kCCBArrangeBringToFront || type == kCCBArrangeBringForward)
        && node.zOrder == siblings.count - 1)
    {
        NSBeep();
        return;
    }
    
    if (siblings.count < 2)
    {
        NSBeep();
        return;
    }
    
    int newIndex = 0;
    
    // Bring forward / send backward
    if (type == kCCBArrangeSendToBack)
    {
        newIndex = 0;
    }
    else if (type == kCCBArrangeBringToFront)
    {
        newIndex = siblings.count -1;
    }
    else if (type == kCCBArrangeSendBackward)
    {
        newIndex = node.zOrder - 1;
    }
    else if (type == kCCBArrangeBringForward)
    {
        newIndex = node.zOrder + 1;
    }

    // Note: Deleting the node will cleanup the userObject containting the NodeInfo stuff
    // This needs to be preserved and attached again.
    id userObject = node.userObject;
    [self deleteNode:node];
    node.userObject = userObject;

    [self addCCObject:node toParent:parent atIndex:newIndex];
}

- (IBAction)menuSetEasing:(id)sender
{
    int easingType = [sender tag];
    [sequenceHandler setContextKeyframeEasingType:easingType];
    [sequenceHandler updatePropertiesToTimelinePosition];
}

- (IBAction)menuSetEasingOption:(id)sender
{
    if (!currentDocument) return;
    
    float opt = [sequenceHandler.contextKeyframe.easing.options floatValue];
    
    
    SequencerKeyframeEasingWindow* wc = [[SequencerKeyframeEasingWindow alloc] initWithWindowNibName:@"SequencerKeyframeEasingWindow"];
    wc.option = opt;
    
    int type = sequenceHandler.contextKeyframe.easing.type;
    if (type == kCCBKeyframeEasingCubicIn
        || type == kCCBKeyframeEasingCubicOut
        || type == kCCBKeyframeEasingCubicInOut)
    {
        wc.optionName = @"Rate:";
    }
    else if (type == kCCBKeyframeEasingElasticIn
             || type == kCCBKeyframeEasingElasticOut
             || type == kCCBKeyframeEasingElasticInOut)
    {
        wc.optionName = @"Period:";
    }
    
    int success = [wc runModalSheetForWindow:window];
    if (success)
    {
        float newOpt = wc.option;
        
        if (newOpt != opt)
        {
            [self saveUndoStateWillChangeProperty:@"*keyframeeasingoption"];
            sequenceHandler.contextKeyframe.easing.options = [NSNumber numberWithFloat:wc.option];
            [sequenceHandler updatePropertiesToTimelinePosition];
        }
    }
}

- (IBAction)menuCreateKeyframesFromSelection:(id)sender
{
    [_resourceCommandController createKeyFrameFromSelection:nil];
}

- (IBAction)menuNewFolder:(NSMenuItem*)sender
{
    ResourceManagerOutlineView * resManagerOutlineView = (ResourceManagerOutlineView*)outlineProject;
    sender.tag = resManagerOutlineView.selectedRow;
    
    [self newFolder:sender];
}

- (IBAction)menuNewFile:(NSMenuItem*)sender
{
    ResourceManagerOutlineView * resManagerOutlineView = (ResourceManagerOutlineView*)outlineProject;
    sender.tag = resManagerOutlineView.selectedRow;
    
    [self newDocument:sender];
}

- (IBAction)menuAlignKeyframeToMarker:(id)sender
{
    [SequencerUtil alignKeyframesToMarker];
}

- (IBAction)menuStretchSelectedKeyframes:(id)sender
{
    SequencerStretchWindow* wc = [[SequencerStretchWindow alloc] initWithWindowNibName:@"SequencerStretchWindow"];
    wc.factor = 1;
    
    int success = [wc runModalSheetForWindow:window];
    if (success)
    {
        [SequencerUtil stretchSelectedKeyframes:wc.factor];
    }
}

- (IBAction)menuReverseSelectedKeyframes:(id)sender
{
    [SequencerUtil reverseSelectedKeyframes];
}

- (IBAction)menuAddStickyNote:(id)sender
{
    CocosScene* cs = [CocosScene cocosScene];
    [cs setStageZoom:0.44];
    self.showStickyNotes = YES;
    [cs.notesLayer addNote];
}

- (NSString*) keyframePropNameFromTag:(int)tag
{
    if      (tag == 0) return @"visible";
    else if (tag == 1) return @"position";
    else if (tag == 2) return @"scale";
    else if (tag == 3) return @"rotation";
    else if (tag == 4) return @"spriteFrame";
    else if (tag == 5) return @"opacity";
    else if (tag == 6) return @"color";
    else if (tag == 7) return @"skew";
    else return NULL;
}

- (IBAction)menuAddKeyframe:(id)sender
{
    int tag = [sender tag];
    [sequenceHandler menuAddKeyframeNamed:[self keyframePropNameFromTag:tag]];
}

- (IBAction)menuCutKeyframe:(id)sender
{
    [self cut:sender];
}

- (IBAction)menuCopyKeyframe:(id)sender
{
    [self copy:sender];
}

- (IBAction)menuPasteKeyframes:(id)sender
{
    [self paste:sender];
}

- (IBAction)menuDeleteKeyframe:(id)sender
{
    [self cut:sender];
}

- (IBAction)menuJavaScriptControlled:(id)sender
{
    [self saveUndoStateWillChangeProperty:@"*javascriptcontrolled"];
    
    jsControlled = !jsControlled;
    [_inspectorController updateInspectorFromSelection];
}

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(saveDocument:)) return hasOpenedDocument;
    else if (menuItem.action == @selector(saveDocumentAs:)) return hasOpenedDocument;
    else if (menuItem.action == @selector(saveAllDocuments:)) return hasOpenedDocument;
    else if (menuItem.action == @selector(performClose:)) return hasOpenedDocument;
    else if (menuItem.action == @selector(menuCreateKeyframesFromSelection:))
    {
        return (hasOpenedDocument && [SequencerUtil canCreateFramesFromSelectedResources]);
    }
    else if (menuItem.action == @selector(menuAlignKeyframeToMarker:))
    {
        return (hasOpenedDocument && [SequencerUtil canAlignKeyframesToMarker]);
    }
    else if (menuItem.action == @selector(menuStretchSelectedKeyframes:))
    {
        return (hasOpenedDocument && [SequencerUtil canStretchSelectedKeyframes]);
    }
    else if (menuItem.action == @selector(menuReverseSelectedKeyframes:))
    {
        return (hasOpenedDocument && [SequencerUtil canReverseSelectedKeyframes]);
    }
    else if (menuItem.action == @selector(menuAddKeyframe:))
    {
        if (!hasOpenedDocument) return NO;
        if (!self.selectedNode) return NO;
        return [sequenceHandler canInsertKeyframeNamed:[self keyframePropNameFromTag:menuItem.tag]];
    }
    else if (menuItem.action == @selector(menuSetCanvasBorder:))
    {
        if (!hasOpenedDocument) return NO;
        int tag = [menuItem tag];
        if (tag == kCCBBorderNone) return YES;
        CGSize canvasSize = [[CocosScene cocosScene] stageSize];
        if (canvasSize.width == 0 || canvasSize.height == 0) return NO;
        return YES;
    }
    else if (menuItem.action == @selector(menuArrange:))
    {
        if (!hasOpenedDocument) return NO;
        return (self.selectedNode != NULL);
    }
    
    return YES;
}

- (IBAction)menuAbout:(id)sender
{
    if(!aboutWindow)
    {
        aboutWindow = [[AboutWindow alloc] initWithWindowNibName:@"AboutWindow"];
    }
    
    [[aboutWindow window] makeKeyAndOrderFront:self];
}

- (NSUndoManager*) windowWillReturnUndoManager:(NSWindow *)window
{
    return currentDocument.undoManager;
}


-(NSString*)applicationTitle
{
	return @"SpriteBuilder";
}

#pragma mark Extras / Snap

- (BOOL)readBoolValue:(NSString*)key withDefault:(BOOL)defaultValue
{
    id value = [SBUserDefaults objectForKey:key];
    if(value)
        return [value boolValue];
    else
        return defaultValue;
}

- (void)setupExtras
{
    // Default Extras 
    self.showExtras      = [self readBoolValue:SHOW_EXTRAS withDefault:YES];
    self.showGuides      = [self readBoolValue:SHOW_GUIDES withDefault:YES];
    self.showGuideGrid   = [self readBoolValue:SHOW_GUIDE_GRID withDefault:NO];
    self.showStickyNotes = [self readBoolValue:SHOW_STICKY_NOTES withDefault:YES];
    
    // Default Snap
    self.snapToggle      = [self readBoolValue:SNAP_TOGGLE withDefault:YES];
    self.snapToGuides    = [self readBoolValue:SNAP_TOGUIDES withDefault:YES];
    self.snapGrid        = [self readBoolValue:SNAP_GRID withDefault:NO];
    self.snapNode        = [self readBoolValue:SNAP_NODE withDefault:YES];
}

-(void) setShowExtras:(BOOL)showExtrasNew {
    showExtras = showExtrasNew;
    [SBUserDefaults setBool:showExtrasNew forKey:SHOW_EXTRAS];
}

-(void) setShowGuides:(BOOL)showGuidesNew {
    showGuides = showGuidesNew;
    [SBUserDefaults setBool:showGuidesNew forKey:SHOW_GUIDES];
    [[[CocosScene cocosScene] guideLayer] updateGuides];
}

-(void) setShowGuideGrid:(BOOL)showGuideGridNew {
    showGuideGrid = showGuideGridNew;
    [SBUserDefaults setBool:showGuideGridNew forKey:SHOW_GUIDE_GRID];
    if(showGuideGrid) {
        [self setSnapGrid:YES];
    }
    [[[CocosScene cocosScene] guideLayer] updateGuides];
}

-(void) setShowStickyNotes:(BOOL)showStickyNotesNew {
    showStickyNotes = showStickyNotesNew;
    [SBUserDefaults setBool:showStickyNotesNew forKey:SHOW_STICKY_NOTES];
}

-(void) setSnapToggle:(BOOL)snapToggleNew {
    snapToggle = snapToggleNew;
    [SBUserDefaults setBool:snapToggle forKey:SNAP_TOGGLE];
}

-(void) setSnapToGuides:(BOOL)snapToGuidesNew {
    snapToGuides = snapToGuidesNew;
    [SBUserDefaults setBool:snapToGuides forKey:SNAP_TOGUIDES];
}

-(void) setSnapGrid:(BOOL)snapGridNew {
    snapGrid = snapGridNew;
    [SBUserDefaults setBool:snapGrid forKey:SNAP_GRID];
}

-(void) setSnapNode:(BOOL)snapNodeNew {
    snapNode = snapNodeNew;
    [SBUserDefaults setBool:snapNode forKey:SNAP_NODE];
}

- (IBAction) menuGuideGridSettings:(id)sender
{
    if (!currentDocument) return;

    GuideGridSizeWindow* wc = [[GuideGridSizeWindow alloc] initWithWindowNibName:@"GuideGridSizeWindow"];
    
    wc.wStage = [[[CocosScene cocosScene] guideLayer] gridSize].width;
    wc.hStage = [[[CocosScene cocosScene] guideLayer] gridSize].height;
    wc.wOffset = [[[CocosScene cocosScene] guideLayer] gridOffset].x;
    wc.hOffset = [[[CocosScene cocosScene] guideLayer] gridOffset].y;
    
    int success = [wc runModalSheetForWindow:window];
    if (success)
    {
        [self saveUndoStateWillChangeProperty:@"*stageGuideSizeOffset"];
        
        CGSize newSize = CGSizeMake(wc.wStage,wc.hStage);
        
        [[[CocosScene cocosScene] guideLayer] setGridSize:newSize];
        [[[CocosScene cocosScene] guideLayer] setGridOffset:ccp(wc.wOffset,wc.hOffset)];
        [[[CocosScene cocosScene] guideLayer] buildGuideGrid];
        [[[CocosScene cocosScene] guideLayer] updateGuides];
    }
}

- (void)setCurrentDocument:(CCBDocument *)aCurrentDocument
{
    currentDocument = aCurrentDocument;
    animationPlaybackManager.enabled = aCurrentDocument != nil;
}

#pragma mark Delegate methods

- (BOOL) windowShouldClose:(id)sender
{
    if ([self hasDirtyDocument])
    {
        NSAlert* alert = [NSAlert alertWithMessageText:@"Save files before closing?"
                                         defaultButton:@"Cancel"
                                       alternateButton:@"Don't Save"
                                           otherButton:@"Save All"
                             informativeTextWithFormat:@"There are unsaved documents. If you quit now you will lose any changes you have made."];

        [alert setAlertStyle:NSWarningAlertStyle];
        NSInteger result = [alert runModal];

        if (result == NSAlertOtherReturn)
        {
            [self saveAllDocuments:nil];
            return YES;
        }

        if (result == NSAlertDefaultReturn)
        {
            return NO;
        }
    }
    NSArray* docs = [tabView tabViewItems];
    for (int i = 0; i < [docs count]; i++)
    {
        CCBDocument* doc = [(NSTabViewItem*) docs[i] identifier];
        doc.isDirty = NO;
        [doc removeBackup];
    }
    return YES;
}

- (void) windowWillClose:(NSNotification *)notification
{
    //right click in Dock on SBX app -> Quit.
    //save backup even if this option is disabled
    if ([self hasDirtyDocument]) {
        [self checkAutoSave];
    }
    
    [self.projectSettings store];
    
    [window saveMainWindowPanelsVisibility];
    [self saveOpenProjectPathToDefaults];

    [self saveOpenedDocumentsForProject];
    
    [[NSApplication sharedApplication] terminate:self];
}

-(void) saveOpenedDocumentsForProject {
    if (SBSettings.restoreOpenedDocuments && self.openedProjectFileName) {
        //save opened documents
        NSArray *docsTabs = [tabView tabViewItems];
        NSMutableArray *openedDocs = [NSMutableArray array];
        
        //notice: first element of openedDocs is currently selecteded doc, string
        CCBDocument *doc = [tabView.selectedTabViewItem identifier];
        if (doc) {
            [openedDocs addObject:doc.filePath];
            for (int i = 0; i < docsTabs.count; i++) {
                CCBDocument *doc = [(NSTabViewItem*) docsTabs[i] identifier];
                [openedDocs addObject:doc.filePath];
            }
        }
        NSMutableDictionary *openedDocuments = [SBSettings.openedDocuments mutableCopy];
        [openedDocuments setObject:openedDocs forKey:self.openedProjectFileName];
        SBSettings.openedDocuments = openedDocuments;
        
        [SBSettings save];
    }
}

- (void)saveOpenProjectPathToDefaults
{
    NSString *projectPath = @"";
    if (projectSettings) {
		projectPath = projectSettings.projectPath;
		projectPath = [projectPath stringByDeletingLastPathComponent];
        [SBUserDefaults setObject:projectPath forKey:LAST_OPENED_PROJECT_PATH];
	}
    else
    {
        [SBUserDefaults removeObjectForKey:LAST_OPENED_PROJECT_PATH];
    }
    [SBUserDefaults synchronize];
}

- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    static float minWidth = 1060.0f;
    static float minHeight = 500.0f;
    [splitHorizontalView setNeedsLayout:YES];
    return NSSizeFromCGSize(
                CGSizeMake(
                        frameSize.width<minWidth ? minWidth:frameSize.width,
                        frameSize.height<minHeight ? minHeight:frameSize.height)
    );
}

- (IBAction) menuQuit:(id)sender
{
    if ([self windowShouldClose:(NSWindow*)self])
    {
		[self.projectSettings store];
        [[NSApplication sharedApplication] terminate:self];
    }
}


- (IBAction)reportBug:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/newnon/SpriteBuilderX/issues"]];
}
- (IBAction)menuHiddenNode:(id)sender {
}

- (IBAction)visitCommunity:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://discuss.cocos2d-x.org"]];
}

#pragma mark Debug

- (IBAction) debug:(id)sender
{
    NSLog(@"DEBUG");
    
    [[ResourceManager sharedManager] debugPrintDirectories];
}

- (NSString*)getPathOfMenuItem:(NSMenuItem*)item
{
    NSOutlineView* outlineView = [AppDelegate appDelegate].outlineProject;
    NSUInteger idx = [item tag];
	
	NSString * fullpath;
	
	id row = [outlineView itemAtRow:idx];
	if([row isKindOfClass:[RMDirectory class]])
	{
		fullpath = [row dirPath];
	}
	else if([row isKindOfClass:[RMResource class]])
	{
		fullpath = [row filePath];
	}

    
    // if it doesn't exist, peek inside "resources-auto" (only needed in the case of resources, which has a different visual
    // layout than what is actually on the disk).
    // Should probably be removed and pulled into [RMResource filePath]
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullpath] == NO)
    {
        NSString* filename = [fullpath lastPathComponent];
        NSString* directory = [fullpath stringByDeletingLastPathComponent];
        fullpath = [NSString pathWithComponents:[NSArray arrayWithObjects:directory, @"resources-auto", filename, nil]];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullpath] == NO) {
        return nil;
    }
    
    return fullpath;
}


@end
