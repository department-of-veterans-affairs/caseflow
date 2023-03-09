SELECT
  id,
  appeal_id,
  appeal_type,
  assigned_at,
  assigned_to_id,
  assigned_to_type,
  assigned_by_id,
  cancellation_reason,
  cancelled_by_id,
  closed_at,
  created_at,
  instructions,
  parent_id,
  placed_on_hold_at,
  started_at,
  status,
  type AS task_type,
  updated_at,
  issue_count,
  claimant_name,
  veteran_participant_id,
  veteran_ssn
FROM (
    (
      (
        SELECT "tasks".*,
          COUNT(request_issues.id) AS issue_count,
          COALESCE(
            NULLIF(
              CASE
                WHEN veteran_is_not_claimant THEN COALESCE(
                  NULLIF(
                    CONCAT(
                      unrecognized_party_details.name,
                      ' ',
                      unrecognized_party_details.last_name
                    ),
                    ' '
                  ),
                  NULLIF(
                    CONCAT(people.first_name, ' ', people.last_name),
                    ' '
                  ),
                  bgs_attorneys.name
                )
                ELSE CONCAT(veterans.first_name, ' ', veterans.last_name)
              END,
              ' '
            ),
            'claimant'
          ) AS claimant_name,
          veterans.participant_id as veteran_participant_id,
          veterans.ssn as veteran_ssn
        FROM "tasks"
          INNER JOIN "higher_level_reviews" ON "higher_level_reviews"."id" = "tasks"."appeal_id"
          AND "tasks"."appeal_type" = 'HigherLevelReview'
          INNER JOIN "request_issues" ON "request_issues"."decision_review_id" = "higher_level_reviews"."id"
          AND "request_issues"."decision_review_type" = 'HigherLevelReview'
          INNER JOIN veterans on veterans.file_number = veteran_file_number
          LEFT JOIN claimants ON claimants.decision_review_id = tasks.appeal_id
          AND claimants.decision_review_type = tasks.appeal_type
          LEFT JOIN people ON claimants.participant_id = people.participant_id
          LEFT JOIN unrecognized_appellants ON claimants.id = unrecognized_appellants.claimant_id
          LEFT JOIN unrecognized_party_details ON unrecognized_appellants.unrecognized_party_detail_id = unrecognized_party_details.id
          LEFT JOIN bgs_attorneys ON claimants.participant_id = bgs_attorneys.participant_id
        GROUP BY tasks.id,
          veterans.participant_id,
          veterans.ssn,
          veterans.first_name,
          veterans.last_name,
          unrecognized_party_details.name,
          unrecognized_party_details.last_name,
          people.first_name,
          people.last_name,
          veteran_is_not_claimant,
          bgs_attorneys.name
      )
      UNION ALL
      (
        SELECT "tasks".*,
          COUNT(request_issues.id) AS issue_count,
          COALESCE(
            NULLIF(
              CASE
                WHEN veteran_is_not_claimant THEN COALESCE(
                  NULLIF(
                    CONCAT(
                      unrecognized_party_details.name,
                      ' ',
                      unrecognized_party_details.last_name
                    ),
                    ' '
                  ),
                  NULLIF(
                    CONCAT(people.first_name, ' ', people.last_name),
                    ' '
                  ),
                  bgs_attorneys.name
                )
                ELSE CONCAT(veterans.first_name, ' ', veterans.last_name)
              END,
              ' '
            ),
            'claimant'
          ) AS claimant_name,
          veterans.participant_id as veteran_participant_id,
          veterans.ssn as veteran_ssn
        FROM "tasks"
          INNER JOIN "supplemental_claims" ON "supplemental_claims"."id" = "tasks"."appeal_id"
          AND "tasks"."appeal_type" = 'SupplementalClaim'
          INNER JOIN "request_issues" ON "request_issues"."decision_review_id" = "supplemental_claims"."id"
          AND "request_issues"."decision_review_type" = 'SupplementalClaim'
          INNER JOIN veterans on veterans.file_number = veteran_file_number
          LEFT JOIN claimants ON claimants.decision_review_id = tasks.appeal_id
          AND claimants.decision_review_type = tasks.appeal_type
          LEFT JOIN people ON claimants.participant_id = people.participant_id
          LEFT JOIN unrecognized_appellants ON claimants.id = unrecognized_appellants.claimant_id
          LEFT JOIN unrecognized_party_details ON unrecognized_appellants.unrecognized_party_detail_id = unrecognized_party_details.id
          LEFT JOIN bgs_attorneys ON claimants.participant_id = bgs_attorneys.participant_id
        GROUP BY tasks.id,
          veterans.participant_id,
          veterans.ssn,
          veterans.first_name,
          veterans.last_name,
          unrecognized_party_details.name,
          unrecognized_party_details.last_name,
          people.first_name,
          people.last_name,
          veteran_is_not_claimant,
          bgs_attorneys.name
      )
    )
    UNION ALL
    (
      SELECT "tasks".*,
        COUNT(request_issues.id) AS issue_count,
        COALESCE(
          NULLIF(
            CASE
              WHEN veteran_is_not_claimant THEN COALESCE(
                NULLIF(
                  CONCAT(
                    unrecognized_party_details.name,
                    ' ',
                    unrecognized_party_details.last_name
                  ),
                  ' '
                ),
                NULLIF(
                  CONCAT(people.first_name, ' ', people.last_name),
                  ' '
                ),
                bgs_attorneys.name
              )
              ELSE CONCAT(veterans.first_name, ' ', veterans.last_name)
            END,
            ' '
          ),
          'claimant'
        ) AS claimant_name,
        veterans.participant_id as veteran_participant_id,
        veterans.ssn as veteran_ssn
      FROM "tasks"
        INNER JOIN "appeals" ON "appeals"."id" = "tasks"."appeal_id"
        AND "tasks"."appeal_type" = 'Appeal'
        INNER JOIN "request_issues" ON "request_issues"."decision_review_id" = "appeals"."id"
        AND "request_issues"."decision_review_type" = 'Appeal'
        INNER JOIN veterans on veterans.file_number = veteran_file_number
        LEFT JOIN claimants ON claimants.decision_review_id = tasks.appeal_id
        AND claimants.decision_review_type = tasks.appeal_type
        LEFT JOIN people ON claimants.participant_id = people.participant_id
        LEFT JOIN unrecognized_appellants ON claimants.id = unrecognized_appellants.claimant_id
        LEFT JOIN unrecognized_party_details ON unrecognized_appellants.unrecognized_party_detail_id = unrecognized_party_details.id
        LEFT JOIN bgs_attorneys ON claimants.participant_id = bgs_attorneys.participant_id
      GROUP BY tasks.id,
        veterans.participant_id,
        veterans.ssn,
        veterans.first_name,
        veterans.last_name,
        unrecognized_party_details.name,
        unrecognized_party_details.last_name,
        people.first_name,
        people.last_name,
        veteran_is_not_claimant,
        bgs_attorneys.name
    )
  ) AS "tasks"
ORDER BY "assigned_at" DESC
