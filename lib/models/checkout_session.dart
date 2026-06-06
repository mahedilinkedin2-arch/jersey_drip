import 'cart_item.dart';

class CheckoutSession {
  const CheckoutSession({required this.items, required this.totalPrice});

  final List<CartItem> items;
  final int totalPrice;
}

class PaymentResult {
  const PaymentResult({
    required this.session,
    required this.paymentMethod,
    required this.transactionId,
  });

  final CheckoutSession session;
  final String paymentMethod;
  final String transactionId;
}
