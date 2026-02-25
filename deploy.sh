firebase use dev
echo "Building Flutter web project in DEV..."
flutter build web --release --dart-define=FIREBASE_ENV=dev
echo "Deploying to Firebase Hosting..."
firebase deploy --only hosting
echo "Deployment complete!"