SELECT
    a.id AS appeal_id,
    'appeal' as appeal_type,
    -- COALESCE selects the first non-null value
    COALESCE(a.changed_hearing_request_type, a.original_hearing_request_type) AS hearing_request_type,
    a.receipt_date AS receipt_date,
    a.uuid AS external_id,
    a.stream_type as appeal_stream,
    a.stream_docket_number as docket_number
FROM appeals a
