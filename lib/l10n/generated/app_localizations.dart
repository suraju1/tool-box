import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Toolucs'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @give.
  ///
  /// In en, this message translates to:
  /// **'Give'**
  String get give;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @take.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get take;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @themes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themes;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @savePreference.
  ///
  /// In en, this message translates to:
  /// **'Save preference'**
  String get savePreference;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPosts;

  /// No description provided for @myTrades.
  ///
  /// In en, this message translates to:
  /// **'My Trades'**
  String get myTrades;

  /// No description provided for @myAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddresses;

  /// No description provided for @mySubscription.
  ///
  /// In en, this message translates to:
  /// **'My Subscription'**
  String get mySubscription;

  /// No description provided for @faqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqs;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @nearbyItems.
  ///
  /// In en, this message translates to:
  /// **'Nearby Items'**
  String get nearbyItems;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchWhatYouWantToGive.
  ///
  /// In en, this message translates to:
  /// **'Search what you want to give'**
  String get searchWhatYouWantToGive;

  /// No description provided for @searchWhatYouWantToTake.
  ///
  /// In en, this message translates to:
  /// **'Search what you want to take'**
  String get searchWhatYouWantToTake;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @savedProfiles.
  ///
  /// In en, this message translates to:
  /// **'Saved Profiles'**
  String get savedProfiles;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @postType.
  ///
  /// In en, this message translates to:
  /// **'Post Type'**
  String get postType;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @unhideAllPosts.
  ///
  /// In en, this message translates to:
  /// **'Unhide All Posts'**
  String get unhideAllPosts;

  /// No description provided for @allHiddenPostsVisible.
  ///
  /// In en, this message translates to:
  /// **'All hidden posts are now visible'**
  String get allHiddenPostsVisible;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @useDeviceTheme.
  ///
  /// In en, this message translates to:
  /// **'Use device theme'**
  String get useDeviceTheme;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get hindi;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी (Marathi)'**
  String get marathi;

  /// No description provided for @selectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategoriesAvailable;

  /// No description provided for @showItemsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Show items near you'**
  String get showItemsNearYou;

  /// No description provided for @areYouSureYouWant.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouWant;

  /// No description provided for @introducing.
  ///
  /// In en, this message translates to:
  /// **'— INTRODUCING —'**
  String get introducing;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @chooseYourPreferredAppThemenyou.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred app theme.\\nYou can also change this later from your profile'**
  String get chooseYourPreferredAppThemenyou;

  /// No description provided for @markThisPerson.
  ///
  /// In en, this message translates to:
  /// **'Mark This Person?'**
  String get markThisPerson;

  /// No description provided for @optionalReview.
  ///
  /// In en, this message translates to:
  /// **'Optional Review'**
  String get optionalReview;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @yourChatsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your chats will appear here once you are logged in.'**
  String get yourChatsWillAppearHere;

  /// No description provided for @noChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChatsYet;

  /// No description provided for @thisChatStaysOnFor.
  ///
  /// In en, this message translates to:
  /// **'• This Chat stays on for next 72 hours.'**
  String get thisChatStaysOnFor;

  /// No description provided for @doNotCheatNegativeRemarks.
  ///
  /// In en, this message translates to:
  /// **'• Do Not cheat, Negative remarks stays on your profile forever.'**
  String get doNotCheatNegativeRemarks;

  /// No description provided for @goodLuckHappyInnovation.
  ///
  /// In en, this message translates to:
  /// **'• Good Luck, Happy Innovation!.'**
  String get goodLuckHappyInnovation;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @noPostsFoundMatchingYour.
  ///
  /// In en, this message translates to:
  /// **'No posts found matching your filters'**
  String get noPostsFoundMatchingYour;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @viewOffers.
  ///
  /// In en, this message translates to:
  /// **'View Offers'**
  String get viewOffers;

  /// No description provided for @verifiedUser.
  ///
  /// In en, this message translates to:
  /// **'Verified User'**
  String get verifiedUser;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get savedAddresses;

  /// No description provided for @profileAddress.
  ///
  /// In en, this message translates to:
  /// **'Profile Address'**
  String get profileAddress;

  /// No description provided for @selectDeliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Select delivery location'**
  String get selectDeliveryLocation;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// No description provided for @defaultText.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultText;

  /// No description provided for @deleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get deleteAddress;

  /// No description provided for @areYouSureYouWant1.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address?'**
  String get areYouSureYouWant1;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @homeFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Home (from Profile)'**
  String get homeFromProfile;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @selectRadius.
  ///
  /// In en, this message translates to:
  /// **'Select Radius'**
  String get selectRadius;

  /// No description provided for @findingProductsIn.
  ///
  /// In en, this message translates to:
  /// **'Finding Products in'**
  String get findingProductsIn;

  /// No description provided for @saveAddressAs.
  ///
  /// In en, this message translates to:
  /// **'Save address as'**
  String get saveAddressAs;

  /// No description provided for @enterCompleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter complete address'**
  String get enterCompleteAddress;

  /// No description provided for @saveAddressAs1.
  ///
  /// In en, this message translates to:
  /// **'Save address as *'**
  String get saveAddressAs1;

  /// No description provided for @setAsDefaultAddress.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get setAsDefaultAddress;

  /// No description provided for @whoYouAreSearchingFor.
  ///
  /// In en, this message translates to:
  /// **'Who you are searching for?'**
  String get whoYouAreSearchingFor;

  /// No description provided for @areaSectorLocality.
  ///
  /// In en, this message translates to:
  /// **'Area / Sector / Locality *'**
  String get areaSectorLocality;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get saveAddress;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @pleaseEnterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Your Phone Number'**
  String get pleaseEnterYourPhoneNumber;

  /// No description provided for @text91.
  ///
  /// In en, this message translates to:
  /// **'+91'**
  String get text91;

  /// No description provided for @getOtp.
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get getOtp;

  /// No description provided for @otpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerification;

  /// No description provided for @enterTheVerificationCodeWe.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code we just sent on\\nyour phone number.'**
  String get enterTheVerificationCodeWe;

  /// No description provided for @didntReceiveTheCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get didntReceiveTheCode;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @justAFewDetailsTo.
  ///
  /// In en, this message translates to:
  /// **'Just a few details to get started'**
  String get justAFewDetailsTo;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @pleaseCheckYourInternetConnectionnand.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection\\nand try again.'**
  String get pleaseCheckYourInternetConnectionnand;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @checkingConnection.
  ///
  /// In en, this message translates to:
  /// **'Checking connection...'**
  String get checkingConnection;

  /// No description provided for @noActiveOffersYet.
  ///
  /// In en, this message translates to:
  /// **'No active offers yet'**
  String get noActiveOffersYet;

  /// No description provided for @noMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get noMatchesYet;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @matchOffers.
  ///
  /// In en, this message translates to:
  /// **'Match Offers'**
  String get matchOffers;

  /// No description provided for @seeWhatPeopleWantAround.
  ///
  /// In en, this message translates to:
  /// **'See what people want around'**
  String get seeWhatPeopleWantAround;

  /// No description provided for @seeExistingPostsByGivers.
  ///
  /// In en, this message translates to:
  /// **'See existing posts by givers'**
  String get seeExistingPostsByGivers;

  /// No description provided for @respondToPostsMentionWhat.
  ///
  /// In en, this message translates to:
  /// **'• Respond to posts, mention what you can offer in return'**
  String get respondToPostsMentionWhat;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @noNotificationsFound.
  ///
  /// In en, this message translates to:
  /// **'No notifications found'**
  String get noNotificationsFound;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @newText.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newText;

  /// No description provided for @tapToRead.
  ///
  /// In en, this message translates to:
  /// **'Tap to read'**
  String get tapToRead;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @reviewsRatings.
  ///
  /// In en, this message translates to:
  /// **'Reviews & Ratings'**
  String get reviewsRatings;

  /// No description provided for @totalReviews.
  ///
  /// In en, this message translates to:
  /// **'Total Reviews'**
  String get totalReviews;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @blockedUsersWillNotBe.
  ///
  /// In en, this message translates to:
  /// **'Blocked users will not be able to see your posts or contact you.'**
  String get blockedUsersWillNotBe;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @areYouSureYouWant2.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to'**
  String get areYouSureYouWant2;

  /// No description provided for @deleteCollection.
  ///
  /// In en, this message translates to:
  /// **'Delete Collection'**
  String get deleteCollection;

  /// No description provided for @areYouSureYouWant3.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this collection?'**
  String get areYouSureYouWant3;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get removeItem;

  /// No description provided for @areYouSureYouWant4.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this item from the collection?'**
  String get areYouSureYouWant4;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @noItemsInThisCollection.
  ///
  /// In en, this message translates to:
  /// **'No items in this collection.'**
  String get noItemsInThisCollection;

  /// No description provided for @webImageUploadComingIn.
  ///
  /// In en, this message translates to:
  /// **'Web image upload coming in next phase'**
  String get webImageUploadComingIn;

  /// No description provided for @tellOthersAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell others about yourself'**
  String get tellOthersAboutYourself;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get tapToChangePhoto;

  /// No description provided for @fullNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameIsRequired;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @noFaqsAvailableAtThe.
  ///
  /// In en, this message translates to:
  /// **'No FAQs available at the moment.'**
  String get noFaqsAvailableAtThe;

  /// No description provided for @didntFindWhatYouWere.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t find what you were looking for ?'**
  String get didntFindWhatYouWere;

  /// No description provided for @wereHereToHelpYou.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help you with any questions or issues you might have with the community'**
  String get wereHereToHelpYou;

  /// No description provided for @addFeedback.
  ///
  /// In en, this message translates to:
  /// **'Add Feedback'**
  String get addFeedback;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @manageYourPosts.
  ///
  /// In en, this message translates to:
  /// **'Manage your posts'**
  String get manageYourPosts;

  /// No description provided for @seeAllYourActiveAnd.
  ///
  /// In en, this message translates to:
  /// **'• See all your active and inactive posts'**
  String get seeAllYourActiveAnd;

  /// No description provided for @viewOffersAndNotificationsFor.
  ///
  /// In en, this message translates to:
  /// **'• View offers and notifications for your items'**
  String get viewOffersAndNotificationsFor;

  /// No description provided for @noPostsFound.
  ///
  /// In en, this message translates to:
  /// **'No posts found'**
  String get noPostsFound;

  /// No description provided for @tryChangingTheFilterOr.
  ///
  /// In en, this message translates to:
  /// **'Try changing the filter or create a new post!'**
  String get tryChangingTheFilterOr;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @deactivatePost.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Post'**
  String get deactivatePost;

  /// No description provided for @areYouSureYouWant5.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this post? It will be hidden from other users and moved to your Inactive list.'**
  String get areYouSureYouWant5;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @postDeactivatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Post deactivated successfully'**
  String get postDeactivatedSuccessfully;

  /// No description provided for @postReactivatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Post reactivated successfully'**
  String get postReactivatedSuccessfully;

  /// No description provided for @text911.
  ///
  /// In en, this message translates to:
  /// **'91'**
  String get text911;

  /// No description provided for @saveDetails.
  ///
  /// In en, this message translates to:
  /// **'Save Details'**
  String get saveDetails;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @noReviewsFound.
  ///
  /// In en, this message translates to:
  /// **'No reviews found.'**
  String get noReviewsFound;

  /// No description provided for @tradeHistory.
  ///
  /// In en, this message translates to:
  /// **'Trade History'**
  String get tradeHistory;

  /// No description provided for @creditBalance.
  ///
  /// In en, this message translates to:
  /// **'Credit Balance : '**
  String get creditBalance;

  /// No description provided for @allSaved.
  ///
  /// In en, this message translates to:
  /// **'All Saved'**
  String get allSaved;

  /// No description provided for @removeSavedProfile.
  ///
  /// In en, this message translates to:
  /// **'Remove Saved Profile'**
  String get removeSavedProfile;

  /// No description provided for @areYouSureYouWant6.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this profile from all saved?'**
  String get areYouSureYouWant6;

  /// No description provided for @createNewFolder.
  ///
  /// In en, this message translates to:
  /// **'Create New Folder'**
  String get createNewFolder;

  /// No description provided for @noSavedUsersYet.
  ///
  /// In en, this message translates to:
  /// **'No saved users yet'**
  String get noSavedUsersYet;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @saveToCollection.
  ///
  /// In en, this message translates to:
  /// **'Save to Collection'**
  String get saveToCollection;

  /// No description provided for @noCollectionsFound.
  ///
  /// In en, this message translates to:
  /// **'No collections found.'**
  String get noCollectionsFound;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @viewAllReviews.
  ///
  /// In en, this message translates to:
  /// **'View All Reviews'**
  String get viewAllReviews;

  /// No description provided for @marks.
  ///
  /// In en, this message translates to:
  /// **'Marks'**
  String get marks;

  /// No description provided for @rateThisPerson.
  ///
  /// In en, this message translates to:
  /// **'Rate This Person'**
  String get rateThisPerson;

  /// No description provided for @shimmerTesting.
  ///
  /// In en, this message translates to:
  /// **'Shimmer Testing'**
  String get shimmerTesting;

  /// No description provided for @verifyTheMotionAndColors.
  ///
  /// In en, this message translates to:
  /// **'Verify the motion and colors are \"Exact\"'**
  String get verifyTheMotionAndColors;

  /// No description provided for @serverStartingUp.
  ///
  /// In en, this message translates to:
  /// **'Server starting up...'**
  String get serverStartingUp;

  /// No description provided for @redirectingToLoginIn3.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to login in 3 seconds...'**
  String get redirectingToLoginIn3;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @buySellExchangeLend.
  ///
  /// In en, this message translates to:
  /// **'Buy • Sell • Exchange • Lend'**
  String get buySellExchangeLend;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @chooseYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get chooseYourPlan;

  /// No description provided for @unlockPremiumFeaturesAndScale.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium features and scale your productivity with TOOLUCS.'**
  String get unlockPremiumFeaturesAndScale;

  /// No description provided for @noSubscriptionPlansAvailableAt.
  ///
  /// In en, this message translates to:
  /// **'No subscription plans available at the moment.'**
  String get noSubscriptionPlansAvailableAt;

  /// No description provided for @oopsSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get oopsSomethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get mostPopular;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @mySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'My Subscriptions'**
  String get mySubscriptions;

  /// No description provided for @noSubscriptionHistory.
  ///
  /// In en, this message translates to:
  /// **'No Subscription History'**
  String get noSubscriptionHistory;

  /// No description provided for @youHaven.
  ///
  /// In en, this message translates to:
  /// **'You haven\\'**
  String get youHaven;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @creditsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Credits Remaining'**
  String get creditsRemaining;

  /// No description provided for @includedBenefits.
  ///
  /// In en, this message translates to:
  /// **'INCLUDED BENEFITS'**
  String get includedBenefits;

  /// No description provided for @noActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'No Active Subscription'**
  String get noActiveSubscription;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @remainingCredits.
  ///
  /// In en, this message translates to:
  /// **'Remaining Credits'**
  String get remainingCredits;

  /// No description provided for @tradingPoint.
  ///
  /// In en, this message translates to:
  /// **'Trading Point'**
  String get tradingPoint;

  /// No description provided for @selectArea.
  ///
  /// In en, this message translates to:
  /// **'Select Area'**
  String get selectArea;

  /// No description provided for @selectAreaDiameter.
  ///
  /// In en, this message translates to:
  /// **'Select Area Diameter'**
  String get selectAreaDiameter;

  /// No description provided for @partnersWithinThisRadiusWill.
  ///
  /// In en, this message translates to:
  /// **'Partners within this radius will see your item.'**
  String get partnersWithinThisRadiusWill;

  /// No description provided for @tradeDetails.
  ///
  /// In en, this message translates to:
  /// **'Trade Details'**
  String get tradeDetails;

  /// No description provided for @tradeType.
  ///
  /// In en, this message translates to:
  /// **'Trade Type'**
  String get tradeType;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @itemDetails.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get itemDetails;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @itemSources.
  ///
  /// In en, this message translates to:
  /// **'Item Sources'**
  String get itemSources;

  /// No description provided for @selectSource.
  ///
  /// In en, this message translates to:
  /// **'-- Select Source --'**
  String get selectSource;

  /// No description provided for @pleaseSelectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one option'**
  String get pleaseSelectAtLeastOne;

  /// No description provided for @writeANote.
  ///
  /// In en, this message translates to:
  /// **'Write a Note'**
  String get writeANote;

  /// No description provided for @whatDoYouWantIn.
  ///
  /// In en, this message translates to:
  /// **'What do you want in return ?'**
  String get whatDoYouWantIn;

  /// No description provided for @whatAreYouOffering.
  ///
  /// In en, this message translates to:
  /// **'What are you offering ?'**
  String get whatAreYouOffering;

  /// No description provided for @whatAreYouLookingFor.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for ?'**
  String get whatAreYouLookingFor;

  /// No description provided for @negotiable.
  ///
  /// In en, this message translates to:
  /// **'Negotiable'**
  String get negotiable;

  /// No description provided for @homemade.
  ///
  /// In en, this message translates to:
  /// **'Homemade'**
  String get homemade;

  /// No description provided for @storeBought.
  ///
  /// In en, this message translates to:
  /// **'Store bought'**
  String get storeBought;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @notifySavedUsersOnly.
  ///
  /// In en, this message translates to:
  /// **'Notify Saved Users Only'**
  String get notifySavedUsersOnly;

  /// No description provided for @onlyPartnersYou.
  ///
  /// In en, this message translates to:
  /// **'Only Partners you\\'**
  String get onlyPartnersYou;

  /// No description provided for @postItem.
  ///
  /// In en, this message translates to:
  /// **'Post Item'**
  String get postItem;

  /// No description provided for @activeSubscriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Active Subscription Required'**
  String get activeSubscriptionRequired;

  /// No description provided for @youDoNotHaveAny.
  ///
  /// In en, this message translates to:
  /// **'You do not have any active subscription or credits to create this post. Please buy or activate a new subscription to continue.'**
  String get youDoNotHaveAny;

  /// No description provided for @buySubscription.
  ///
  /// In en, this message translates to:
  /// **'Buy Subscription'**
  String get buySubscription;

  /// No description provided for @seeExistingPostsByTakers.
  ///
  /// In en, this message translates to:
  /// **'See existing posts by takers'**
  String get seeExistingPostsByTakers;

  /// No description provided for @respondToPostsMentionWhat1.
  ///
  /// In en, this message translates to:
  /// **'Respond to posts, mention what...'**
  String get respondToPostsMentionWhat1;

  /// No description provided for @viewSellerProfile.
  ///
  /// In en, this message translates to:
  /// **'View Seller Profile'**
  String get viewSellerProfile;

  /// No description provided for @saveSeller.
  ///
  /// In en, this message translates to:
  /// **'Save Seller'**
  String get saveSeller;

  /// No description provided for @sharePost.
  ///
  /// In en, this message translates to:
  /// **'Share Post'**
  String get sharePost;

  /// No description provided for @hidePost.
  ///
  /// In en, this message translates to:
  /// **'Hide Post'**
  String get hidePost;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get reportPost;

  /// No description provided for @seeWhatPeopleAreGiving.
  ///
  /// In en, this message translates to:
  /// **'See what people are giving'**
  String get seeWhatPeopleAreGiving;

  /// No description provided for @respondToPostsMentionWhat2.
  ///
  /// In en, this message translates to:
  /// **'Respond to posts, mention what...'**
  String get respondToPostsMentionWhat2;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @noTradeSelected.
  ///
  /// In en, this message translates to:
  /// **'No trade selected'**
  String get noTradeSelected;

  /// No description provided for @completeTrade.
  ///
  /// In en, this message translates to:
  /// **'Complete Trade'**
  String get completeTrade;

  /// No description provided for @cancelTrade.
  ///
  /// In en, this message translates to:
  /// **'Cancel Trade'**
  String get cancelTrade;

  /// No description provided for @areYouSureYouWant7.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this trade?'**
  String get areYouSureYouWant7;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @tradeSummary.
  ///
  /// In en, this message translates to:
  /// **'Trade Summary'**
  String get tradeSummary;

  /// No description provided for @noTradeHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No trade history found'**
  String get noTradeHistoryFound;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// No description provided for @whyAreYouReportingThis.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this post?'**
  String get whyAreYouReportingThis;

  /// No description provided for @selectAReason.
  ///
  /// In en, this message translates to:
  /// **'Select a reason'**
  String get selectAReason;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @asThePostOwnerYou.
  ///
  /// In en, this message translates to:
  /// **'As the post owner, you don\\'**
  String get asThePostOwnerYou;

  /// No description provided for @goToChat.
  ///
  /// In en, this message translates to:
  /// **'Go to Chat'**
  String get goToChat;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @completeTheTrade.
  ///
  /// In en, this message translates to:
  /// **'Complete the Trade'**
  String get completeTheTrade;

  /// No description provided for @chatLocked.
  ///
  /// In en, this message translates to:
  /// **'Chat Locked'**
  String get chatLocked;

  /// No description provided for @kindlyCloseTheTradeFirst.
  ///
  /// In en, this message translates to:
  /// **'Kindly close the trade first; only then will the chat be enabled.'**
  String get kindlyCloseTheTradeFirst;

  /// No description provided for @closeTrade.
  ///
  /// In en, this message translates to:
  /// **'Close Trade'**
  String get closeTrade;

  /// No description provided for @noCancel.
  ///
  /// In en, this message translates to:
  /// **'No, Cancel'**
  String get noCancel;

  /// No description provided for @yesProceed.
  ///
  /// In en, this message translates to:
  /// **'Yes, Proceed'**
  String get yesProceed;

  /// No description provided for @offerSent.
  ///
  /// In en, this message translates to:
  /// **'Offer Sent!'**
  String get offerSent;

  /// No description provided for @yourOfferHasBeenSent.
  ///
  /// In en, this message translates to:
  /// **'Your offer has been sent successfully. Please wait for the owner to accept it.'**
  String get yourOfferHasBeenSent;

  /// No description provided for @seeDetails.
  ///
  /// In en, this message translates to:
  /// **'See Details'**
  String get seeDetails;

  /// No description provided for @requestedReturnDetails.
  ///
  /// In en, this message translates to:
  /// **'Requested Return Details'**
  String get requestedReturnDetails;

  /// No description provided for @addUpTo5Photos.
  ///
  /// In en, this message translates to:
  /// **'Add up to 5 photos'**
  String get addUpTo5Photos;

  /// No description provided for @takeIt.
  ///
  /// In en, this message translates to:
  /// **'Take It'**
  String get takeIt;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @noResponseSelected.
  ///
  /// In en, this message translates to:
  /// **'No response selected'**
  String get noResponseSelected;

  /// No description provided for @meetingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Meeting Preferences'**
  String get meetingPreferences;

  /// No description provided for @acceptTheOfferAndChoose.
  ///
  /// In en, this message translates to:
  /// **'Accept the offer and choose a handover location'**
  String get acceptTheOfferAndChoose;

  /// No description provided for @reasonForRejection.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection:'**
  String get reasonForRejection;

  /// No description provided for @tradeRequest.
  ///
  /// In en, this message translates to:
  /// **'Trade Request'**
  String get tradeRequest;

  /// No description provided for @statusNote.
  ///
  /// In en, this message translates to:
  /// **'Status Note'**
  String get statusNote;

  /// No description provided for @rejectOffer.
  ///
  /// In en, this message translates to:
  /// **'Reject Offer'**
  String get rejectOffer;

  /// No description provided for @tradeAccepted.
  ///
  /// In en, this message translates to:
  /// **'Trade Accepted!'**
  String get tradeAccepted;

  /// No description provided for @thePartnerWillNowBe.
  ///
  /// In en, this message translates to:
  /// **'The partner will now be notified to pay and start the chat.'**
  String get thePartnerWillNowBe;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @tradeConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Trade Confirmed !'**
  String get tradeConfirmed;

  /// No description provided for @becauseEverythingYouNeedIs.
  ///
  /// In en, this message translates to:
  /// **'“Because everything you need is already nearby.”'**
  String get becauseEverythingYouNeedIs;

  /// No description provided for @instagramSurajubale1.
  ///
  /// In en, this message translates to:
  /// **'Instagram: @surajubale_1'**
  String get instagramSurajubale1;

  /// No description provided for @creditBalance1.
  ///
  /// In en, this message translates to:
  /// **'Credit Balance: '**
  String get creditBalance1;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser;

  /// No description provided for @yourMessages.
  ///
  /// In en, this message translates to:
  /// **'Your Messages'**
  String get yourMessages;

  /// No description provided for @selectAChatFromThe.
  ///
  /// In en, this message translates to:
  /// **'Select a chat from the left to start messaging.'**
  String get selectAChatFromThe;

  /// No description provided for @startAConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startAConversation;

  /// No description provided for @goodLuckHappyInnovation1.
  ///
  /// In en, this message translates to:
  /// **'• Good Luck, Happy Innovation!'**
  String get goodLuckHappyInnovation1;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @youHaveUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes'**
  String get youHaveUnsavedChanges;

  /// No description provided for @whatDoTheyWantIn.
  ///
  /// In en, this message translates to:
  /// **'What do they want in return?'**
  String get whatDoTheyWantIn;

  /// No description provided for @whatDoYouWantTo.
  ///
  /// In en, this message translates to:
  /// **'What do you want to give today?'**
  String get whatDoYouWantTo;

  /// No description provided for @searchAndFulfillRequestsFrom.
  ///
  /// In en, this message translates to:
  /// **'Search and fulfill requests from people around you.'**
  String get searchAndFulfillRequestsFrom;

  /// No description provided for @nearbyRequests.
  ///
  /// In en, this message translates to:
  /// **'Nearby Requests'**
  String get nearbyRequests;

  /// No description provided for @noRequestsFoundMatchingYour.
  ///
  /// In en, this message translates to:
  /// **'No requests found matching your criteria.'**
  String get noRequestsFoundMatchingYour;

  /// No description provided for @didntFindWhatYouWere1.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t find what you were looking for?'**
  String get didntFindWhatYouWere1;

  /// No description provided for @wereHereToHelpYou1.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help you with any questions or issues you might have with the community.'**
  String get wereHereToHelpYou1;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submitFeedback;

  /// No description provided for @noPostsFoundNearYou.
  ///
  /// In en, this message translates to:
  /// **'No posts found near you.'**
  String get noPostsFoundNearYou;

  /// No description provided for @joinTheCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the Community'**
  String get joinTheCommunity;

  /// No description provided for @accessThousandsOfToolsShared.
  ///
  /// In en, this message translates to:
  /// **'Access thousands of tools shared by\\npeople around you.'**
  String get accessThousandsOfToolsShared;

  /// No description provided for @pleaseEnterYourPhoneNumber1.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number to sign in or create a new account.'**
  String get pleaseEnterYourPhoneNumber1;

  /// No description provided for @locationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location Disabled'**
  String get locationDisabled;

  /// No description provided for @yourSystemLocationServicesAre.
  ///
  /// In en, this message translates to:
  /// **'Your system location services are turned off. Please enable location in your device settings to fetch your current location.'**
  String get yourSystemLocationServicesAre;

  /// No description provided for @findingProductsFor.
  ///
  /// In en, this message translates to:
  /// **'Finding Products for'**
  String get findingProductsFor;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @currentPlan1.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PLAN'**
  String get currentPlan1;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @changePlan.
  ///
  /// In en, this message translates to:
  /// **'Change Plan'**
  String get changePlan;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get viewPlans;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retryConnection;

  /// No description provided for @checkingConnectionAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Checking connection automatically...'**
  String get checkingConnectionAutomatically;

  /// No description provided for @welcomeToToolbocs.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Toolucs'**
  String get welcomeToToolbocs;

  /// No description provided for @theUltimatePlatformToTrade.
  ///
  /// In en, this message translates to:
  /// **'The ultimate platform to trade, lend, and borrow tools in your community.'**
  String get theUltimatePlatformToTrade;

  /// No description provided for @byContinuingYouAgreeTo.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy.'**
  String get byContinuingYouAgreeTo;

  /// No description provided for @secureAccess.
  ///
  /// In en, this message translates to:
  /// **'Secure Access'**
  String get secureAccess;

  /// No description provided for @yourSecurityIsOurTop.
  ///
  /// In en, this message translates to:
  /// **'Your security is our top priority. We use secure\\nOTP verification to protect your account.'**
  String get yourSecurityIsOurTop;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code? '**
  String get didntReceiveCode;

  /// No description provided for @verifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify Account'**
  String get verifyAccount;

  /// No description provided for @errorNoPostIdProvided.
  ///
  /// In en, this message translates to:
  /// **'Error: No Post ID provided (or page was refreshed)'**
  String get errorNoPostIdProvided;

  /// No description provided for @postNotFoundOrAccess.
  ///
  /// In en, this message translates to:
  /// **'Post not found or access denied'**
  String get postNotFoundOrAccess;

  /// No description provided for @descriptionPoints.
  ///
  /// In en, this message translates to:
  /// **'Description Points:'**
  String get descriptionPoints;

  /// No description provided for @priceInReturn.
  ///
  /// In en, this message translates to:
  /// **'Price in return'**
  String get priceInReturn;

  /// No description provided for @itemSource.
  ///
  /// In en, this message translates to:
  /// **'Item Source'**
  String get itemSource;

  /// No description provided for @thisItemIsNoLonger.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available.'**
  String get thisItemIsNoLonger;

  /// No description provided for @recommendedItemsFromVerifiedSellers.
  ///
  /// In en, this message translates to:
  /// **'Recommended items from verified sellers.'**
  String get recommendedItemsFromVerifiedSellers;

  /// No description provided for @pleaseLogInToView.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view your profile.'**
  String get pleaseLogInToView;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @yourProfileIsSavedBy.
  ///
  /// In en, this message translates to:
  /// **'Your profile is saved by 22 users'**
  String get yourProfileIsSavedBy;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @setUpYourAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Set up your account details to start\\nsharing and finding tools.'**
  String get setUpYourAccountDetails;

  /// No description provided for @justAFewDetails.
  ///
  /// In en, this message translates to:
  /// **'Just a few details'**
  String get justAFewDetails;

  /// No description provided for @pleaseCompleteYourProfileTo.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile to continue.'**
  String get pleaseCompleteYourProfileTo;

  /// No description provided for @whatDoYouWantTo1.
  ///
  /// In en, this message translates to:
  /// **'What do you want to take today?'**
  String get whatDoYouWantTo1;

  /// No description provided for @discoverAmazingToolsAndItems.
  ///
  /// In en, this message translates to:
  /// **'Discover amazing tools and items being given away near you.'**
  String get discoverAmazingToolsAndItems;

  /// No description provided for @requestAnItem.
  ///
  /// In en, this message translates to:
  /// **'Request an Item'**
  String get requestAnItem;

  /// No description provided for @availableItemsNearby.
  ///
  /// In en, this message translates to:
  /// **'Available Items Nearby'**
  String get availableItemsNearby;

  /// No description provided for @noItemsFoundMatchingYour.
  ///
  /// In en, this message translates to:
  /// **'No items found matching your search.'**
  String get noItemsFoundMatchingYour;

  /// No description provided for @appearanceSettings.
  ///
  /// In en, this message translates to:
  /// **'Appearance Settings'**
  String get appearanceSettings;

  /// No description provided for @customizeTheLookAndFeel.
  ///
  /// In en, this message translates to:
  /// **'Customize the look and feel of the application.'**
  String get customizeTheLookAndFeel;

  /// No description provided for @rateThisUser.
  ///
  /// In en, this message translates to:
  /// **'Rate this user'**
  String get rateThisUser;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @searchChats.
  ///
  /// In en, this message translates to:
  /// **'Search chats...'**
  String get searchChats;

  /// No description provided for @chatInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get chatInfoTitle;

  /// No description provided for @chatInfo1.
  ///
  /// In en, this message translates to:
  /// **'This Chat stays on for next 72 hours.'**
  String get chatInfo1;

  /// No description provided for @chatInfo2.
  ///
  /// In en, this message translates to:
  /// **'Do Not cheat, Negative remarks stays on your profile forever.'**
  String get chatInfo2;

  /// No description provided for @chatInfo3.
  ///
  /// In en, this message translates to:
  /// **'Good Luck, Happy Innovation!.'**
  String get chatInfo3;

  /// No description provided for @distanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceLabel;

  /// No description provided for @setYourLocationToEnable.
  ///
  /// In en, this message translates to:
  /// **'Set your location to enable distance filtering'**
  String get setYourLocationToEnable;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String kmAway(String distance);

  /// No description provided for @unknownDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'- km away'**
  String get unknownDistanceAway;

  /// No description provided for @userIsTaking.
  ///
  /// In en, this message translates to:
  /// **'{userName}\'s Taking'**
  String userIsTaking(String userName);

  /// No description provided for @userIsGiving.
  ///
  /// In en, this message translates to:
  /// **'{userName}\'s Giving'**
  String userIsGiving(String userName);

  /// No description provided for @inExchangeFor.
  ///
  /// In en, this message translates to:
  /// **'In exchange for: '**
  String get inExchangeFor;

  /// No description provided for @moneyLabel.
  ///
  /// In en, this message translates to:
  /// **'(Money)'**
  String get moneyLabel;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeLabel;

  /// No description provided for @itemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemLabel;

  /// No description provided for @offersLabel.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offersLabel;

  /// No description provided for @giveLabel.
  ///
  /// In en, this message translates to:
  /// **'Give'**
  String get giveLabel;

  /// No description provided for @takeLabel.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get takeLabel;

  /// No description provided for @enableGpsForAccurateLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable GPS for accurate location'**
  String get enableGpsForAccurateLocation;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add new address'**
  String get addNewAddress;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @filterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterLabel;

  /// No description provided for @sortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortByLabel;

  /// No description provided for @showingResults.
  ///
  /// In en, this message translates to:
  /// **'(Showing {count} Results)'**
  String showingResults(int count);

  /// No description provided for @myPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPostsTitle;

  /// No description provided for @seeAllActiveInactivePosts.
  ///
  /// In en, this message translates to:
  /// **'• See all your active and inactive posts'**
  String get seeAllActiveInactivePosts;

  /// No description provided for @viewOffersNotifications.
  ///
  /// In en, this message translates to:
  /// **'• View offers and notifications for your items'**
  String get viewOffersNotifications;

  /// No description provided for @allPostsTab.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allPostsTab;

  /// No description provided for @activePostsTab.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activePostsTab;

  /// No description provided for @inactivePostsTab.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactivePostsTab;

  /// No description provided for @tryChangingFilterOrCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Try changing the filter or create a new post!'**
  String get tryChangingFilterOrCreatePost;

  /// No description provided for @createPostLabel.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPostLabel;

  /// No description provided for @noSubscriptionPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t made any subscription payments yet.'**
  String get noSubscriptionPaymentsYet;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}'**
  String expiresOn(String date);

  /// No description provided for @idHash.
  ///
  /// In en, this message translates to:
  /// **'ID #{id}'**
  String idHash(String id);

  /// No description provided for @periodLabel.
  ///
  /// In en, this message translates to:
  /// **'PERIOD'**
  String get periodLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT'**
  String get amountLabel;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeStatus;

  /// No description provided for @expiredStatus.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get expiredStatus;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message ...'**
  String get typeAMessage;

  /// No description provided for @youChose.
  ///
  /// In en, this message translates to:
  /// **'You chose '**
  String get youChose;

  /// No description provided for @givingTo.
  ///
  /// In en, this message translates to:
  /// **'Giving {givingItem} to {partnerName} '**
  String givingTo(String givingItem, String partnerName);

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **'and '**
  String get andWord;

  /// No description provided for @taking.
  ///
  /// In en, this message translates to:
  /// **'Taking {takingItem} '**
  String taking(String takingItem);

  /// No description provided for @inReturn.
  ///
  /// In en, this message translates to:
  /// **'in return'**
  String get inReturn;

  /// No description provided for @postNotFound.
  ///
  /// In en, this message translates to:
  /// **'Post not found'**
  String get postNotFound;

  /// No description provided for @offerSummary.
  ///
  /// In en, this message translates to:
  /// **'Offer Summary'**
  String get offerSummary;

  /// No description provided for @selectYourOffer.
  ///
  /// In en, this message translates to:
  /// **'Select Your Offer'**
  String get selectYourOffer;

  /// No description provided for @youHaveAlreadyMadeAn.
  ///
  /// In en, this message translates to:
  /// **'You have already made an offer for this item.'**
  String get youHaveAlreadyMadeAn;

  /// No description provided for @step1Of4.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 4'**
  String get step1Of4;

  /// No description provided for @whatDoYouWantIn1.
  ///
  /// In en, this message translates to:
  /// **'What do you want in return?'**
  String get whatDoYouWantIn1;

  /// No description provided for @setYourAcceptablePriceRange.
  ///
  /// In en, this message translates to:
  /// **'Set your acceptable price range'**
  String get setYourAcceptablePriceRange;

  /// No description provided for @allowBuyersToMakeCounter.
  ///
  /// In en, this message translates to:
  /// **'Allow buyers to make counter offers'**
  String get allowBuyersToMakeCounter;

  /// No description provided for @waitingForThePostOwner.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the post owner to review your offer...'**
  String get waitingForThePostOwner;

  /// No description provided for @reasonForRejection1.
  ///
  /// In en, this message translates to:
  /// **'Reason for Rejection'**
  String get reasonForRejection1;

  /// No description provided for @reviewRespond.
  ///
  /// In en, this message translates to:
  /// **'Review & Respond'**
  String get reviewRespond;

  /// No description provided for @acceptTheOfferAndChoose1.
  ///
  /// In en, this message translates to:
  /// **'Accept the offer and choose a handover location, or reject it entirely.'**
  String get acceptTheOfferAndChoose1;

  /// No description provided for @meetingPreference.
  ///
  /// In en, this message translates to:
  /// **'Meeting Preference'**
  String get meetingPreference;

  /// No description provided for @confirmAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Confirm Acceptance'**
  String get confirmAcceptance;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @tradeConfirmed1.
  ///
  /// In en, this message translates to:
  /// **'Trade Confirmed!'**
  String get tradeConfirmed1;

  /// No description provided for @viewTradeDetails.
  ///
  /// In en, this message translates to:
  /// **'View Trade Details'**
  String get viewTradeDetails;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @sellerProfile.
  ///
  /// In en, this message translates to:
  /// **'Seller Profile'**
  String get sellerProfile;

  /// No description provided for @communityMarks.
  ///
  /// In en, this message translates to:
  /// **'Community Marks'**
  String get communityMarks;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @errorProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Error: Profile not found'**
  String get errorProfileNotFound;

  /// No description provided for @personRating.
  ///
  /// In en, this message translates to:
  /// **'Person Rating'**
  String get personRating;

  /// No description provided for @totalTrades.
  ///
  /// In en, this message translates to:
  /// **'Total Trades'**
  String get totalTrades;

  /// No description provided for @sentOffers.
  ///
  /// In en, this message translates to:
  /// **'Sent Offers'**
  String get sentOffers;

  /// No description provided for @receivedOffers.
  ///
  /// In en, this message translates to:
  /// **'Received Offers'**
  String get receivedOffers;

  /// No description provided for @matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matches;

  /// No description provided for @sentTab.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sentTab;

  /// No description provided for @receivedTab.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedTab;

  /// No description provided for @profileSavedBy.
  ///
  /// In en, this message translates to:
  /// **'Your profile is saved by {count} users'**
  String profileSavedBy(String count);

  /// No description provided for @unblockUserPrompt.
  ///
  /// In en, this message translates to:
  /// **'unblock {name}?'**
  String unblockUserPrompt(String name);

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get folderName;

  /// No description provided for @usagePostsUsed.
  ///
  /// In en, this message translates to:
  /// **'Usage: {count} posts used'**
  String usagePostsUsed(String count);

  /// No description provided for @postVisibilityStatus.
  ///
  /// In en, this message translates to:
  /// **'Post Visibility: {status}'**
  String postVisibilityStatus(String status);

  /// No description provided for @remainingDaysCount.
  ///
  /// In en, this message translates to:
  /// **'Remaining Days: {days}'**
  String remainingDaysCount(String days);

  /// No description provided for @postPriceAmount.
  ///
  /// In en, this message translates to:
  /// **'Post Price: ₹{price}'**
  String postPriceAmount(String price);

  /// No description provided for @totalAllocationCredits.
  ///
  /// In en, this message translates to:
  /// **'Total Allocation: {credits} Credits'**
  String totalAllocationCredits(String credits);

  /// No description provided for @daysPlan.
  ///
  /// In en, this message translates to:
  /// **'{days} Days Plan'**
  String daysPlan(String days);

  /// No description provided for @planText.
  ///
  /// In en, this message translates to:
  /// **'{name} Plan'**
  String planText(String name);

  /// No description provided for @blockedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Blocked on: {date}'**
  String blockedOnDate(String date);

  /// No description provided for @youDontHaveAnyActiveSubscriptionPlan.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any active subscription plan.'**
  String get youDontHaveAnyActiveSubscriptionPlan;

  /// No description provided for @collectionCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Collection created successfully'**
  String get collectionCreatedSuccessfully;

  /// No description provided for @failedToCreateCollection.
  ///
  /// In en, this message translates to:
  /// **'Failed to create collection'**
  String get failedToCreateCollection;

  /// No description provided for @profileRemovedFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile removed from saved'**
  String get profileRemovedFromSaved;

  /// No description provided for @failedToRemoveProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove profile'**
  String get failedToRemoveProfile;

  /// No description provided for @giveIt.
  ///
  /// In en, this message translates to:
  /// **'Give It'**
  String get giveIt;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @itemCondition.
  ///
  /// In en, this message translates to:
  /// **'Item Condition'**
  String get itemCondition;

  /// No description provided for @noDescriptionProvided.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescriptionProvided;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @returnInReturn.
  ///
  /// In en, this message translates to:
  /// **'{returnType} in return'**
  String returnInReturn(String returnType);

  /// No description provided for @returnInReturnFallback.
  ///
  /// In en, this message translates to:
  /// **'Return in return'**
  String get returnInReturnFallback;

  /// No description provided for @kmAwayFrom.
  ///
  /// In en, this message translates to:
  /// **'{km} km away from {location}'**
  String kmAwayFrom(String km, String location);

  /// No description provided for @giveWhatWillYouOffer.
  ///
  /// In en, this message translates to:
  /// **'Give ( What will you offer in Return? )'**
  String get giveWhatWillYouOffer;

  /// No description provided for @takeWhatYouWant.
  ///
  /// In en, this message translates to:
  /// **'Take ( What you want in Return? )'**
  String get takeWhatYouWant;

  /// No description provided for @giveWhatIsAskingFor.
  ///
  /// In en, this message translates to:
  /// **'Give what {name}\'s asking for'**
  String giveWhatIsAskingFor(String name);

  /// No description provided for @takeWhatIsGiving.
  ///
  /// In en, this message translates to:
  /// **'Take what {name}\'s giving'**
  String takeWhatIsGiving(String name);

  /// No description provided for @itemYouOfferInReturn.
  ///
  /// In en, this message translates to:
  /// **'Item You Offer in Return'**
  String get itemYouOfferInReturn;

  /// No description provided for @itemYouWantInReturn.
  ///
  /// In en, this message translates to:
  /// **'Item You Want in Return'**
  String get itemYouWantInReturn;

  /// No description provided for @fillDetailsYouOffering.
  ///
  /// In en, this message translates to:
  /// **'Fill details of the item you\'re offering'**
  String get fillDetailsYouOffering;

  /// No description provided for @fillItemDetailsYouWant.
  ///
  /// In en, this message translates to:
  /// **'Fill item details you want in return'**
  String get fillItemDetailsYouWant;

  /// No description provided for @moneyAskForMoney.
  ///
  /// In en, this message translates to:
  /// **'Money ( Ask for Money )'**
  String get moneyAskForMoney;

  /// No description provided for @askForMoney.
  ///
  /// In en, this message translates to:
  /// **'Ask for Money'**
  String get askForMoney;

  /// No description provided for @offerPriceForItem.
  ///
  /// In en, this message translates to:
  /// **'Offer a price for the item'**
  String get offerPriceForItem;

  /// No description provided for @setCustomPrice.
  ///
  /// In en, this message translates to:
  /// **'Set a custom price for the item'**
  String get setCustomPrice;

  /// No description provided for @askForFree.
  ///
  /// In en, this message translates to:
  /// **'Ask for Free'**
  String get askForFree;

  /// No description provided for @giveForFree.
  ///
  /// In en, this message translates to:
  /// **'Give For Free'**
  String get giveForFree;

  /// No description provided for @spreadSomeJoy.
  ///
  /// In en, this message translates to:
  /// **'Spread some joy in the neighborhood'**
  String get spreadSomeJoy;

  /// No description provided for @giverLabel.
  ///
  /// In en, this message translates to:
  /// **'GIVER'**
  String get giverLabel;

  /// No description provided for @takerLabel.
  ///
  /// In en, this message translates to:
  /// **'TAKER'**
  String get takerLabel;

  /// No description provided for @givingAction.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Giving'**
  String givingAction(String name);

  /// No description provided for @takingAction.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Taking'**
  String takingAction(String name);

  /// No description provided for @offerTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Offer Type : {type}'**
  String offerTypeLabel(String type);

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category : {category}'**
  String categoryLabel(String category);

  /// No description provided for @takeItemFrom.
  ///
  /// In en, this message translates to:
  /// **'Take {item} from {name}'**
  String takeItemFrom(String item, String name);

  /// No description provided for @giveItemTo.
  ///
  /// In en, this message translates to:
  /// **'Give {item} to {name}'**
  String giveItemTo(String item, String name);

  /// No description provided for @giveSpecifiedReturn.
  ///
  /// In en, this message translates to:
  /// **'Give Specified Return'**
  String get giveSpecifiedReturn;

  /// No description provided for @takeOfferedItem.
  ///
  /// In en, this message translates to:
  /// **'Take Offered Item'**
  String get takeOfferedItem;

  /// No description provided for @offerCustomItem.
  ///
  /// In en, this message translates to:
  /// **'Offer Custom Item'**
  String get offerCustomItem;

  /// No description provided for @requestCustomItem.
  ///
  /// In en, this message translates to:
  /// **'Request Custom Item'**
  String get requestCustomItem;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send Offer'**
  String get sendOffer;

  /// No description provided for @offerSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer Sent!'**
  String get offerSentTitle;

  /// No description provided for @offerSentMsg.
  ///
  /// In en, this message translates to:
  /// **'Your offer has been sent successfully. Please wait for the owner to accept it.'**
  String get offerSentMsg;

  /// No description provided for @kmAwayLabel.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String kmAwayLabel(String km);

  /// No description provided for @didNotFindWhatYouWereLookingFor.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t find what you were looking for ?'**
  String get didNotFindWhatYouWereLookingFor;

  /// No description provided for @wereHereToHelpYouWithAnyQuestions.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help you with any questions or issues you might have with the community'**
  String get wereHereToHelpYouWithAnyQuestions;

  /// No description provided for @shareYourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Share Your Feedback'**
  String get shareYourFeedback;

  /// No description provided for @partnersWithinRadius.
  ///
  /// In en, this message translates to:
  /// **'Partners within this radius will see your item.'**
  String get partnersWithinRadius;

  /// No description provided for @enterItemName.
  ///
  /// In en, this message translates to:
  /// **'Enter item name'**
  String get enterItemName;

  /// No description provided for @pleaseSelectAtLeastOneOption.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one option'**
  String get pleaseSelectAtLeastOneOption;

  /// No description provided for @minimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get minimum;

  /// No description provided for @maximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get maximum;

  /// No description provided for @postNow.
  ///
  /// In en, this message translates to:
  /// **'Post Now'**
  String get postNow;

  /// No description provided for @postRequest.
  ///
  /// In en, this message translates to:
  /// **'Post Request'**
  String get postRequest;

  /// No description provided for @uploadAtLeastOneImage.
  ///
  /// In en, this message translates to:
  /// **'Upload at least one image'**
  String get uploadAtLeastOneImage;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @creditsLeft.
  ///
  /// In en, this message translates to:
  /// **'Credits: {credits}'**
  String creditsLeft(String credits);

  /// No description provided for @creditsPerTrade.
  ///
  /// In en, this message translates to:
  /// **'{credits} Credits per trade'**
  String creditsPerTrade(String credits);

  /// No description provided for @noActiveSubscriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have any active subscription or credits to create this post. Please buy or activate a new subscription to continue.'**
  String get noActiveSubscriptionMessage;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @categoryAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category added successfully!'**
  String get categoryAddedSuccessfully;

  /// No description provided for @addCustomCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Category'**
  String get addCustomCategory;

  /// No description provided for @photoRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo required'**
  String get photoRequired;

  /// No description provided for @max5PhotosReached.
  ///
  /// In en, this message translates to:
  /// **'Max 5 photos reached'**
  String get max5PhotosReached;

  /// No description provided for @createGivePost.
  ///
  /// In en, this message translates to:
  /// **'Create Give Post'**
  String get createGivePost;

  /// No description provided for @createTakePost.
  ///
  /// In en, this message translates to:
  /// **'Create Take Post'**
  String get createTakePost;

  /// No description provided for @askSomeoneToTake.
  ///
  /// In en, this message translates to:
  /// **'• Ask someone to take something, by creating a post'**
  String get askSomeoneToTake;

  /// No description provided for @postVisibleToTakers.
  ///
  /// In en, this message translates to:
  /// **'• This post will be visible to the \"takers\" around you'**
  String get postVisibleToTakers;

  /// No description provided for @inYourSelectedArea.
  ///
  /// In en, this message translates to:
  /// **'• In your selected area i.e >10 mtrs / <5kms'**
  String get inYourSelectedArea;

  /// No description provided for @newCondition.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newCondition;

  /// No description provided for @likeNewCondition.
  ///
  /// In en, this message translates to:
  /// **'Like New'**
  String get likeNewCondition;

  /// No description provided for @usedCondition.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get usedCondition;

  /// No description provided for @describeYourProduct.
  ///
  /// In en, this message translates to:
  /// **'Describe your product here...'**
  String get describeYourProduct;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @desiredPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Desired Price Range'**
  String get desiredPriceRange;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @tradeWith.
  ///
  /// In en, this message translates to:
  /// **'Trade With'**
  String get tradeWith;

  /// No description provided for @exchangeDetails.
  ///
  /// In en, this message translates to:
  /// **'Exchange Details'**
  String get exchangeDetails;

  /// No description provided for @youReceive.
  ///
  /// In en, this message translates to:
  /// **'You Receive'**
  String get youReceive;

  /// No description provided for @youGive.
  ///
  /// In en, this message translates to:
  /// **'You Give'**
  String get youGive;

  /// No description provided for @youPay.
  ///
  /// In en, this message translates to:
  /// **'You Pay'**
  String get youPay;

  /// No description provided for @tradeInfo.
  ///
  /// In en, this message translates to:
  /// **'Trade Info'**
  String get tradeInfo;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateLabel(String date);

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(String status);

  /// No description provided for @meetingLabel.
  ///
  /// In en, this message translates to:
  /// **'Meeting: {meeting}'**
  String meetingLabel(String meeting);

  /// No description provided for @tradeNotes.
  ///
  /// In en, this message translates to:
  /// **'Trade Notes'**
  String get tradeNotes;

  /// No description provided for @noAdditionalNotesProvided.
  ///
  /// In en, this message translates to:
  /// **'No additional notes provided.'**
  String get noAdditionalNotesProvided;

  /// No description provided for @rejectedReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejected Reason: {reason}'**
  String rejectedReasonLabel(String reason);

  /// No description provided for @chatWith.
  ///
  /// In en, this message translates to:
  /// **'Chat with {name}'**
  String chatWith(String name);

  /// No description provided for @tradeCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Trade cancelled successfully'**
  String get tradeCancelledSuccessfully;

  /// No description provided for @failedToCancelTrade.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel trade'**
  String get failedToCancelTrade;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @dislike.
  ///
  /// In en, this message translates to:
  /// **'Dislike'**
  String get dislike;

  /// No description provided for @likedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Liked successfully'**
  String get likedSuccessfully;

  /// No description provided for @dislikedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Disliked successfully'**
  String get dislikedSuccessfully;

  /// No description provided for @failedToSubmitMark.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit mark'**
  String get failedToSubmitMark;

  /// No description provided for @givingYouItem.
  ///
  /// In en, this message translates to:
  /// **'Giving you {itemName}'**
  String givingYouItem(String itemName);

  /// No description provided for @takingYourItem.
  ///
  /// In en, this message translates to:
  /// **'Taking your {itemName}'**
  String takingYourItem(String itemName);

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @usedForNotifications.
  ///
  /// In en, this message translates to:
  /// **'Used for notifications and account recovery'**
  String get usedForNotifications;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @verifiedMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Verified mobile number'**
  String get verifiedMobileNumber;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @profileVisibility.
  ///
  /// In en, this message translates to:
  /// **'Profile Visibility'**
  String get profileVisibility;

  /// No description provided for @publicAnyoneCanView.
  ///
  /// In en, this message translates to:
  /// **'Public: Anyone can view your profile.'**
  String get publicAnyoneCanView;

  /// No description provided for @showTradeHistory.
  ///
  /// In en, this message translates to:
  /// **'Show Trade History'**
  String get showTradeHistory;

  /// No description provided for @tradeHistoryHidden.
  ///
  /// In en, this message translates to:
  /// **'Your trade history is hidden from others.'**
  String get tradeHistoryHidden;

  /// No description provided for @enterYourBio.
  ///
  /// In en, this message translates to:
  /// **'Enter your bio...'**
  String get enterYourBio;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
