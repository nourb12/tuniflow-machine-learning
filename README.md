# TuniFlow Machine Learning

Service Python de scoring et de prediction pour TuniFlow. Il expose une API FastAPI consommee par le backend .NET et regroupe les scripts d'entrainement des modeles.

## Perimetre

- Prediction du risque de retard de paiement avec comparaison entre regression logistique et LightGBM.
- Detection d'anomalies sur les transactions d'entreprise avec Isolation Forest.
- Evaluation de transactions de reference au format ULB avec Isolation Forest ou Local Outlier Factor.
- Scoring de qualite des champs extraits par OCR.
- Projection de tresorerie a partir des probabilites de retard et des echeances connues.
- Schema PostgreSQL d'entrainement isole dans `ml_training`.

Les jeux de donnees, les rapports d'evaluation et les modeles entraines sont produits localement et ne sont pas versionnes. Les scripts proposent une source synthetique reproductible pour les demonstrations. Les donnees reelles ne doivent jamais etre ajoutees au depot.

## Installation

Depuis la racine du depot, dans PowerShell :

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Editez `.env` localement. Configurez une cle `TUNIFLOW_ML_API_KEY` qui correspond a la cle interne configuree dans le backend. Ne partagez jamais le fichier `.env`.

## Entrainement

Les jeux synthetiques permettent de tester les pipelines sans exporter de donnees d'entreprise :

```powershell
.\.venv\Scripts\python.exe .\train_late_payment_model.py --source synthetic
.\.venv\Scripts\python.exe .\train_transaction_anomaly_model.py --source synthetic
.\.venv\Scripts\python.exe .\train_ocr_error_model.py --rows 4500
```

La prediction de retard peut aussi etre entrainee depuis la vue PostgreSQL `ml_training.retard_features`. Pour cela, executez d'abord `sql/001_create_ml_training_schema.sql` sur une base de developpement, puis configurez `ML_DATABASE_URL` dans `.env` et lancez le script sans `--source synthetic`.

Les modeles sont crees sous `models/`; les jeux de donnees et resultats sont ecrits sous `data/` et `reports/`. Ces chemins sont exclus de Git.

## Lancement de l'API

```powershell
.\Start-Local.ps1
```

Ajoutez `-Reload` pour le rechargement automatique en developpement. L'API ecoute sur `http://127.0.0.1:8001`; la documentation interactive est disponible sur `/docs`. La route `/health` ne demande pas de cle. Les routes de prediction exigent l'en-tete `X-Internal-Api-Key`.

Les modeles requis par chaque route doivent avoir ete entraines avant son utilisation. L'API renvoie un statut 503 si un modele ou un rapport necessaire manque.

## Endpoints principaux

| Methode | Route | Usage |
| --- | --- | --- |
| GET | `/health` | Etat du service et disponibilite des modeles |
| POST | `/predict/late-payment` | Probabilite de retard de paiement |
| POST | `/predict/transaction-anomaly` | Scoring d'une transaction de reference |
| POST | `/anomaly/company-report` | Detection d'anomalies dans un portefeuille d'entreprise |
| POST | `/predict/ocr-error` | Evaluation de coherence des champs OCR |
| POST | `/forecast/cash` | Projection de tresorerie hebdomadaire |

Consultez `/docs` pour les schemas complets des requetes et reponses.

## Limites d'interpretation

Les resultats obtenus sur des donnees synthetiques ou de reference valident le fonctionnement technique des pipelines, mais ne demontrent pas une performance sur les donnees reelles des entreprises. Le scoring OCR est entraine sur des erreurs generees. Toute utilisation decisionnelle requiert un jeu de validation representatif, une revue metier et un suivi des performances.
