# Architecture - Application Sajda

## Concept
Application islamique de développement personnel permettant aux utilisateurs de gagner des hassanates par des actions spirituelles (dons, récitations du Coran, dhikr).

## Palette de Couleurs
- **Vert émeraude profond** (#1B5E20) - Couleur dominante, spiritualité islamique
- **Or rose métallique** (#D4AF37) - Accents nobles pour récompenses
- **Blanc nacré** (#FAFAFA) - Fond principal, pureté
- **Bleu nuit mystique** (#1A237E) - Éléments de profondeur spirituelle
- **Gradient aurore** - Rose poudré au violet doux pour les prières

## Structure de l'Application

### Écrans Principaux
1. **Page d'Accueil** - Dashboard avec compteur de hassanat et actions quotidiennes
2. **Actions Quotidiennes** - Prière, Dhikr, Charité, Lecture Coran
3. **Profil Spirituel** - Niveaux, statistiques, badges
4. **Défis** - Challenges spirituels et récompenses

### Modèles de Données
- **Utilisateur** - Nom, niveau spirituel, hassanat total, streak
- **Action** - Type, points hassanat, description, icône
- **Badge** - Nom, description, condition d'obtention
- **Défi** - Nom, objectif, récompense, durée

### Fonctionnalités Clés
- Système de gamification spirituelle avec niveaux
- Compteur de hassanat en temps réel
- Actions quotidiennes avec points
- Badges et récompenses
- Streaks pour habitudes quotidiennes
- Design glassmorphisme avec motifs islamiques

### Niveaux Spirituels
1. Serviteur dévoué (0-99 hassanat)
2. Aspirant (100-499 hassanat)
3. Pieux (500-1499 hassanat)
4. Bienfaisant (1500-4999 hassanat)
5. Rapproché d'Allah (5000+ hassanat)

### Actions et Récompenses
- **Prière quotidienne** - 10 hassanat par prière
- **Dhikr** - 5 hassanat per session
- **Lecture Coran** - 20 hassanat per lecture
- **Charité/Don** - 30 hassanat per don
- **Bonnes actions** - 15 hassanat per action

## Implémentation Technique
- Navigation avec BottomNavigationBar
- État local avec SharedPreferences
- Design Material 3 avec thème personnalisé
- Animations subtiles et micro-interactions
- Support RTL pour l'arabe