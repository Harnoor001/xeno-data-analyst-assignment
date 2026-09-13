WITH RECURSIVE campaign_roots AS (
    SELECT
        id AS campaign_id,
        id AS root_id
    FROM campaign
    WHERE parent_id IS NULL

    UNION ALL

    SELECT
        c.id AS campaign_id,
        r.root_id
    FROM campaign AS c
    JOIN campaign_roots AS r
      ON c.parent_id = r.campaign_id
),
qualifying_deliveries AS (
    SELECT
        l.id AS log_id,
        l.customer_id,
        r.root_id
    FROM communication_log AS l
    JOIN campaign AS c
      ON c.id = l.communication_id
    JOIN campaign_roots AS r
      ON r.campaign_id = c.id
    WHERE l.merchant_id = 501
      AND l.communication_type = '2'
      AND l.delivery_status = 900
      AND l.sent_time >= '2026-10-01'
      AND l.sent_time <  '2026-11-01'
      AND c.creation_status IN ('approved', 'aborted', 'resumed', 'stopped')
      AND c.processing_status = 'processed'
),
classified_deliveries AS (
    SELECT
        q.*,
        EXISTS (
            SELECT 1
            FROM campaign AS child
            WHERE child.parent_id = q.root_id
        ) AS is_retry_family
    FROM qualifying_deliveries AS q
),
counted_events AS (
    SELECT
        root_id,
        CASE
            WHEN is_retry_family = 1 THEN customer_id
            ELSE CAST(log_id AS TEXT)
        END AS counted_entity
    FROM classified_deliveries
    GROUP BY
        root_id,
        CASE
            WHEN is_retry_family = 1 THEN customer_id
            ELSE CAST(log_id AS TEXT)
        END
)
SELECT COUNT(*) AS target_base
FROM counted_events;
