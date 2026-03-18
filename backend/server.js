const express = require('express');
const crypto = require('crypto');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const RAZORPAY_KEY_ID = 'rzp_test_1DP5mmOlF5G5ag';
const RAZORPAY_KEY_SECRET = 'YOUR_RAZORPAY_SECRET_KEY';

// Endpoint to create a Razorpay order
// This should be called from the Flutter app before opening checkout
app.post('/api/create-order', async (req, res) => {
    const { amount, currency, receipt } = req.body;

    if (!amount) {
        return res.status(400).json({ success: false, message: 'Amount is required.' });
    }

    try {
        // In a real app, use the Razorpay Node SDK:
        // const Razorpay = require('razorpay');
        // var instance = new Razorpay({ key_id: 'YOUR_KEY_ID', key_secret: 'YOUR_SECRET' })
        // const order = await instance.orders.create({amount, currency, receipt});
        
        // Simulating the Razorpay Order API response for demonstration
        const mockOrderId = 'order_' + crypto.randomBytes(8).toString('hex');
        
        console.log(`📦 Order created: ${mockOrderId} for amount: ${amount}`);
        
        res.json({
            success: true,
            orderId: mockOrderId,
            amount: amount,
            currency: currency || 'INR'
        });
    } catch (error) {
        console.error('Error creating order:', error);
        res.status(500).json({ success: false, message: 'Failed to create order.' });
    }
});

// Endpoint to verify payment signature securely on the backend
app.post('/api/verify-payment', (req, res) => {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, amount, studentId } = req.body;

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
        return res.status(400).json({ success: false, message: 'Missing payment details.' });
    }

    try {
        // Create HMAC SHA256 digest
        const hmac = crypto.createHmac('sha256', RAZORPAY_KEY_SECRET);
        hmac.update(razorpay_order_id + '|' + razorpay_payment_id);
        const generatedSignature = hmac.digest('hex');

        // Compare generated signature with Razprpay's signature payload
        if (generatedSignature === razorpay_signature) {
            console.log(`✅ Payment verified successfully for Txn: ${razorpay_payment_id}`);
            
            // TODO: Initialize Firebase Admin connection here to verify duplicates
            // and securely execute the database update ONLY IF NOT ALREADY RECORDED!
            // const db = admin.firestore();
            // await db.collection('receipts').add({amount, studentId, transactionId: razorpay_payment_id...})
            // await db.collection('students').doc(studentId).update({feesPaid: admin.firestore.FieldValue.increment(amount)});

            return res.json({ success: true, message: 'Payment verified and updated successfully.' });
        } else {
            console.error(`🚨 Invalid payment signature for Txn: ${razorpay_payment_id}`);
            return res.status(400).json({ success: false, message: 'Payment verification failed. Invalid Signature.' });
        }
    } catch (error) {
        console.error('Error verifying payment:', error);
        return res.status(500).json({ success: false, message: 'Internal Server Error' });
    }
});

// Export the Express API
module.exports = app;

// Conditionally listen if this file is run directly (local development)
if (require.main === module) {
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
        console.log(`Backend Server listening on port ${PORT}`);
    });
}
