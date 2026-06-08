# LEARN.md

## Project Summary

`jerseyapp` is a Flutter mobile shopping app built as an e-commerce storefront for premium sports jerseys and apparel. It uses Firebase for backend services including authentication, Firestore, storage, cloud functions, and email OTP support.

## Core Technologies

- Flutter 3 / Dart 3
- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `cloud_functions`
- Riverpod for state management
- EmailJS OTP integration via `emailjs`
- Local asset-based product visuals stored under `images/` and `product_images/`

## Important App Files

### Entry Point
- `lib/main.dart`
  - Initializes Firebase using `firebase_options.dart`
  - Wraps the app with `ProviderScope`
  - Sets up `MaterialApp` with app theme and `SplashScreen`
  - Handles route generation for `OTPVerificationScreen`

### Launch and Authentication
- `lib/splash_screen.dart`
  - Splash animation and 3-second redirect to `AuthScreen`
- `lib/auth_screen.dart`
  - Login / signup form
  - Toggles between sign-in and sign-up modes
  - Uses `AuthService` and `AuthOtpController`
- `lib/otp_verification_screen.dart`
  - OTP entry for signup verification and payment verification
- `lib/forgot_password_screen.dart`
  - Password reset using Firebase Auth email reset

### Home and Shopping
- `lib/home.dart`
  - Main customer landing screen with category chips, search, product grid, and bottom navigation
  - Combines home browsing, cart count, wishlist, profile access, and order shortcuts
- `lib/product_details_page.dart`
  - Product detail screen with size selection, add to cart, buy now, and wishlist toggling
- `lib/cart_page.dart`
  - Cart management UI with item selection, quantity, size update, and checkout initiation
- `lib/order_setup_page.dart`
  - Order review screen for buy-now flow and cart checkout flow
- `lib/checkout_page.dart`
  - Payment method selection screen with bKash and card options
- `lib/bkash_payment_page.dart` and `lib/card_payment_page.dart`
  - Payment form UI that creates a payment session and sends OTP for verification
- `lib/payment_success_page.dart`
  - Verifies the payment session, creates the paid order, and moves to receipt
- `lib/order_receipt_page.dart`
  - Final order receipt display after payment success

### Profile and Orders
- `lib/profile_page.dart`
  - Current user profile display and account information
- `lib/edit_profile_page.dart`
  - Edit user name and address information
- `lib/orders_page.dart`
  - Order history list for the signed-in customer
- `lib/order_details_page.dart`
  - Detailed view of a placed order

### Admin Panel
- `lib/admin/admin_panel_screen.dart`
  - Top-level admin dashboard screen with navigation to admin views
- `lib/admin/views/`
  - `dashboard_view.dart`: analytics and summary cards
  - `orders_view.dart`: order listing and management
  - `products_view.dart`: product management and catalog controls
  - `inventory_view.dart`: stock and size management for products
  - `users_view.dart`: user role management and user list

### Providers and Services
- `lib/providers/auth_otp_controller.dart`
  - OTP lifecycle and verification state for both signup and payment flows
- `lib/providers/admin_provider.dart`
  - Admin streams and role management state
- `lib/services/auth_service.dart`
  - Firebase email/password auth, sign in, sign up, logout, and user profile persistence
- `lib/services/otp_service.dart`
  - Firestore OTP record creation, verification, resend, and cancellation
- `lib/services/email_otp_service.dart`
  - Sends OTP via EmailJS using an external email template
- `lib/services/product_service.dart`
  - Streams product collection data, normalizes product fields, reads size variants
- `lib/services/cart_service.dart`
  - Manages cart items, quantity, selected sizes, and stock verification
- `lib/services/wishlist_service.dart`
  - Toggles wishlist entries and streams wishlist product IDs
- `lib/services/order_service.dart`
  - Creates paid orders and clears cart items after successful payment
- `lib/services/payment_session_service.dart`
  - Creates and verifies payment sessions for OTP-secured payments
- `lib/services/profile_service.dart`
  - Current user profile stream, updates, and user data initialization
- `lib/services/admin_service.dart`
  - Admin analytics, product/order/user management, and cloud function wrappers

## Firebase Data Model

### Collections

- `users/{uid}`
  - `cart` subcollection: user cart items
  - `wishlist` subcollection: wishlisted product ids
  - `orders` subcollection: orders created by the user
- `products`
  - Main product catalog documents with fields such as `name`, `description`, `price`, `images`, `sizeVariants`, `category`, `brand`, and `available`
- `payment_sessions`
  - Tracks the payment state of pending checkout sessions before order creation
- `otp_verifications`
  - Stores OTP codes, expiry, type, and verification state for signup or payment flows

### Key document usage

- Cart operations are scoped to `users/{uid}/cart`
- Wishlist presence is stored per user under `users/{uid}/wishlist`
- Orders are written under `users/{uid}/orders` with transaction handling for item stock deduction
- Admin updates may use direct Firestore document writes and callable Cloud Functions for secure operations like product deletion and user role changes

## Application Architecture

### UI Layer
- `lib/*_page.dart`, `lib/*_screen.dart`, `lib/admin/*`
- Screens use Flutter `Widget` trees with Material design and custom theming from `lib/core/theme`
- Significant use of `StreamBuilder` to render live Firestore data

### State Management
- `flutter_riverpod` is the app's chosen state management solution
- Providers expose asynchronous streams and notifier-based state
- Services encapsulate Firebase operations and business logic

### Services Layer
- Handles all Firestore, Firebase Auth, Storage, and Cloud Functions interactions
- Maintains separation between UI and backend data operations
- Provides reusable methods for product listing, cart changes, order creation, user profile updates, and admin actions

### Theming
- Shape, color, and typography are centralized under `lib/core/theme/`
- Custom widgets and background components reuse `AppColors`, `AppSpacing`, and `AppTextStyles`

## Notes for Further Exploration

- `lib/common/widgets/auth_background.dart` provides the persistent visual shell used in login and splash screens
- `lib/models/` likely contains strongly typed model classes used for data conversions and UI binding
- `lib/core/theme/` holds the centralized design system used by most visible components
- Admin-only screens rely on provider state and service wrappers for analytics and action confirmation

## Quick Start

1. Open the workspace in Flutter-enabled VS Code
2. Ensure Firebase config files are available for each platform
3. Run `flutter pub get`
4. Start the app with `flutter run`

> Note: This app depends on a live Firebase project and EmailJS configuration for the OTP flows to work end-to-end.
