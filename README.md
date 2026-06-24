# dxc-dbt-pipeline

> Pipeline de transformation de données pour le suivi du recouvrement et de la rétention client FTTH chez Orange Côte d'Ivoire — construit avec **dbt + PostgreSQL**.

---

## Contexte

Dans le cadre de la Direction de l'Expérience Client (DXC) d'Orange CI, ce projet remplace un système de 10 vues matérialisées PostgreSQL gérées manuellement par un pipeline **dbt** documenté, testé et versionné.

Les données proviennent de deux sources :
- **Starburst/Trino** — parc clients FTTH prepaid et postpaid, rechargements, paiements
- **MSurvey API** — campagnes de phoning TTS (Téléconseillers)

L'objectif : produire des tables agrégées prêtes pour Power BI, permettant aux directeurs de suivre en temps réel les taux de retour actif par campagne, par jour et par type de base.

---

## Architecture

```
Python / R (ETL)
    ↓
PostgreSQL (tables brutes)
    tb_tts · tb_reclamations · tb_ftth_prepaid · tb_ftth_postpaid
    tb_ftth_prepaid_recharges · tb_ftth_postpaid_paiements
    ↓
DBT (transformations)
    staging/       → nettoyage et typage
    intermediate/  → jointures et enrichissement
    marts/         → agrégations finales Power BI
    ↓
Power BI (dashboard directeurs)
```

---

## Structure du projet

```
dxc_project/
├── models/
│   ├── sources.yml                        # déclaration des 6 sources PostgreSQL
│   ├── staging/
│   │   ├── stg_tts_prepaid.sql            # appels TTS campagnes prepaid
│   │   ├── stg_tts_postpaid.sql           # appels TTS campagnes postpaid
│   │   ├── stg_reclamations.sql           # réclamations filtrées
│   │   ├── stg_recla_prepaid.sql          # réclamations prepaid
│   │   └── stg_recla_postpaid.sql         # réclamations postpaid
│   ├── intermediate/
│   │   ├── int_tts_parc_prepaid.sql       # TTS × parc prepaid (est_actif_au_appel)
│   │   ├── int_tts_recharges_prepaid.sql  # + rechargements mois courant
│   │   ├── int_tts_parc_postpaid.sql      # TTS × parc postpaid
│   │   ├── int_tts_paiements_postpaid.sql # + paiements mois courant
│   │   ├── int_recla_parc_prepaid.sql     # réclamations × parc prepaid
│   │   └── int_recla_parc_postpaid.sql    # réclamations × parc postpaid
│   └── marts/
│       ├── mart_reclamations.sql          # table réclamations (incrémental)
│       ├── mart_retour_actif_prepaid.sql  # KPIs TTS prepaid → Power BI
│       ├── mart_retour_actif_postpaid.sql # KPIs TTS postpaid → Power BI
│       ├── mart_retour_actif_recla_prepaid.sql
│       ├── mart_retour_actif_recla_postpaid.sql
│       └── schema.yml                     # 27 tests de qualité
├── logs/                                  # logs horodatés des exécutions
├── run_dbt.py                             # wrapper Python + notification Gmail
└── dbt_project.yml
```

---

## Modèles DBT

| Modèle | Type | Rôle |
|--------|------|------|
| `stg_*` | view | Nettoyage, typage, DISTINCT ON par client/jour |
| `int_tts_parc_*` | view | Jointure TTS × parc (statut actif au jour de l'appel et aujourd'hui) |
| `int_tts_recharges_prepaid` | view | Ajout rechargements mois courant |
| `int_tts_paiements_postpaid` | view | Ajout paiements mois courant |
| `int_recla_parc_*` | view | Jointure réclamations × parc + transactions |
| `mart_reclamations` | incremental | Table réclamations — traitements agents préservés |
| `mart_retour_actif_prepaid` | table | Agrégation KPIs prepaid par jour/campagne |
| `mart_retour_actif_postpaid` | table | Agrégation KPIs postpaid par jour/campagne |
| `mart_retour_actif_recla_prepaid` | table | Agrégation KPIs réclamations prepaid |
| `mart_retour_actif_recla_postpaid` | table | Agrégation KPIs réclamations postpaid |

