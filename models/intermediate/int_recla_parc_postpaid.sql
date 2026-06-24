
-- Réclamations postpaid enrichies avec statut actif + paiements

SELECT
    r.nd_clean AS nd,
    DATE(r.startdate) AS jour,
    DATE_TRUNC('month', r.startdate) AS mois_recla,
    r.campagne,
    r.statut_appel,
    r.statut_traitement,
    DATE_PART('day', r.date_assignation - r.startdate) AS delai_assignation,
    DATE_PART('day', r.date_traitement - r.startdate) AS delai_traitement,
    CASE
        WHEN p_jour.etat = 'Actif' THEN 1
        ELSE 0
    END AS est_actif_au_appel,
    CASE
        WHEN p_actuel.etat = 'Actif' THEN 1
        ELSE 0
    END AS est_actif_aujourdhui,
    CASE WHEN f.nd IS NOT NULL AND f.statut_fact = 'paye' THEN 1 ELSE 0 END AS a_paye,
    COALESCE(f.mnt_fact_mois_m, 0) AS montant_paiement

FROM {{ ref('stg_recla_postpaid') }} r

LEFT JOIN {{ source('dxc', 'tb_ftth_postpaid') }} p_jour
    ON r.nd_clean = p_jour.nd
    AND p_jour.date_id = DATE(r.startdate)

LEFT JOIN (
    SELECT DISTINCT ON (nd) nd, etat
    FROM {{ source('dxc', 'tb_ftth_postpaid') }}
    ORDER BY nd, date_id DESC
) p_actuel ON r.nd_clean = p_actuel.nd

LEFT JOIN (
    SELECT DISTINCT ON (nd) nd, statut_fact, mnt_fact_mois_m
    FROM {{ source('dxc', 'tb_ftth_postpaid_paiements') }}
    WHERE date_paiement >= DATE_TRUNC('month', CURRENT_DATE)
      AND date_paiement < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    ORDER BY nd, date_paiement DESC
) f ON r.nd_clean = f.nd
