echo "Building Flutter web project..."
flutter build web --release
echo "Deploying to Firebase Hosting..."
firebase deploy --only hosting
echo "Deployment complete!"