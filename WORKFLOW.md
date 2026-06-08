# WORKFLOW.md

## 1. App Launch Flow

1. `lib/main.dart` initializes Firebase with `firebase_options.dart`.
2. `ProviderScope` is set up for Riverpod state management.
3. The `JerseyDripApp` loads `SplashScreen` as the initial route.
4. `SplashScreen` displays the brand logo and transitions to `AuthScreen` after 3 seconds.

## 2. User Authentication Flow

### Sign In

- `AuthScreen` displays login and sign-up forms.
- Email and password are validated inside the form.
- `AuthService.signIn` authenticates with Firebase Auth.
- On success, the user is taken to the home/customer flow.

### Sign Up

- The user switches to sign-up mode on `AuthScreen`.
- Submitting the sign-up form triggers `AuthOtpController.sendSignupOtp`.
- `EmailOtpService` sends an OTP email via EmailJS.
- `OtpService.createOtpRecord` stores a verification session in Firestore under `otp_verifications`.
- The app navigates to `OTPVerificationScreen` with `OtpVerificationArgs.signup`.
- The user enters a 6-digit OTP and submits.
- `AuthOtpController.verifySignupOtp` calls `OtpService.verifyOtp`, verifies the OTP, and completes signup.
- `AuthService.signUp` creates a Firebase Auth user and persists the user profile via `ProfileService`.

### Forgot Password

- `ForgotPasswordScreen` asks for an email.
- On submit, Firebase Auth sends a password reset email.
- The user receives instructions outside the app.

## 3. Customer Shopping Flow

### Homepage

- `HomeScreen` shows category chips, a search bar, and a product grid.
- `ProductService` streams Firestore `products` and normalizes fields for UI.
- The user can filter by search text and category.
- `ProductCard` displays product image, name, price, availability, wishlist state, and add-to-cart control.

### Product Detail

- `ProductDetailsPage` renders a chosen product with size options and quantity selector.
- `WishlistService.toggleProduct` updates the current user's wishlist.
- `CartService.addItem` adds a product to `users/{uid}/cart` with selected size and quantity.
- `Buy Now` sends the user to `OrderSetupPage` with a one-item purchase path.

### Cart and Checkout

- `CartPage` consumes `CartService.cartStream` and `WishlistService.wishlistProductIdsStream`.
- The user selects cart items, modifies quantity or size, and removes items.
- Selected items flow into `OrderSetupPage` when the user taps checkout.
- `OrderSetupPage` loads the user's saved address from `ProfileService.currentUserProfileStream`.
- The user confirms the shipping address and proceeds to `CheckoutPage`.

## 4. Payment and Order Finalization

### Payment Options

- `CheckoutPage` shows the selected products and total summary.
- The user chooses between `bKash` and card payment.
- Pressing a payment option opens `BkashPaymentPage` or `CardPaymentPage`.

### Payment Session Creation

- Payment pages collect mock transaction details for simulation.
- `PaymentSessionService.createPaymentSession` creates a Firestore `payment_sessions` record.
- The session contains `pending_verification` and is associated with the user, selected items, and order metadata.
- An OTP is sent to the user's email via the same OTP infrastructure.

### OTP Verification and Order Creation

- `OTPVerificationScreen` validates a payment OTP via `AuthOtpController.verifyPaymentOtp`.
- Upon success, the app transitions to `PaymentSuccessPage`.
- `PaymentSuccessPage` verifies the session using `PaymentSessionService.isCurrentUserSessionVerified`.
- `OrderService.createPaidOrder` runs a Firestore transaction to:
  - write the order document to `users/{uid}/orders`
  - decrement stock counts for purchased products
  - remove purchased items from the cart
  - mark the payment session as completed
- `OrderReceiptPage` displays the final order receipt and provides navigation back to home or orders.

## 5. Order History and Profile Flow

- `OrdersPage` streams the current user's order history from `users/{uid}/orders`.
- `OrderDetailsPage` displays line items, totals, shipping address, and order metadata.
- `ProfilePage` shows the current user profile from `ProfileService.currentUserProfileStream`.
- `EditProfilePage` allows changing the user name and address.
- `AuthService.signOut` logs the user out and returns them to authentication.

## 6. Admin Flow

### Entry

- Admin features are grouped under `lib/admin/admin_panel_screen.dart`.
- The admin panel includes views for dashboard analytics, orders, products, inventory, and users.

### Dashboard

- `AdminService.getDashboardStatsStream` calculates product count, order count, revenue, and other metrics.
- Metrics are displayed in `dashboard_view.dart`.

### Order Management

- `AdminService.watchOrders` streams order documents.
- Admins can update order status and review order details.

### Product Management

- `AdminService.watchProducts` streams product documents for catalog management.
- Admins can delete products using callable cloud functions.

### Inventory and User Roles

- `AdminService.updateProductSizeStock` adjusts per-size stock values in product documents.
- `AdminService.updateUserRole` changes user roles using secure callable functions.
- `AdminService.watchUsers` streams user profile documents and role metadata.

## 7. Backend Interaction Points

### Firestore Collections

- `products`
- `users/{uid}` with `cart`, `wishlist`, `orders`
- `payment_sessions`
- `otp_verifications`

### Cloud Functions

- Callable actions for sensitive admin operations such as deleting products and updating roles
- These functions are invoked through `AdminService`

### Email OTP

- `EmailOtpService` uses EmailJS templates to deliver one-time passcodes
- The OTP service is shared between signup verification and payment verification paths

## 8. Observability and Validation

- The app relies on real-time Firestore streams for live updates
- `StreamBuilder` widgets across the app keep UI synchronized with backend data
- Navigation is largely imperative using `Navigator.push`, `Navigator.pop`, and route generation for OTP verification
- Stock validation and size availability checks are performed in service code before checkout/payment flows

## 9. Deployment Considerations

- Firebase configuration and platform-specific settings are required in `android/`, `ios/`, `web/`
- `emailjs` configuration must be valid for OTP email delivery
- The project does not include backend function source here, but expects callable Firebase functions to exist for admin operations

## 10. Recommended Next Steps

- Confirm Firebase `google-services.json` / `GoogleService-Info.plist` and EmailJS configuration
- Review `lib/core/theme/` for app-wide visual consistency
- Inspect `lib/admin/` views and the provider state flow if extending admin capabilities
- Test the full signup-to-order flow with a live Firebase project to validate OTP and order creation logic
