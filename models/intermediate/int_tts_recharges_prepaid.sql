
-- TTS prepaid enrichi avec recharges du mois en cours

SELECT
    p.nd,
    p.jour,
    p.mois_appel,
    p.campagne,
    p.disponibilite_client,
    p.est_actif_au_appel,
    p.est_actif_aujourdhui,
    CASE WHEN r.nd IS NOT NULL THEN 1 ELSE 0 END AS a_recharge,
    COALESCE(r.montant_ttc, 0) AS montant_recharge

FROM {{ ref('int_tts_parc_prepaid') }} p

LEFT JOIN (
    SELECT nd, SUM(montant_ttc) AS montant_ttc
    FROM {{ source('dxc', 'tb_ftth_prepaid_recharges') }}
    WHERE date_rechargement >= DATE_TRUNC('month', CURRENT_DATE)
      AND date_rechargement < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    GROUP BY nd
) r ON p.nd = r.nd
