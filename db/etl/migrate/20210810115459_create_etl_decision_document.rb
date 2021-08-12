# frozen_string_literal: true

class CreateEtlDecisionDocument < Caseflow::Migration
  def change
    create_table :decision_documents do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"
      t.index ["created_at"]
      t.index ["updated_at"]

      t.datetime "decision_document_created_at", comment: "decision_documents.created_at"
      t.datetime "decision_document_updated_at", comment: "decision_documents.updated_at"
      t.index ["decision_document_created_at"]
      t.index ["decision_document_updated_at"]

      # Comments copied from asyncable.rb
      t.datetime "attempted_at", comment: "When the job ran"
      t.datetime "submitted_at", comment: "When the job first became eligible to run"
      t.datetime "last_submitted_at", comment: "When the job is eligible to run (can be reset to restart the job)"
      t.datetime "processed_at", comment: "When the job has concluded"
      t.string "error", comment: "Message captured from a failed attempt"

      t.datetime "canceled_at", comment: "Timestamp when the job was abandoned"
      t.datetime "uploaded_to_vbms_at", comment: "When document was successfully uploaded to VBMS"

      t.references :appeal, polymorphic: true, null: false, comment: "Associated appeal"

      t.string "citation_number", null: false, comment: "Unique identifier for decision document"
      t.index ["citation_number"], unique: true
      t.date "decision_date", null: false
      t.index ["decision_date"]
      t.string "redacted_document_location", null: false

      # Now for columns to associate with other tables
      t.string "docket_number", comment: "from appeals.stream_docket_number"

      t.references :judge_case_reviews, null: false, index: true, foreign_key: false,
                                        comment: "References associated judge_case_review record"
      t.references :attorney_case_reviews, null: false, index: true, foreign_key: false,
                                           comment: "References associated attorney_case_review record"

      t.bigint "judge_task_id", comment: "Id of associated judge task"
      t.bigint "attorney_task_id", comment: "Id of associated attorney task"

      t.bigint "judge_user_id", comment: "Id of associated judge user"
      t.index ["judge_user_id"]

      t.bigint "attorney_user_id", comment: "Id of associated attorney user"
      t.index ["attorney_user_id"]
    end

    # Do not add foreign keys because they rely on the order in which the *Syncers run
    # and because associated records cannot be easily deleted by ETL::Sweeper.
    # add_foreign_key :decision_documents, "tasks", column: "judge_task_id", validate: false
    # add_foreign_key :decision_documents, "tasks", column: "attorney_task_id", validate: false
    # add_foreign_key :decision_documents, "users", column: "judge_user_id", validate: false
    # add_foreign_key :decision_documents, "users", column: "attorney_user_id", validate: false
  end
end
