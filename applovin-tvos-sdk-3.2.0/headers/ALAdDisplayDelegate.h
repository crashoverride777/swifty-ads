//
//  ALAdDisplayDelegate.h
//  sdk
//
//  Created by Basil on 3/23/12.
//  Copyright (c) 2013, AppLovin Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIView.h>
#import "ALAnnotations.h"

#import "ALAd.h"
/**
 * This protocol defines a listener for ad display events. 
 */
@class ALHtmlAdView;
@protocol ALAdDisplayDelegate <NSObject>

/**
 * This method is invoked when the ad is displayed in the view.
 *
 * This method is invoked on the main UI thread.
 * 
 * @param ad     Ad that was just displayed. Will not be nil.
 * @param view   Ad view in which the ad was displayed. Will not be nil.
 */
-(void) ad: (alnonnull ALAd *) ad wasDisplayedIn: (alnonnull UIView *) view;

/**
 * This method is invoked when the ad is hidden from in the view.
 * This occurs when the user "X's" out of an interstitial, or when a banner rotates.
 *
 * This method is invoked on the main UI thread.
 * 
 * @param ad     Ad that was just hidden. Will not be nil.
 * @param view   Ad view in which the ad was hidden. Will not be nil.
 */
-(void) ad: (alnonnull ALAd *) ad wasHiddenIn: (alnonnull UIView *) view;

/**
 * This method is invoked when the ad is clicked from in the view.
 * 
 * This method is invoked on the main UI thread.
 *
 * @param ad     Ad that was just clicked. Will not be nil.
 * @param view   Ad view in which the ad was hidden. Will not be nil.
 */
-(void) ad: (alnonnull ALAd *) ad wasClickedIn: (alnonnull UIView *) view;

@end
