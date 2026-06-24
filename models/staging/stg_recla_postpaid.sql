-- Réclamations postpaid : un seul par ND par jour
-- Priorité : TRAITE > ASSIGNE > NON ASSIGNE
-- Campagnes postpaid : FACTURE OUVERTE, SUSPENSION

SELECT DISTINCT ON (nd_clean, DATE(startdate))
    nd_clean,
    startdate,
    campagne,
    statut_appel,
    statut_traitement,
    date_assignation,
    date_traitement
FROM {{ source('dxc', 'tb_reclamations') }}
WHERE campagne IN ('FACTURE OUVERTE', 'SUSPENSION')
  AND nd_clean IS NOT NULL
  AND nd_clean <> ''
  AND startdate IS NOT NULL
ORDER BY nd_clean, DATE(startdate),
    CASE statut_traitement
        WHEN 'TRAITE' THEN 1
        WHEN 'ASSIGNE' THEN 2
        WHEN 'NON ASSIGNE' THEN 3
        ELSE 4
    END,
    startdate DESC
