DECLARE VAR_SITE         STRING    DEFAULT 'MLB';
DECLARE VAR_DATETIME_UTC TIMESTAMP DEFAULT TIMESTAMP('2026-04-22 16:00:00 UTC'); /* 2026-04-22T13:00:00 MLB */
DECLARE VAR_LINE_ITEM_ID INT64     DEFAULT 529377;
DECLARE VAR_BIDS_FILTER  STRING    DEFAULT '529377';
DECLARE VAR_DOMAIN_ID    STRING    DEFAULT 'www.4devs.com.br';

/* Extrae el objeto JSON del line item buscado una sola vez para no repetir el REGEXP_EXTRACT */
WITH extracted AS (
    SELECT
        site_id,
        _PARTITIONTIME,
        domain_id,
        placement_id,
        bid_floor,
        bids,
        REGEXP_EXTRACT(
            bids,
            CONCAT(r'\{[^{}]*"line_item_id":', CAST(VAR_LINE_ITEM_ID AS STRING), r'[^{}]*(?:\{[^{}]*\}[^{}]*)*\}')
        ) AS bid_match,
    FROM
        `ads-displa-yxim11er7z5-furyid.ads_display_bq_dataset.bid_auction_adx`
    WHERE
        _PARTITIONTIME = VAR_DATETIME_UTC
        AND site_id    = VAR_SITE
        AND bids       LIKE CONCAT('%', VAR_BIDS_FILTER, '%')
        AND domain_id  = VAR_DOMAIN_ID
),

raw AS (
    SELECT
        site_id,
        _PARTITIONTIME,
        domain_id,
        placement_id,
        bid_floor,
        bids,
        bid_match,
        JSON_VALUE(bid_match, '$.line_item_id') AS line_item_id,
        JSON_VALUE(bid_match, '$.reason_name')  AS reason_name,
    FROM extracted
    WHERE bid_match IS NOT NULL
)

SELECT
    site_id,
    _PARTITIONTIME,
    domain_id,
    placement_id,
    bid_floor,
    bids,
    bid_match,
    line_item_id,
    reason_name,
FROM raw
WHERE line_item_id = CAST(VAR_LINE_ITEM_ID AS STRING)
  AND reason_name  = 'WIN'
LIMIT 100

