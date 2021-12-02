# frozen_string_literal: true

require "immigrant"

Immigrant.ignore_keys = [
  # Can't add FK. If the veteran cannot be located in BGS, then Caseflow doesn't create a Veteran record.
  # See https://dsva.slack.com/archives/C3EAF3Q15/p1636061857138600?thread_ts=1636060646.138000&cid=C3EAF3Q15
  { from_table: "available_hearing_locations", column: "veteran_file_number" },

  # Investigate these next and add foreign key if possible.
  { from_table: "ramp_issues", column: "source_issue_id" },

  # The documents table is extremely large -- investigate these later
  { from_table: "annotations", column: "document_id" },
  { from_table: "document_views", column: "document_id" },
  { from_table: "documents_tags", column: "document_id" },
  { from_table: "documents_tags", column: "tag_id" },

  # The ForeignKeyPolymorphicAssociationJob checks for orphaned records for these polymorphic associations:
  { from_table: "sent_hearing_email_events", column: "hearing_id" },
  { from_table: "hearing_email_recipients", column: "hearing_id" },
  { from_table: "special_issue_lists", column: "appeal_id" },
  { from_table: "tasks", column: "appeal_id" },
  { from_table: "vbms_uploaded_documents", column: "appeal_id" },
  { from_table: "available_hearing_locations", column: "appeal_id" },
  # claimants.participant_id to persons table  # Not polymorphic but will be checked by job

  # Refers to the tasks table for AMA appeals, but something like `4107503-2021-05-31` for legacy appeals
  # Search for `review_class.complete(params)` in our code to see where task_id is set.
  # Possible solution: Create new column for VACOLS task ID, copy VACOLS non-integer strings to new column,
  # update the code to read and assign VACOLS strings to new column,
  # delete the VACOLS string from `task_id` column, convert `task_id` to a `bigint` column,
  # and then add the FK for `task_id`.
  { from_table: "judge_case_reviews", column: "task_id" },
  { from_table: "attorney_case_reviews", column: "task_id" },

  # Don't need FKs on a cache table
  { from_table: "cached_appeal_attributes", column: "appeal_id" },
  { from_table: "cached_appeal_attributes", column: "vacols_id" },
  { from_table: "cached_user_attributes", column: "sdomainid" }
]
