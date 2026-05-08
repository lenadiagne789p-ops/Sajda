# Déploiement Web de l'Application Sajda

## Option 1: Firebase Hosting (Recommandé)

### Prérequis
1. Installer Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Se connecter à Firebase:
```bash
firebase login
```

### Étapes de déploiement

1. **Compiler l'application pour le web:**
```bash
flutter build web --release
```

2. **Initialiser Firebase (si première fois):**
```bash
firebase init hosting
```
- Choisir `build/web` comme répertoire public
- Configurer comme application single-page (SPA): Oui
- Ne pas réécrire `index.html`

3. **Déployer:**
```bash
firebase deploy --only hosting
```

4. **URL de l'application:**
Votre application sera accessible à l'adresse:
`https://sajda-app.web.app` ou `https://sajda-app.firebaseapp.com`

## Option 2: GitHub Pages

1. **Créer un repository GitHub pour votre projet**

2. **Compiler l'application:**
```bash
flutter build web --base-href "/nom-du-repo/"
```

3. **Pousser le dossier build/web vers la branche gh-pages**

## Option 3: Netlify

1. **Compiler l'application:**
```bash
flutter build web --release
```

2. **Glisser-déposer le dossier `build/web` sur netlify.com**

3. **Configuration des redirects (créer _redirects dans build/web):**
```
/*    /index.html   200
```

## Optimisations Web

L'application a été optimisée pour le web avec:
- Configuration PWA complète
- Métadonnées SEO
- Icônes adaptatives
- Configuration de cache
- Support hors-ligne

## Test Local

Pour tester localement:
```bash
flutter run -d chrome --web-renderer html
```

Ou servir le build:
```bash
flutter build web --release
cd build/web
python -m http.server 8000
```

Puis ouvrir: http://localhost:8000