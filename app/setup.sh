#!/usr/bin/env bash
# Gera as pastas android/, ios/ e web/ (o código em lib/ e o pubspec.yaml são mantidos) e instala dependências.
set -e
flutter create . --project-name petvida --org com.petvida --platforms=android,ios,web
flutter pub get
echo "Pronto. Leia a secção 'Configurar Android/iOS' do README (permissões e notificações)."