---

## Logique métier

### Prepaid vs Postpaid

| | Prepaid | Postpaid |
|--|---------|----------|
| Campagnes | PREPAID · PREPAID CRITIQUE · PREPAID REVEIL · WINBACK | FACTURE OUVERTE · SUSPENSION |
| Statut actif | `date_expiration > date_appel` | `etat = 'Actif'` |
| Action attendue | Rechargement | Paiement facture |
| Source transaction | `tb_ftth_prepaid_recharges` | `tb_ftth_postpaid_paiements` |

### KPIs calculés (marts finaux)

- `nb_contactes` — clients distincts contactés par jour/campagne
- `nb_decroches` — clients ayant décroché
- `nb_actifs_au_appel` — actifs au moment exact de l'appel
- `nb_actifs_aujourdhui` — actifs à la date du refresh
- `nb_recharges / nb_payes` — ayant agi financièrement ce mois
- `taux_retour · taux_decroche · taux_actif_au_appel · taux_actif_aujourdhui`

### Réclamations (en plus)

- `delai_moyen_assignation` — délai moyen entre création et assignation
- `delai_moyen_traitement` — délai moyen entre création et traitement
- `taux_traitement` — part des réclamations traitées

---

## Tests qualité

27 tests automatisés définis dans `schema.yml` :

```
not_null     → colonnes clés des 5 marts
unique       → id_hash dans mart_reclamations
accepted_values → statut_traitement (NON ASSIGNE · ASSIGNE · TRAITE)
              → campagnes prepaid et postpaid
```

```bash
dbt test
# Done. PASS=27 WARN=0 ERROR=0
```

---

## Installation

### Prérequis

- Python 3.10+
- PostgreSQL 14+
- dbt-postgres

```bash
pip install dbt-postgres
```

### Configuration

1. Cloner le repo :
```bash
git clone https://github.com/Fay040501/dxc-dbt-pipeline.git
cd dxc-dbt-pipeline
```

2. Configurer le profil dbt dans `~/.dbt/profiles.yml` :
```yaml
dxc_project:
  outputs:
    dev:
      type: postgres
      host: localhost
      port: 5432
      user: postgres
      password: <votre_mot_de_passe>
      dbname: <votre_base>
      schema: public
      threads: 4
  target: dev
```

3. Vérifier la connexion :
```bash
dbt debug
```

4. Lancer le pipeline :
```bash
dbt run
dbt test
```

---

## Automatisation

Le script `run_dbt.py` orchestre l'exécution complète et envoie une notification Gmail :

```bash
python run_dbt.py
```

Il produit :
- Un **fichier log horodaté** dans `logs/`
- Un **mail HTML** avec le statut (succès/erreur), la durée, et le détail de chaque modèle

Planification via Windows Task Scheduler :

```
Programme : python
Arguments : run_dbt.py
Dossier   : C:\chemin\vers\dxc_project
Déclencheur : quotidien à 06h00
```

---

## Stack technique

| Outil | Usage |
|-------|-------|
| dbt-postgres 1.10 | Transformation et orchestration |
| PostgreSQL 14 | Base de données |
| Python 3.10 | ETL (Starburst → PostgreSQL) + wrapper dbt |
| Power BI | Dashboard directeurs (DirectQuery) |
| Git / GitHub | Versionning |
| Windows Task Scheduler | Automatisation quotidienne |

---

## Auteur

**Fofana Alassane Yahaya**
Data Analyst — Direction de l'Expérience Client, Orange Côte d'Ivoire
Master 2 Ingénierie Statistique et Data Science — INSSEDS

[GitHub](https://github.com/Fay040501) · [LinkedIn](#)