// FCM Push Notification Testing Script
// Install dependencies: npm install firebase-admin
// Run: FIREBASE_SERVICE_ACCOUNT_PATH=C:\Secure\HireMeBuddy\your-key.json node test_fcm_notifications.js

const admin = require('firebase-admin');
const readline = require('readline');
const fs = require('fs');

// SECURITY: Load service account from environment variable
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
if (!serviceAccountPath) {
  console.error('ERROR: FIREBASE_SERVICE_ACCOUNT_PATH environment variable not set');
  console.error('Set it with: set FIREBASE_SERVICE_ACCOUNT_PATH=C:\\Secure\\HireMeBuddy\\your-service-account.json');
  process.exit(1);
}

if (!fs.existsSync(serviceAccountPath)) {
  console.error('ERROR: Service account file not found:', serviceAccountPath);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'hiremebuddy-850a8'
});

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

console.log('\n🔔 FCM Push Notification Testing Tool');
console.log('=====================================\n');

function prompt(question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer);
    });
  });
}

async function sendNotification(token, title, body, data = {}) {
  try {
    console.log('\n🚀 Sending FCM notification...');
    
    const message = {
      token: token,
      notification: {
        title: title,
        body: body
      },
      data: data,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK'
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log('✅ Notification sent successfully!');
    console.log('   Message ID:', response);
    return true;
  } catch (error) {
    console.error('❌ Failed to send notification');
    console.error('   Error:', error.message);
    if (error.code) {
      console.error('   Error Code:', error.code);
    }
    return false;
  }
}

function showInstructions() {
  console.log('\n📱 To get your FCM token:');
  console.log('   1. Run the app: flutter run');
  console.log('   2. Look for console log: "ℹ️ FCM token: ..."');
  console.log('   3. Copy the entire token (starts with "f" or "c")');
  console.log('   4. Paste it when prompted\n');
}

async function showMenu() {
  console.log('\n📋 Test Options:');
  console.log('   1. Send custom test notification');
  console.log('   2. Send booking notification');
  console.log('   3. Send message notification');
  console.log('   4. Send payment notification');
  console.log('   5. Send provider verification notification');
  console.log('   6. Show FCM token instructions');
  console.log('   7. Exit\n');
}

async function main() {
  while (true) {
    await showMenu();
    const choice = await prompt('Select option (1-7): ');

    if (choice === '7') {
      console.log('\n👋 Goodbye!\n');
      rl.close();
      process.exit(0);
    }

    if (choice === '6') {
      showInstructions();
      continue;
    }

    const token = await prompt('\nEnter FCM token: ');
    if (!token || token.trim() === '') {
      console.log('❌ Token cannot be empty');
      continue;
    }

    let success = false;

    switch (choice) {
      case '1':
        const title = await prompt('Enter notification title: ');
        const body = await prompt('Enter notification body: ');
        success = await sendNotification(
          token.trim(),
          title || 'Test Notification',
          body || 'This is a test notification'
        );
        break;

      case '2':
        success = await sendNotification(
          token.trim(),
          '🎉 New Booking Request!',
          'You have a new booking request for Plumbing Service',
          {
            type: 'booking',
            booking_id: 'test-booking-' + Date.now(),
            action: 'new_booking',
            client_name: 'John Doe',
            service_name: 'Plumbing Service'
          }
        );
        break;

      case '3':
        success = await sendNotification(
          token.trim(),
          '💬 New Message from Sarah',
          'Hey, are you available tomorrow morning?',
          {
            type: 'message',
            chat_id: 'test-chat-' + Date.now(),
            sender_id: 'test-user-123',
            sender_name: 'Sarah Johnson'
          }
        );
        break;

      case '4':
        success = await sendNotification(
          token.trim(),
          '💰 Payment Received',
          'You received N$150.00 for Plumbing Service',
          {
            type: 'payment',
            payment_id: 'test-payment-' + Date.now(),
            amount: '150.00',
            currency: 'NAD',
            booking_id: 'booking-123'
          }
        );
        break;

      case '5':
        success = await sendNotification(
          token.trim(),
          '✅ Verification Complete',
          'Your provider profile has been verified! You can now accept bookings.',
          {
            type: 'verification',
            status: 'approved',
            verification_id: 'verify-' + Date.now()
          }
        );
        break;

      default:
        console.log('❌ Invalid option. Please select 1-7.');
    }

    if (success) {
      console.log('\n💡 Check your device for the notification!');
      console.log('   - If app is in foreground: notification banner appears');
      console.log('   - If app is in background: system notification appears');
      console.log('   - Check console logs for delivery confirmation');
    }
  }
}

// Start the tool
showInstructions();
main().catch((error) => {
  console.error('Fatal error:', error);
  rl.close();
  process.exit(1);
});
