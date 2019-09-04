#import "RNAppTour.h"
#import <React/RCTEventDispatcher.h>

NSString *const onStartShowStepEvent = @"onStartShowCaseEvent";
NSString *const onShowSequenceStepEvent = @"onShowSequenceStepEvent";
NSString *const onFinishShowStepEvent = @"onFinishSequenceEvent";

@implementation MutableOrderedDictionary {
@protected
    NSMutableArray *_values;
    NSMutableOrderedSet *_keys;
}

- (instancetype)init {
    if ((self = [super init])) {
        _values = NSMutableArray.new;
        _keys = NSMutableOrderedSet.new;
    }
    return self;
}

- (NSUInteger)count {
    return _keys.count;
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (NSEnumerator *)keyEnumerator {
    return _keys.objectEnumerator;
}

- (void)removeObjectForKey:(id)key {
    [_values removeObjectAtIndex:[_keys indexOfObject: key]];
    [_keys removeObject:key];
}

- (id)objectForKey:(id)key {
    NSUInteger index = [_keys indexOfObject:key];
    if (index != NSNotFound){
        return _values[index];
    }
    return nil;
}


- (void)setObject:(id)object forKey:(id)key {
    NSUInteger index = [_keys indexOfObject:key];
    if (index != NSNotFound) {
        _values[index] = object;
    } else {
        [_keys addObject:key];
        [_values addObject:object];
    }
}

@end

@implementation RNAppTour

@synthesize delegate;

@synthesize bridge = _bridge;

- (id)init {
    self = [super init];
    if (self) {
        targets = [[MutableOrderedDictionary alloc] init];
    }

    return self;
}

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(ShowSequence:(NSArray *)views props:(NSDictionary *)props)
{
    bool tourStarted = false;
    if (targets == nil || [[targets allKeys] count] <= 0) {
        targets = [[MutableOrderedDictionary alloc] init];
    } else {
        for (NSNumber *view in views) {
            if (![targets objectForKey: [view stringValue]]) {
                tourStarted = true;
            }
        }
    }

    for (NSNumber *view in views) {
        [targets setObject:[props objectForKey: [view stringValue]] forKey: [view stringValue]];
    }

    if (tourStarted == true) return;
    if ([[targets allKeys] count] <= 0) return;
    
    NSString *showTargetKey = [ [targets allKeys] objectAtIndex: 0];
    [self ShowFor:[NSNumber numberWithLongLong:[showTargetKey longLongValue]] props:[targets objectForKey:showTargetKey] ];
}

RCT_EXPORT_METHOD(ShowFor:(nonnull NSNumber *)view props:(NSDictionary *)props)
{
    MaterialShowcase *materialShowcase = [self generateMaterialShowcase:view props:props];

    [materialShowcase showWithAnimated:true completion:^() {
        [self.bridge.eventDispatcher sendDeviceEventWithName:onStartShowStepEvent body:@{@"start_step": @YES}];
    }];
}

- (MaterialShowcase *)generateMaterialShowcase:(NSNumber *)view props:(NSDictionary *)props {

    MaterialShowcase *materialShowcase = [[MaterialShowcase alloc] init];
    UIView *target = [self.bridge.uiManager viewForReactTag: view];

    NSString *title = [props objectForKey: @"title"];
    NSString *description = [props objectForKey: @"description"];

    // Background
    UIColor *backgroundPromptColor;
    NSString *backgroundPromptColorValue = [props objectForKey:@"backgroundPromptColor"];
    if (backgroundPromptColorValue != nil) {
        backgroundPromptColor = [self colorWithHexString: backgroundPromptColorValue];
    }
    if (backgroundPromptColor != nil) {
        [materialShowcase setBackgroundColor: backgroundPromptColor];
    }

    if ([props objectForKey:@"backgroundPrompAlpha"] != nil) {
        float backgroundPrompAlphaValue = [[props objectForKey:@"backgroundPrompAlpha"] floatValue];
        if (backgroundPrompAlphaValue >= 0.0 && backgroundPrompAlphaValue <= 1.0) {
            [materialShowcase setBackgroundPromptColorAlpha:backgroundPrompAlphaValue];
        }
    }

    // Target
    UIColor *outerCircleColor;
    UIColor *targetCircleColor;
    NSString *outerCircleColorValue = [props objectForKey:@"outerCircleColor"];
    if (outerCircleColorValue != nil) {
        outerCircleColor = [self colorWithHexString: outerCircleColorValue];
    }
    NSString *targetCircleColorValue = [props objectForKey:@"targetCircleColor"];
    if (targetCircleColorValue != nil) {
        targetCircleColor = [UIColor clearColor];
    }


    if (outerCircleColor != nil) {
        target.tintColor = outerCircleColor;
        [materialShowcase setTargetTintColor: outerCircleColor];
    } if (targetCircleColor != nil) {
        [materialShowcase setTargetHolderColor: targetCircleColor];
    }

    if ([props objectForKey:@"targetRadius"] != nil) {
        float targetRadiusValue = [[props objectForKey:@"targetRadius"] floatValue];
        if (targetRadiusValue >= 0) {
            [materialShowcase setTargetHolderRadius: targetRadiusValue];
        }
    }

    if ([props objectForKey:@"cancelable"] != nil) {
        BOOL *cancelable = [[props objectForKey:@"cancelable"] boolValue];
        [materialShowcase setIsTapRecognizerForTargetView: !cancelable];
    }

    // Text
    UIColor *titleTextColor;
    UIColor *descriptionTextColor;
    //    showcase.primaryTextFont = UIFont.boldSystemFont(ofSize: primaryTextSize)
    //    showcase.secondaryTextFont = UIFont.systemFont(ofSize: secondaryTextSize)

    NSString *titleTextColorValue = [props objectForKey:@"titleTextColor"];
    if (titleTextColorValue != nil) {
        titleTextColor = [self colorWithHexString:titleTextColorValue];
    }

    NSString *descriptionTextColorValue = [props objectForKey:@"descriptionTextColor"];
    if (descriptionTextColorValue != nil) {
        descriptionTextColor = [self colorWithHexString:descriptionTextColorValue];
    }

    [materialShowcase setPrimaryText: title];
    [materialShowcase setSecondaryText: description];

    if (titleTextColor != nil) {
        [materialShowcase setPrimaryTextColor: titleTextColor];
    } if (descriptionTextColor != nil) {
        [materialShowcase setSecondaryTextColor: descriptionTextColor];
    }

    float titleTextSizeValue = [[props objectForKey:@"titleTextSize"] floatValue];
    float descriptionTextSizeValue = [[props objectForKey:@"descriptionTextSize"] floatValue];
    if (titleTextSizeValue > 0) {
        [materialShowcase setPrimaryTextSize: titleTextSizeValue];
    } if (descriptionTextSizeValue > 0) {
        [materialShowcase setSecondaryTextSize: descriptionTextSizeValue];
    }

    NSString *titleTextAlignmentValue = [props objectForKey:@"titleTextAlignment"];
    NSString *descriptionTextAlignmentValue = [props objectForKey:@"descriptionTextAlignment"];
    if (titleTextAlignmentValue != nil) {
        NSTextAlignment* titleTextAlignment = [self getTextAlignmentByString:titleTextAlignmentValue];
        [materialShowcase setSecondaryTextAlignment: titleTextAlignment];
    } if (descriptionTextAlignmentValue != nil) {
        NSTextAlignment* descriptionTextAlignment = [self getTextAlignmentByString:descriptionTextAlignmentValue];
        [materialShowcase setSecondaryTextAlignment: descriptionTextAlignment];
    }

    // Animation
    float aniComeInDurationValue = [[props objectForKey:@"aniComeInDuration"] floatValue]; // second unit
    float aniGoOutDurationValue = [[props objectForKey:@"aniGoOutDuration"] floatValue]; // second unit
    if (aniGoOutDurationValue > 0) {
        [materialShowcase setAniComeInDuration: aniComeInDurationValue];
    } if (aniGoOutDurationValue > 0) {
        [materialShowcase setAniGoOutDuration: aniGoOutDurationValue];
    }

    UIColor *aniRippleColor;
    NSString *aniRippleColorValue = [props objectForKey:@"aniRippleColor"];
    if (aniRippleColorValue != nil) {
        aniRippleColor = [self colorWithHexString: aniRippleColorValue];
    } if (aniRippleColor != nil) {
        [materialShowcase setAniRippleColor: aniRippleColor];
    }


    if ([props objectForKey:@"aniRippleAlpha"] != nil) {
        float aniRippleAlphaValue = [[props objectForKey:@"aniRippleAlpha"] floatValue];
        if (aniRippleAlphaValue >= 0.0 && aniRippleAlphaValue <= 1.0) {
            [materialShowcase setAniRippleAlpha: aniRippleAlphaValue];
        }
    }

    float aniRippleScaleValue = [[props objectForKey:@"aniRippleScale"] floatValue];
    if (aniRippleScaleValue > 0) {
        [materialShowcase setAniRippleScale:aniRippleScaleValue];
    }

    [materialShowcase setTargetViewWithView: target];
    [materialShowcase setDelegate: (id)self];

    return materialShowcase;
}


- (void)showCaseWillDismissWithShowcase:(MaterialShowcase *)materialShowcase didTapTarget:(bool)didTapTarget {
    NSLog(@"");
}
- (void)showCaseDidDismissWithShowcase:(MaterialShowcase *)materialShowcase didTapTarget:(bool)didTapTarget {
    NSLog(@"");
    
    NSArray *targetKeys = [targets allKeys];
    if (targetKeys.count <= 0) {
        return;
    }
    
    NSString *removeTargetKey = [targetKeys objectAtIndex: 0];
    [targets removeObjectForKey: removeTargetKey];
    
    NSMutableArray *viewIds = [[NSMutableArray alloc] init];
    NSMutableDictionary *props = [[NSMutableDictionary alloc] init];
    
    if (targetKeys.count <= 1) {
        [self.bridge.eventDispatcher sendDeviceEventWithName:onFinishShowStepEvent body:@{@"finish": @YES}];
    }
    else {
        [self.bridge.eventDispatcher sendDeviceEventWithName:onShowSequenceStepEvent body:@{@"next_step": @YES}];
    }
    
    for (NSString *view in [targets allKeys]) {
        [viewIds addObject: [NSNumber numberWithLongLong:[view longLongValue]]];
        [props setObject:(NSDictionary *)[targets objectForKey: view] forKey:view];
    }
    
    if ([viewIds count] > 0) {
        [self ShowSequence:viewIds props:props];
    }
}


- (NSTextAlignment*) getTextAlignmentByString: (NSString*) strAlignment {
    if (strAlignment == nil) {
        return NSTextAlignmentLeft; // default is left
    }
    
    NSString *lowCaseString = [strAlignment lowercaseString];
    if ([lowCaseString isEqualToString:@"left"]) {
        return NSTextAlignmentLeft;
    } if ([lowCaseString isEqualToString:@"right"]) {
        return NSTextAlignmentRight;
    } if ([lowCaseString isEqualToString:@"center"]) {
        return NSTextAlignmentCenter;
    } if ([lowCaseString isEqualToString:@"justify"]) {
        return NSTextAlignmentJustified;
    }
    
    return NSTextAlignmentLeft;
}

- (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

- (UIColor *) colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            return nil;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}


@end
