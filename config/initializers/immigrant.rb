require "immigrant"

Immigrant.ignore_keys = [
  # Add FK to column file_number in veterans table
  { from_table: "available_hearing_locations", column: "veteran_file_number" },

  # Add FK to legacy_appeals
  { from_table: "worksheet_issues", column: "appeal_id" },

  # Add FK to dispatch_tasks table (not the tasks table)
  { from_table: "claim_establishments", column: "task_id" },

  # Add FK to users table
  { from_table: "attorney_case_reviews", column: "attorney_id" },
  { from_table: "attorney_case_reviews", column: "reviewing_judge_id" },

  # Investigate these next and add foreign key if possible.
  { from_table: "advance_on_docket_motions", column: "person_id" },
  { from_table: "ramp_issues", column: "source_issue_id" },
  { from_table: "remand_reasons", column: "decision_issue_id" },
  { from_table: "certification_cancellations", column: "certification_id" },

  # The documents table is extremely large -- investigate these later
  { from_table: "annotations", column: "document_id" },
  { from_table: "document_views", column: "document_id" },
  { from_table: "documents_tags", column: "document_id" },
  { from_table: "documents_tags", column: "tag_id" },

  # A job will check for orphaned records for these polymorphic associations:
  { from_table: "sent_hearing_email_events", column: "hearing_id" },
  { from_table: "hearing_email_recipients", column: "hearing_id" },
  { from_table: "special_issue_lists", column: "appeal_id" },
  { from_table: "tasks", column: "appeal_id" },
  { from_table: "vbms_uploaded_documents", column: "appeal_id" },
  # claimants.participant_id  # Not polymorphic but will be checked by job

  # Refers to the tasks table for AMA appeals, but something like `4107503-2021-05-31` for legacy appeals
  # Search for `review_class.complete(params)` in our code to see where task_id is set.
  # Possible solution: Create new column for VACOLS task ID, transfer VACOLS non integer strings to new column, update the code to assign VACOLS strings to new column, delete the VACOLS string from task_id column, and then add the FK
  { from_table: "judge_case_reviews", column: "task_id" },
  { from_table: "attorney_case_reviews", column: "task_id" },

  # Don't need FKs on a cache table
  { from_table: "cached_appeal_attributes", column: "appeal_id" },
  { from_table: "cached_appeal_attributes", column: "vacols_id" }
]
