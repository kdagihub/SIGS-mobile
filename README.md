# SIGS-mobile
SIGS version mobile


Statut : flutter analyze = 0 erreurs, flutter build web --release = succès.

Pour tester l'app, tu peux lancer flutter run -d chrome depuis le dossier mobile/SIGS-mobile/, ou flutter run si tu as un émulateur Android configuré. L'app démarre sur le splash screen, puis navigue vers l'écran de recherche MS-NIUS.

flutter run -d chrome --web-port=3000


# #### BUILD AND DEPLOY ON LOCAL

# 1 - Build
flutter clean 2>&1 &&
flutter pub get 2>&1 
flutter build apk --release 2>&1

# 2 - Copie on desktop

cp "/home/devfullstack/Bureau/PROJET DSI/CIA_SIGS/SIGS-v0.0/mobile/SIGS-mobile/build/app/outputs/flutter-apk/app-release.apk" ~/Bureau/SIGS-Mobile.apk && ls -lh ~/Bureau/SIGS-Mobile.apk