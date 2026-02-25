firebase use prod
echo "Building Flutter web project in PROD..."
flutter build web --release --dart-define=FIREBASE_ENV=prod
echo "Deploying to Firebase Hosting..."
firebase deploy --only hosting
echo "Deployment complete!"