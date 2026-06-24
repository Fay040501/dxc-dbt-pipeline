
-- TTS postpaid enrichi avec statut actif au jour de l'appel et aujourd'hui

SELECT
    t.nd_clean AS nd,
    DATE(t.startdate) AS jour,
    DATE_TRUNC('month', t.startdate) AS mois_appel,
    t.campagne,
    t.disponibilite_client,
    CASE
        WHEN p_jour.etat = 'Actif' THEN 1
        ELSE 0
    END AS est_actif_au_appel,
    CASE
        WHEN p_actuel.etat = 'Actif' THEN 1
        ELSE 0
    END AS est_actif_aujourdhui

FROM {{ ref('stg_tts_postpaid') }} t

LEFT JOIN {{ source('dxc', 'tb_ftth_postpaid') }} p_jour
    ON t.nd_clean = p_jour.nd
    AND p_jour.date_id = DATE(t.startdate)

LEFT JOIN (
    SELECT DISTINCT ON (nd) nd, etat
    FROM {{ source('dxc', 'tb_ftth_postpaid') }}
    ORDER BY nd, date_id DESC
) p_actuel
    ON t.nd_clean = p_actuel.nd
