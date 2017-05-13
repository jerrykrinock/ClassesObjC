#import "SSYNoVoiceOverControls.h"

@implementation SSYNoVoiceOverImageView

- (void)awakeFromNib {
    self.cell.accessibilityElement = NO;
}

@end


@implementation SSYNoVoiceOverButton

- (void)awakeFromNib {
    self.cell.accessibilityElement = NO;
}

@end


@implementation SSYNoVoiceOverTextField

- (void)awakeFromNib {
    self.cell.accessibilityElement = NO;
}

@end

