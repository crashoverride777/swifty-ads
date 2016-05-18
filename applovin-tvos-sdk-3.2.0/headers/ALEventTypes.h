//
//  ALEventTypes.h
//  sdk
//
//  Created by Matt Szaro on 7/15/15.
//
//

#import "ALAnnotations.h"

#ifndef ALEventTypes_h
#define ALEventTypes_h

/**
 * @name Authentication Events
 */

/**
 * Event signifying that the user logged in to an existing account.
 *
 * Suggested parameters: kALEventParameterUserAccountIdentifierKey
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserLoggedIn;

/**
 * Event signifying that the finished a registration flow and created a new account.
 *
 * Suggested parameters: kALEventParameterUserAccountIdentifierKey
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserCreatedAccount;

/**
 * @name Content Events
 */

/**
 * Event signifying that the user viewed a specific piece of content.
 *
 * For views of saleable products, it is preferred you pass kALEventTypeUserViewedProduct.
 *
 * Suggested parameters: kALEventParameterContentIdentifierKey.
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserViewedContent;

/**
 * Event signifying that the user executed a search query.
 *
 * Suggested parameters: kALEventParameterSearchQueryKey
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserExecutedSearch;

/**
 * @name Gaming Events
 */

/**
 * Event signifying that the user completed a tutorial or introduction sequence.
 *
 * Suggested parameters: None.
 */
extern NSString* __alnonnull const kALEventTypeUserCompletedTutorial;

/**
 * Event signifying that the user completed a given level or game sequence.
 *
 * Suggested parameters: kALEventParameterCompletedLevelKey
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserCompletedLevel;

/**
 * Event signifying that the user completed (or "unlocked") a particular achievement.
 *
 * Suggested parameters: kALEventParameterCompletedAchievementKey
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserCompletedAchievement;

/**
 * Event signifying that the user spent virtual currency on an in-game purchase.
 *
 * Suggested parameters: kALEventParameterVirtualCurrencyAmountKey
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserSpentVirtualCurrency;

/**
 * @name Commerce Events
 */

/**
 * Event signifying that the user viewed a specific piece of content.
 *
 * For general content, e.g. not saleable products, it is preferred you pass kALEventTypeUserViewedContent.
 *
 * Suggested parameters: kALEventParameterProductIdentifierKey.
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserViewedProduct;

/**
 * Event signifying that the user added a product/item to their shopping cart.
 *
 * Suggested parameters: kALEventParameterProductIdentifierKey
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserAddedItemToCart;

/**
 * Event signifying that the user added a product/item to their wishlist.
 *
 * Suggested parameters: kALEventParameterProductIdentifierKey
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserAddedItemToWishlist;

/**
 * Event signifying that the user provided payment information, such as a credit card number.
 *
 * Suggested parameters: None.
 * Please DO NOT pass us any personally identifiable information (PII) or financial/payment information.
 */
extern NSString* __alnonnull const kALEventTypeUserProvidedPaymentInformation;

/**
 * Event signifying that the user began a check-out / purchase process.
 *
 * Suggested parameters: kALEventParameterProductIdentifierKey, kALEventParameterRevenueAmountKey and kALEventParameterRevenueCurrencyKey.
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserBeganCheckOut;

/**
 * Event signifying that the user completed a check-out / purchase.
 *
 * Suggested parameters: kALEventParameterCheckoutTransactionIdentifierKey, kALEventParameterProductIdentifierKey, kALEventParameterRevenueAmountKey and kALEventParameterRevenueCurrencyKey.
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserCompletedCheckOut;

/**
 * Event signifying that the user completed an iTunes in-app purchase using StoreKit.
 *
 * Note that this event implies an in-app content purchase; for purchases of general products completed using Apple Pay, use kALEventTypeUserCompletedCheckOut instead.
 *
 * Suggested parameters: kALEventParameterProductIdentifierKey, kALEventParameterStoreKitTransactionIDKey, kALEventParamterStoreKitReceiptKey, kALEventParameterRevenueAmountKey, kALEventParameterRevenueCurrencyKey
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserCompletedInAppPurchase;

/**
 * Event signifying that the user has created a reservation or other date-specific event.
 *
 * Suggested parameters: kALEventParameterProductIdentifierKey, kALEventParameterReservationStartDateKey and kALEventParameterReservationEndDateKey
 * We recommend you pass these key-value pairs to trackEvent:parameters:.
 */
extern NSString* __alnonnull const kALEventTypeUserCreatedReservation;

/**
 * @name Social Events
 */

/**
 * Event signifying that the user sent an invitation to use your app to a friend.
 *
 * Suggested parameters: None.
 */
extern NSString* __alnonnull const kALEventTypeUserSentInvitation;

