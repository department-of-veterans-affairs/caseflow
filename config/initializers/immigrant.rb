
Immigrant.ignore_keys = [
  # Investigate next

  { from_table: "advance_on_docket_motions", column: "person_id" },
  { from_table: "judge_case_reviews", column: "task_id" },
  { from_table: "hearing_appeal_stream_snapshots", column: "appeal_id" },
  { from_table: "hearing_appeal_stream_snapshots", column: "hearing_id" },

  { from_table: "attorney_case_reviews", column: "attorney_id" },
  { from_table: "attorney_case_reviews", column: "reviewing_judge_id" },
  { from_table: "attorney_case_reviews", column: "task_id" },
  { from_table: "available_hearing_locations", column: "veteran_file_number" },

  { from_table: "board_grant_effectuations", column: "appeal_id" },
  { from_table: "board_grant_effectuations", column: "decision_document_id" },
  { from_table: "board_grant_effectuations", column: "end_product_establishment_id" },
  { from_table: "board_grant_effectuations", column: "granted_decision_issue_id" },

  { from_table: "cached_appeal_attributes", column: "vacols_id", },

  { from_table: "certification_cancellations", column: "certification_id" },
  { from_table: "claim_establishments", column: "task_id" },

  # The documents table is extremely large
  { from_table: "annotations", column: "document_id" },
  { from_table: "document_views", column: "document_id" },
  { from_table: "documents_tags", column: "document_id" },
  { from_table: "documents_tags", column: "tag_id" },

  { from_table: "ramp_issues", column: "source_issue_id" },
  { from_table: "remand_reasons", column: "decision_issue_id" },

  # Polymorphic associations, add to job that checks for orphaned records
  { from_table: "cached_appeal_attributes", column: "appeal_id" },
  { from_table: "special_issue_lists", column: "appeal_id" },
  { from_table: "vbms_uploaded_documents", column: "appeal_id" },
]
