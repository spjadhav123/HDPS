// lib/features/parent/razorpay_web_impl.dart
import 'dart:js' as js;

void openRazorpayWeb(Map<String, dynamic> options, Function(Map<dynamic, dynamic>) onSuccess, Function(String) onError) {
  final jsOptions = js.JsObject.jsify(options);
  
  js.context.callMethod('openRazorpayCheckout', [
    jsOptions,
    js.allowInterop((paymentId, orderId, signature) {
      onSuccess({
        'paymentId': paymentId,
        'orderId': orderId,
        'signature': signature,
      });
    }),
    js.allowInterop((errorDescription) {
      onError(errorDescription.toString());
    }),
  ]);
}
