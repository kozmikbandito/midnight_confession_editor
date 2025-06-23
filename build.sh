#!/usr/bin/env bash
# exit on error
set -o errexit

# Render'ın sunucusuna Flutter SDK'sını indirip kuruyoruz
git clone https://github.com/flutter/flutter.git --depth 1 --branch stable /opt/render/flutter
export PATH="$PATH:/opt/render/flutter/bin"

# Flutter'ın kurulduğunu doğrulayıp, bağımlılıkları indiriyoruz
flutter precache
flutter pub get

# Şimdi asıl build komutumuzu çalıştırıyoruz
echo "Building Flutter web..."
flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY