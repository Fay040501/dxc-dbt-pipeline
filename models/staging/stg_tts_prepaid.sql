-- TTS prepaid : un seul appel par ND par jour
-- Priorité : décroché > sonne en vain > non joignable
-- Campagnes prepaid : tout sauf FACTURE OUVERTE et SUSPENSION

SELECT DISTINCT ON (nd_clean, DATE(startdate))
    nd_clean,
    startdate,
    campagne,
    disponibilite_client
FROM {{ source('dxc', 'tb_tts') }}
WHERE campagne NOT IN ('FACTURE OUVERTE', 'SUSPENSION')
  AND nd_clean IS NOT NULL
  AND nd_clean <> ''
  AND startdate IS NOT NULL
ORDER BY nd_clean, DATE(startdate),
    CASE disponibilite_client
        WHEN 'Le client a décroché.' THEN 1
        WHEN 'Le numéro du client sonne en vain.' THEN 2
        WHEN 'Le numéro du client n''est pas joignable.' THEN 3
        ELSE 4
    END,
    startdate
