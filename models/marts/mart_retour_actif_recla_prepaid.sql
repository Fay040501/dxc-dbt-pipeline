{{ config(materialized='table') }}

-- Agrégation retour actif réclamations prepaid par jour et campagne

SELECT
    jour,
    mois_recla,
    campagne,
    COUNT(DISTINCT nd) AS nb_reclamations,
    COUNT(DISTINCT CASE WHEN statut_traitement = 'TRAITE' THEN nd END) AS nb_traites,
    COUNT(DISTINCT CASE WHEN statut_traitement = 'ASSIGNE' THEN nd END) AS nb_assignes,
    COUNT(DISTINCT CASE WHEN statut_traitement = 'NON ASSIGNE' THEN nd END) AS nb_non_assignes,
    COUNT(DISTINCT CASE WHEN statut_appel = 'DECROCHE' THEN nd END) AS nb_decroches,
    SUM(est_actif_au_appel) AS nb_actifs_au_appel,
    SUM(est_actif_aujourdhui) AS nb_actifs_aujourdhui,
    COUNT(DISTINCT CASE WHEN a_recharge = 1 THEN nd END) AS nb_recharges,
    SUM(montant_recharge) AS montant_total,
    COUNT(DISTINCT CASE WHEN statut_appel = 'DECROCHE' AND a_recharge = 1 THEN nd END) AS nb_decroche_et_recharge,
    COUNT(DISTINCT CASE WHEN statut_appel = 'DECROCHE' AND est_actif_aujourdhui = 1 THEN nd END) AS nb_decroche_et_actif,
    COUNT(DISTINCT CASE WHEN statut_traitement = 'TRAITE' AND a_recharge = 1 THEN nd END) AS nb_traite_et_recharge,
    ROUND(AVG(delai_assignation)::numeric, 1) AS delai_moyen_assignation,
    ROUND(AVG(delai_traitement)::numeric, 1) AS delai_moyen_traitement,
    ROUND(COUNT(DISTINCT CASE WHEN statut_traitement = 'TRAITE' THEN nd END)::numeric * 100.0 / NULLIF(COUNT(DISTINCT nd), 0)::numeric, 1) AS taux_traitement,
    ROUND(COUNT(DISTINCT CASE WHEN statut_appel = 'DECROCHE' THEN nd END)::numeric * 100.0 / NULLIF(COUNT(DISTINCT nd), 0)::numeric, 1) AS taux_decroche,
    ROUND(COUNT(DISTINCT CASE WHEN a_recharge = 1 THEN nd END)::numeric * 100.0 / NULLIF(COUNT(DISTINCT nd), 0)::numeric, 1) AS taux_retour,
    ROUND(SUM(est_actif_aujourdhui)::numeric * 100.0 / NULLIF(COUNT(DISTINCT nd), 0)::numeric, 1) AS taux_actif_aujourdhui

FROM {{ ref('int_recla_parc_prepaid') }}
GROUP BY jour, mois_recla, campagne
ORDER BY jour, campagne