/**
 * Event signifying that the user shared a link or deep-link to some content within your app.
 *
 * Suggested parameters: None.
 */
extern NSString* __alnonnull const kALEventTypeUserSharedLink;

/**
 * @name Event Parameters
 */

/**
 * Dictionary key for trackEvent:parameters: which represents the username or account ID of the user. Expects corresponding value of type NSString.
 */
extern NSString* __alnonnull const kALEventParameterUserAccountIdentifierKey;

/**
 * Dictionary key for trackEvent:parameters: which identifies a particular piece of content viewed by the user.  Expects corresponding value of type NSString.
 *
 * This could be something like a section title, or even a name of a view controller.
 * For views of particular products, it is preferred you pass an SKU under kALEventParameterProductIdentifierKey.
 */
extern NSString* __alnonnull const kALEventParameterContentIdentifierKey;

/**
 * Dictionary key for trackEvent:parameters: which represents a search query executed by the user.  Expects corresponding value of type NSString.
 *
 * In most cases the text entered into a UISearchBar is what you'd want to provide.
 */
extern NSString* __alnonnull const kALEventParameterSearchQueryKey;

/**
 * Dictionary key for trackEvent:parameters: which represents an identifier of the level the user has just completed.  Expects corresponding value of type NSString.
 */
extern NSString* __alnonnull const kALEventParameterCompletedLevelKey;

/**
 * Dictionary key for trackEvent:parameters: which represents an identifier of the achievement the user has just completed/unlocked.  Expects corresponding value of type NSString.
 */
extern NSString* __alnonnull const kALEventParameterCompletedAchievementKey;

/**
 * Dictionary key for trackEvent:parameters: which represents the amount of virtual currency that a user spent on an in-game purchase.  Expects corresponding value of type NSNumber.
 */
extern NSString* __alnonnull const kALEventParameterVirtualCurrencyAmountKey;

/**
 * Dictionary key for trackEvent:parameters: which represents the name of the virtual currency that a user spent on an in-game purchase.  Expects corresponding value of type NSString.
 */
extern NSString* __alnonnull const kALEventParameterVirtualCurrencyNameKey;

/**
 * Dictionary key for trackEvent:parameters: which identifies a particular product.  Expects corresponding value of type NSString.
 *
 * This could be something like a product name, SKU or inventory ID.
 * For non-product content, like tracking uses of particular view controllers, it is preferred you pass kALEventParameterContentIdentifierKey instead.
 */
extern NSString* __alnonnull const kALEventParameterProductIdentifierKey;

/**
 * Dictionary key for trackEvent:parameters: which represents the amount of revenue generated by a purchase event.  Expects corresponding value of type NSNumber.
 */
extern NSString* __alnonnull const kALEventParameterRevenueAmountKey;

/**
 * Dictionary key for trackEvent:parameters: which represents the currency of the revenue event.  Expects corresponding value of type NSString.
 *
 * Ideally this should be an ISO 4217 3-letter currency code (for instance, USD, EUR, GBP...)
 */
extern NSString* __alnonnull const kALEventParameterRevenueCurrencyKey;

/**
 * Dictionary key for trackEvent:parameters: which represents a unique identifier for the current checkout transaction.  Expects corresponding value of type NSString.
 */
extern NSString* __alnonnull const kALEventParameterCheckoutTransactionIdentifierKey;

/**
 * Dictionary key for trackEvent:parameters: which represents the StoreKit transaction ID associated with the revenue keys.  Expects corresponding value of type NSString.
 *
 * This identifier should match the value of the transactionIdentifier property of SKPaymentTransaction.
 */
extern NSString* __alnonnull const kALEventParameterStoreKitTransactionIdentifierKey;

/**
 * Dictionary key for trackEvent:parameters: which represents the StoreKit receipt associated with the revenue keys.  Expects corresponding value of type NSData.
 *
 * The receipt can be collected as such: NSData* receipt = [NSData dataWithContentsOfURL: [[NSBundle mainBundle] appStoreReceiptURL]];
 */
extern NSString* __alnonnull const kALEventParameterStoreKitReceiptKey;

/**
 * Dictionary key for trackEvent:parameters: which represents the start date of a reservation.  Expects corresponding value of type NSDate.
 */
extern NSString* __alnonnull const kALEventParameterReservationStartDateKey;

/**
 * Dictionary key for trackEvent:parameters: which represents the end date of a reservation.  Expects corresponding value of type NSDate.
 *
 * If a reservation does not span multiple days, you can submit only kALEventParameterReservationStartDateKey and ignore this parameter.
 */
extern NSString* __alnonnull const kALEventParameterReservationEndDateKey;

#endif
