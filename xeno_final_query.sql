-- target_base for merchant 501, October 2026

WITH RECURSIVE family AS (
    -- Map every retry campaign to the first campaign in its chain.
    SELECT id, id AS root_id
    FROM campaign
    WHERE parent_id IS NULL

    UNION ALL

    SELECT c.id, f.root_id
    FROM campaign AS c
    JOIN family AS f
      ON c.parent_id = f.id
),
qualifying_sends AS (
    SELECT
        l.id,
        l.customer_id,
        f.root_id,
        EXISTS (
            SELECT 1
            FROM campaign AS child
            WHERE child.parent_id = f.root_id
        ) AS is_retry_family
    FROM communication_log AS l
    JOIN campaign AS c
      ON c.id = l.communication_id
    JOIN family AS f
      ON f.id = c.id
    WHERE l.merchant_id = 501
      AND l.communication_type = '2'
      AND l.delivery_status = 900
      AND l.sent_time >= '2026-10-01'
      AND l.sent_time < '2026-11-01'
      AND c.creation_status IN ('approved', 'aborted', 'resumed', 'stopped')
      AND c.processing_status = 'processed'
)
SELECT COUNT(*) AS target_base
FROM (
    SELECT
        root_id,
        CASE
            WHEN is_retry_family THEN customer_id
            ELSE id
        END AS counted_item
    FROM qualifying_sends
    GROUP BY root_id, counted_item
);
