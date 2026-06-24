{{ config(
    materialized='incremental',
    unique_key='id_hash'
) }}

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
    campagne,
    NULL::text AS statut_appel,
    NULL::text AS motif_reel,
    NULL::text AS niveau,
    NULL::text AS commentaire_bo,
    NULL::text AS zone_client,
    NULL::text AS sous_motif,
    NULL::text AS id_dossier,
    NULL::text AS assigne_a,
    'NON ASSIGNE'::text AS statut_traitement,
    NULL::timestamp AS date_assignation,
    NULL::timestamp AS date_traitement
FROM {{ ref('stg_reclamations') }}

{% if is_incremental() %}
WHERE id_hash NOT IN (SELECT id_hash FROM {{ this }})
{% endif %}
