# WIDGET_EXPLANATION.md

## 1. Widget Architecture Overview

This app separates visual layout from business logic using:

- `lib/*_page.dart` and `lib/*_screen.dart` for full-screen views
- `lib/widgets/` for reusable UI components
- `lib/common/widgets/` for shared shell and background UI
- `lib/core/theme/` for colors, spacing, and typography
- Riverpod providers for state management and Firestore streams

Most screens are built as `StatelessWidget` or `StatefulWidget` classes that compose smaller custom widgets.

## 2. Major Screen Widget Trees

### `SplashScreen`
- Root scaffold with `AuthBackground`
- Centered animated logo and app title
- Timer to transition to `AuthScreen`

### `AuthScreen`
- Root `Scaffold` with `AuthBackground`
- Card-based form box for login/signup
- Form fields using `AuthTextField`
- Action buttons for submit and mode toggle
- Links to `ForgotPasswordScreen`
- Navigation to `OTPVerificationScreen` for signup/OTP flows

### `HomeScreen`
- Column layout with header, search area, category chips, and product grid
- Uses `AppSearchBar` for search input
- Category chips filter Firestore product stream
- `ProductCard` shows each product thumbnail
- Bottom navigation via `BottomNavBar`
- `StreamBuilder` and `FutureBuilder` combine Firestore data and wishlist state

### `ProductDetailsPage`
- Summary card for selected product image and details
- Size selection using custom selectable chips/buttons
- Quantity selector and total price summary
- Action buttons for `Add to Cart` and `Buy Now`
- Wishlist toggle icon with instant feedback

### `CartPage`
- Cart list rendered with `StreamBuilder` on user cart data
- Each item rendered by a cart tile with quantity and size controls
- Summary footer with total and checkout button
- Multi-selection support for checkout flow using item checkboxes

### `OrderSetupPage`
- Order preview with shipping address details and item summary
- Selection of shipping address from user profile
- Continue button to `CheckoutPage`

### `CheckoutPage`
- Payment method cards for bKash and card payment
- Order summary section with line totals
- Buttons to navigate into payment flow screens

### `BkashPaymentPage` / `CardPaymentPage`
- Payment form fields for phone/email and transaction details
- Submit button that creates a payment session and sends OTP
- Uses `PaymentSessionService` to persist session state

### `OTPVerificationScreen`
- OTP entry fields for 6-digit code
- Resend OTP button and timeout controls
- UI adapts based on payment vs signup verification mode

### `PaymentSuccessPage`
- Success confirmation UI with order receipt summary
- Button to view the order or return home
- Verifies payment session and triggers order creation

### `AdminPanelScreen`
- Side navigation / tab-based view for admin features
- Loads child views based on selected admin section
- Accessible views include dashboard metrics, orders, product catalog, inventory, and users

## 3. Reusable UI Components

### `BottomNavBar`
- Custom bottom navigation bar with 4 tabs
- Uses `GestureDetector` to handle tap events
- Highlights the active tab with accent color

### `ProductCard`
- Encapsulates product image, wishlist button, title, and price
- Includes built-in asset resolution fallback for missing images
- Shows out-of-stock badge when product is unavailable
- Provides an add-to-cart floating button

### `AuthTextField`
- Styled text form field for login/signup forms
- Supports label, hint text, validation, focus control, and suffix widgets
- Uses centralized `AppColors`, `AppTextStyles`, and rounded borders

### `AppSearchBar`
- Search input shell with icon and custom background
- Calls `onChanged` to update product filtering live

## 4. State Management Patterns

### Riverpod Providers
- `ProviderScope` at root enables Riverpod throughout the app
- `AuthOtpController` manages OTP lifecycle and cooldown state
- `AdminProvider` handles admin-specific streams, statistics, and actions

### Stream-driven UI
- Most data-driven screens rely on Firestore `StreamBuilder`
- Streams are exposed by service classes:
  - `ProductService` for product catalog
  - `CartService` for cart list
  - `WishlistService` for wishlist product IDs
  - `ProfileService` for user profile
  - `AdminService` for admin analytics and management lists

### Stateful Widgets
- `SplashScreen` uses `StatefulWidget` for timed animation
- Payment pages use form state and async button state
- Cart and checkout flows manage local selection state and loading indicators

## 5. Design and Theming

### Theme System
- App theme is centralized in `lib/core/theme/app_theme.dart`
- Style constants are stored in:
  - `AppColors`
  - `AppSpacing`
  - `AppTextStyles`

### Visual Style
- Rounded cards, soft shadows, and bright accent colors are consistent across screens
- Many screens use dark background panels with contrasting text and accent highlights
- Item cards and action buttons use elevated containers and strong corner radius for a modern mobile look

## 6. Behavior and Interaction Patterns

- Product interactions are immediate: add to wishlist or cart updates Firestore quickly
- Checkout is gated by stock validation and requires a payment OTP
- Orders are created only after payment session verification
- Admin UI supports real-time data updates via Firestore streams and receptive actions

## 7. Maintenance Notes

- Screen widgets are designed to be composable, so new payment or product flows should reuse existing form and card components
- Service classes centralize backend logic and are the right location for behavior changes such as stock validation, order rules, or payment session lifecycle updates
- The app currently mixes direct Firestore operations and callable cloud functions; sensitive admin operations should remain behind secure callables
