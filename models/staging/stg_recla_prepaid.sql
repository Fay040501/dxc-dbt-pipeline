-- Réclamations prepaid : toutes campagnes sauf FACTURE OUVERTE et SUSPENSION
-- Pas de DISTINCT ON ici car la vue originale n'en fait pas pour prepaid

SELECT
    nd_clean,
    startdate,
    campagne,
    statut_appel,
    statut_traitement,
    date_assignation,
    date_traitement
FROM {{ source('dxc', 'tb_reclamations') }}
WHERE campagne NOT IN ('FACTURE OUVERTE', 'SUSPENSION')
  AND nd_clean IS NOT NULL
  AND nd_clean <> ''
