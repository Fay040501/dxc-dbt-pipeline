
-- Réclamations prepaid enrichies avec statut actif + recharges

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
        WHEN TO_DATE(p_jour.date_expiration, 'DD/MM/YYYY') > DATE(r.startdate) THEN 1
        ELSE 0
    END AS est_actif_au_appel,
    CASE
        WHEN TO_DATE(p_actuel.date_expiration, 'DD/MM/YYYY') > CURRENT_DATE THEN 1
        ELSE 0
    END AS est_actif_aujourdhui,
    CASE WHEN rech.nd IS NOT NULL THEN 1 ELSE 0 END AS a_recharge,
    COALESCE(rech.montant_ttc, 0) AS montant_recharge

FROM {{ ref('stg_recla_prepaid') }} r

LEFT JOIN {{ source('dxc', 'tb_ftth_prepaid') }} p_jour
    ON r.nd_clean = p_jour.nd
    AND p_jour.date_id = DATE(r.startdate)

LEFT JOIN (
    SELECT DISTINCT ON (nd) nd, date_expiration
    FROM {{ source('dxc', 'tb_ftth_prepaid') }}
    ORDER BY nd, date_id DESC
) p_actuel ON r.nd_clean = p_actuel.nd

LEFT JOIN (
    SELECT nd, SUM(montant_ttc) AS montant_ttc
    FROM {{ source('dxc', 'tb_ftth_prepaid_recharges') }}
    WHERE date_rechargement >= DATE_TRUNC('month', CURRENT_DATE)
      AND date_rechargement < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    GROUP BY nd
) rech ON r.nd_clean = rech.nd
