
-- TTS postpaid enrichi avec paiements du mois en cours

SELECT
    p.nd,
    p.jour,
    p.mois_appel,
    p.campagne,
    p.disponibilite_client,
    p.est_actif_au_appel,
    p.est_actif_aujourdhui,
    CASE WHEN f.nd IS NOT NULL AND f.statut_fact = 'paye' THEN 1 ELSE 0 END AS a_paye,
    COALESCE(f.mnt_fact_mois_m, 0) AS montant_paiement

FROM {{ ref('int_tts_parc_postpaid') }} p

LEFT JOIN (
    SELECT DISTINCT ON (nd) nd, statut_fact, mnt_fact_mois_m
    FROM {{ source('dxc', 'tb_ftth_postpaid_paiements') }}
    WHERE date_paiement >= DATE_TRUNC('month', CURRENT_DATE)
      AND date_paiement < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    ORDER BY nd, date_paiement DESC
) f ON p.nd = f.nd
