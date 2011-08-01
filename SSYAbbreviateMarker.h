#import <Cocoa/Cocoa.h>

/*!
 @brief    This transformer DOES NOT WORK when used in an IB binding
 because, possibly, the placeholder substitutions specified in Interface
 Builder get substituted in before the value transformer, or something
 like that.   DO NOT USE THIS CLASS.
 
 A transformer which replaces Selection Marker constants:
 NSNoSelectionMarker or nil, NSMultipleValuesMarker, and NSNotApplicableMarker.
 Transformed values are: an em dash, three bullets, and a thick "X", respectively.
 
 @details  Use this in text fields that are not wide enough fit the
 full text such as the localized strings of "Multiple Selection",
 "No Selection" or "Not Applicable".
 */
@interface SSYAbbreviateMarker : NSValueTransformer {
}

@end
