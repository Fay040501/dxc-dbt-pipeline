
-- TTS prepaid enrichi avec statut actif au jour de l'appel et aujourd'hui

SELECT
    t.nd_clean AS nd,
    DATE(t.startdate) AS jour,
    DATE_TRUNC('month', t.startdate) AS mois_appel,
    t.campagne,
    t.disponibilite_client,
    CASE
        WHEN TO_DATE(p_jour.date_expiration, 'DD/MM/YYYY') > DATE(t.startdate) THEN 1
        ELSE 0
    END AS est_actif_au_appel,
    CASE
        WHEN TO_DATE(p_actuel.date_expiration, 'DD/MM/YYYY') > CURRENT_DATE THEN 1
        ELSE 0
    END AS est_actif_aujourdhui

FROM {{ ref('stg_tts_prepaid') }} t

LEFT JOIN {{ source('dxc', 'tb_ftth_prepaid') }} p_jour
    ON t.nd_clean = p_jour.nd
    AND p_jour.date_id = DATE(t.startdate)

LEFT JOIN (
    SELECT DISTINCT ON (nd) nd, date_expiration
    FROM {{ source('dxc', 'tb_ftth_prepaid') }}
    ORDER BY nd, date_id DESC
) p_actuel
    ON t.nd_clean = p_actuel.nd
