-- Filtre les réclamations depuis tb_tts
-- CHURN, RESILIATION ou motif renseigné

SELECT
    id_hash,
    startdate,
    nd_clean,
    identite_client,
    contact,
    disponibilite_client,
    categorie_de_non_paiement,
    motif_non_paiement,
    commentaire,
    campagne
FROM {{ source('dxc', 'tb_tts') }}
WHERE categorie_de_non_paiement IN ('DEMANDE DE RESILIATION', 'CHURN')
   OR motif_non_paiement IS NOT NULL
