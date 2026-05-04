#!/bin/bash

echo "🚀 Déploiement de Sajda Web App"
echo "================================"

# Vérifier que Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé"
    exit 1
fi

# Nettoyer les builds précédents
echo "🧹 Nettoyage des builds précédents..."
flutter clean

# Récupérer les dépendances
echo "📦 Installation des dépendances..."
flutter pub get

# Compiler pour le web
echo "🔨 Compilation pour le web..."
flutter build web --release --web-renderer html

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de la compilation"
    exit 1
fi

echo "✅ Compilation réussie!"
echo ""
echo "Options de déploiement:"
echo "1. Firebase Hosting: firebase deploy --only hosting"
echo "2. GitHub Pages: Pusher build/web vers gh-pages"
echo "3. Netlify: Glisser-déposer build/web sur netlify.com"
echo ""
echo "📁 Fichiers compilés disponibles dans: build/web/"
echo ""
echo "Pour tester localement:"
echo "cd build/web && python -m http.server 8000"
echo "Puis ouvrir: http://localhost:8000"