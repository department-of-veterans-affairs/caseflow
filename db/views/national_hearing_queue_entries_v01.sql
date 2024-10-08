SELECT
    appeals.id AS appeal_id,
    appeals.appeal AS appeal_type,
    -- COALESCE selects the first non-null value
    COALESCE(appeals.changed_hearing_request_type, appeals.original_hearing_request_type) AS hearing_request_type,
    appeals.receipt_date AS receipt_date,
    appeals.uuid AS external_id,

  FROM appeals
