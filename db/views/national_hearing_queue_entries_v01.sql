--- this view is a way to see both of the appeals and legacy appeals information in a single table
--- materialized means that this information will be cached in a temporary table
SELECT
    appeals.id AS appeal_id,
    'appeal' as appeal_type,
    -- COALESCE selects the first non-null value
    COALESCE(appeals.changed_hearing_request_type, appeals.original_hearing_request_type) AS hearing_request_type,
    appeals.receipt_date AS receipt_date,
    appeals.uuid AS external_id,
    appeals.stream_type as appeal_stream,
    appeals.stream_docket_number as docket_number
FROM appeals
