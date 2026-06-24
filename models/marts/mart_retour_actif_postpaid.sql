{{ config(materialized='table') }}

-- Agrégation retour actif postpaid par jour et campagne

SELECT
    jour,
    mois_appel,
    campagne,
    COUNT(DISTINCT nd) AS nb_contactes,
    SUM(CASE WHEN disponibilite_client = 'Le client a décroché.' THEN 1 ELSE 0 END) AS nb_decroches,
    SUM(est_actif_au_appel) AS nb_actifs_au_appel,
    SUM(est_actif_aujourdhui) AS nb_actifs_aujourdhui,
    COUNT(DISTINCT CASE WHEN a_paye = 1 THEN nd END) AS nb_payes,
    SUM(montant_paiement) AS montant_total,
    COUNT(DISTINCT CASE WHEN disponibilite_client = 'Le client a décroché.' AND a_paye = 1 THEN nd END) AS nb_decroche_et_paye,
    COUNT(DISTINCT CASE WHEN disponibilite_client = 'Le client a décroché.' AND est_actif_aujourdhui = 1 THEN nd END) AS nb_decroche_et_actif,
    ROUND(COUNT(DISTINCT CASE WHEN a_paye = 1 THEN nd END)::numeric * 100.0 / NULLIF(COUNT(DISTINCT nd), 0)::numeric, 1) AS taux_retour,
    ROUND(SUM(CASE WHEN disponibilite_client = 'Le client a décroché.' THEN 1 ELSE 0 END)::numeric * 100.0 / NULLIF(COUNT(DISTINCT nd), 0)::numeric, 1) AS taux_decroche,
    ROUND(SUM(est_actif_au_appel)::numeric * 100.0 / NULLIF(COUNT(DISTINCT nd), 0)::numeric, 1) AS taux_actif_au_appel,
    ROUND(SUM(est_actif_aujourdhui)::numeric * 100.0 / NULLIF(COUNT(DISTINCT nd), 0)::numeric, 1) AS taux_actif_aujourdhui

FROM {{ ref('int_tts_paiements_postpaid') }}
GROUP BY jour, mois_appel, campagne
