# Configuration Google Play Store pour les achats in-app

## Étapes pour configurer les produits dans Google Play Console

### 1. Accéder à Google Play Console
- Connectez-vous à [Google Play Console](https://play.google.com/console)
- Sélectionnez votre application Sajda

### 2. Créer les produits d'abonnement

#### A. Accès à Vie (Achat unique)
- Allez dans **Monétisation** > **Produits**
- Cliquez sur **Créer un produit**
- **ID du produit** : `lifetime_premium`
- **Nom** : Accès Premium à Vie
- **Description** : Débloquez toutes les fonctionnalités premium de Sajda avec un seul paiement
- **Prix** : 10,99 € (ou votre prix préféré)
- **Type** : Produit géré (non consommable)

#### B. Abonnement Mensuel
- Allez dans **Monétisation** > **Abonnements**
- Cliquez sur **Créer un abonnement**
- **ID du produit** : `monthly_premium`
- **Nom** : Sajda Premium Mensuel
- **Description** : Accès complet aux fonctionnalités premium, renouvelé automatiquement chaque mois
- **Prix de base** : 2,99 € / mois
- **Période d'abonnement** : 1 mois
- **Essai gratuit** : 7 jours (optionnel)

#### C. Abonnement Annuel
- **ID du produit** : `yearly_premium`
- **Nom** : Sajda Premium Annuel
- **Description** : Économisez avec l'abonnement annuel - Accès complet aux fonctionnalités premium
- **Prix de base** : 19,99 € / an
- **Période d'abonnement** : 1 an
- **Essai gratuit** : 7 jours (optionnel)

### 3. Configuration des licences de test
- Allez dans **Configuration** > **Licences de test**
- Ajoutez vos comptes de test pour pouvoir tester les achats sans être facturé

### 4. Télécharger et publier l'APK
- Compilez votre application avec `flutter build apk --release`
- Téléchargez l'APK dans la **Console de test interne** ou **Test fermé**
- Activez les produits créés

### 5. Vérification des revenus
- Les revenus des achats seront automatiquement crédités sur votre compte développeur Google Play
- Google prend une commission de 30% sur les achats in-app et abonnements
- Les revenus sont généralement versés mensuellement après déduction des frais et taxes

### 6. Gestion des abonnements
- Les abonnements sont gérés automatiquement par Google Play
- Les utilisateurs peuvent annuler leurs abonnements via le Play Store
- Vous recevrez des notifications webhook pour les changements d'abonnement

## Important
- Les ID des produits (`lifetime_premium`, `monthly_premium`, `yearly_premium`) doivent correspondre exactement à ceux définis dans le code
- Une fois publiés, les ID des produits ne peuvent plus être modifiés
- Testez toujours en mode test avant la publication

## Suivi des revenus
- Consultez **Rapports de revenus** dans Google Play Console
- Exportez les données pour votre comptabilité
- Configurez des alertes pour surveiller les performances