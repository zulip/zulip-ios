//
//  SidebarStreamCell.m
//  Zulip
//
//  Created by Leonardo Franchi on 7/30/13.
//
//

#import "SidebarStreamCell.h"
#import "ZulipAppDelegate.h"
#import "ZulipAPIController.h"
#import "UnreadManager.h"

#import "UIColor+HexColor.h"
#import "UIView+Layout.h"
#import <FontAwesomeKit/FAKFontAwesome.h>

@interface SidebarStreamCell ()
@end

@implementation SidebarStreamCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.stream = nil;
    }
    return self;
}

- (void)setShortcut:(SIDEBAR_SHORTCUTS)shortcut
{
    _shortcut = shortcut;
    NarrowOperators *op = [[NarrowOperators alloc] init];

    switch (shortcut) {
        case HOME:
        {
            // Magic to go  back to the main view
            [op setInHomeView];
            UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"home" ofType:@"png"]];
            self.gravatar.image = image;
            break;
        }
        case PRIVATE_MESSAGES:
        {
            [op setPrivateMessages];

            UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"user" ofType:@"png"]];
            self.gravatar.image = image;
            break;
        }
        case AT_MENTIONS:
        {
            [op setMentions];
            FAKFontAwesome *tagIcon = [FAKFontAwesome tagIconWithSize:self.gravatar.height];
            self.gravatar.image = [tagIcon imageWithSize:self.gravatar.size];
            break;
        }
        default:
            break;
    }

    self.name.text = [op title];

    _narrow = op;

    NSDictionary *unread_counts = [[[ZulipAPIController sharedInstance] unreadManager] unreadCounts];
    [self setUnreadCount:unread_counts];
}

- (void)setStream:(ZSubscription *)subscription
{
    _shortcut = STREAM;
    _stream = subscription;

    NarrowOperators *op = [[NarrowOperators alloc] init];
    [op addStreamNarrow:subscription.name];
    _narrow = op;

    CGFloat size = CGRectGetHeight(self.gravatar.bounds);
    self.gravatar.image = [self streamColorSwatchWithSize:size andColor:subscription.color];

    NSDictionary *unread_counts = [[[ZulipAPIController sharedInstance] unreadManager] unreadCounts];
    [self setUnreadCount:unread_counts];

    self.name.text = [op title];
    [self setBackgroundIfCurrent];
}

- (void)setCount:(int)count
{
    if (count > 0) {
        self.unread.text = [NSString stringWithFormat:@"%i", count];
    } else {
        self.unread.text = @"";
    }
}

- (void)setBackgroundIfCurrent
{
    ZulipAppDelegate *delegate = (ZulipAppDelegate *)[[UIApplication sharedApplication] delegate];

    if ([[delegate currentNarrow] isEqual:self.narrow]) {
        // This is the current narrow, highlight it
        self.backgroundColor = [UIColor colorWithHexString:@"#CCD6CC" defaultColor:[UIColor grayColor]];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
}

- (void)setUnreadCount:(NSDictionary *)unreadCounts
{
    int count = 0;
    if (self.narrow.isHomeView) {
        if ([unreadCounts objectForKey:@"home"]) {
            count = [[unreadCounts objectForKey:@"home"] intValue];
        }
    } else if (self.narrow.isPrivateMessages) {
        if ([unreadCounts objectForKey:@"pms"]) {
            count = [[unreadCounts objectForKey:@"pms"] intValue];
        }
    } else {
        if ([unreadCounts objectForKey:@"streams"]) {
            NSDictionary *streams = [unreadCounts objectForKey:@"streams"];
            if ([streams objectForKey:self.stream.name]) {
                count = [[streams objectForKey:self.stream.name] intValue];
            }
        }
    }
    [self setCount:count];
}

#pragma mark - Drawing Methods

- (UIImage *)streamColorSwatchWithSize:(int)height andColor:(NSString *)colorRGB
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, height), NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
	UIGraphicsPushContext(context);

    CGRect bounds = CGRectMake(0, 0, height, height);
    CGContextAddEllipseInRect(context, bounds);
    CGContextClip(context);

    UIColor *color = [UIColor colorWithHexString:colorRGB defaultColor:[UIColor grayColor]];
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, bounds);

    UIGraphicsPopContext();
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

    return result;
}

@end
