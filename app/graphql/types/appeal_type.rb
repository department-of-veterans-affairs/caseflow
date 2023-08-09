module Types
  class AppealType < Types::BaseObject
    field :id, ID, null: false do
      description "PKey of Appeals table"
    end

    field :docket_type, String, null: false do
      description "The docket type selected by the Veteran on their appeal form, which can be hearing, " \
        "evidence submission, or direct review."
    end

    field :veteran_file_number, String, null: false do
      description "File number of the veteran this appeal has been submitted for."
    end

    field :stream_docket_number, String, null: false do
      description "Multiple appeals with the same docket number indicate separate appeal streams, " \
        "mimicking the structure of legacy appeals."
    end

    field :stream_type, String, null: false do
      description "When multiple appeals have the same docket number, they are differentiated by appeal stream type, "\
        "depending on the work being done on each appeal."
    end

  # t.boolean "aod_based_on_age", comment: "If true, appeal is advance-on-docket due to claimant's age."
  # t.string "changed_hearing_request_type", comment: "The new hearing type preference for an appellant that needs a hearing scheduled"
  # t.string "closest_regional_office", comment: "The code for the regional office closest to the Veteran on the appeal."
  # t.datetime "created_at"
  # t.date "docket_range_date", comment: "Date that appeal was added to hearing docket range."
  # t.string "docket_type", comment: "The docket type selected by the Veteran on their appeal form, which can be hearing, evidence submission, or direct review."
  # t.datetime "established_at", comment: "Timestamp for when the appeal has successfully been intaken into Caseflow by the user."
  # t.datetime "establishment_attempted_at", comment: "Timestamp for when the appeal's establishment was last attempted."
  # t.datetime "establishment_canceled_at", comment: "Timestamp when job was abandoned"
  # t.string "establishment_error", comment: "The error message if attempting to establish the appeal resulted in an error. This gets cleared once the establishment is successful."
  # t.datetime "establishment_last_submitted_at", comment: "Timestamp for when the the job is eligible to run (can be reset to restart the job)."
  # t.datetime "establishment_processed_at", comment: "Timestamp for when the establishment has succeeded in processing."
  # t.datetime "establishment_submitted_at", comment: "Timestamp for when the the intake was submitted for asynchronous processing."
  # t.boolean "filed_by_va_gov", comment: "Indicates whether or not this form came from VA.gov"
  # t.boolean "homelessness", default: false, null: false, comment: "Indicates whether or not a veteran is experiencing homelessness"
  # t.boolean "legacy_opt_in_approved", comment: "Indicates whether a Veteran opted to withdraw matching issues from the legacy process. If there is a matching legacy issue and it is not withdrawn then it is ineligible for the decision review."
  # t.string "original_hearing_request_type", comment: "The hearing type preference for an appellant before any changes were made in Caseflow"
  # t.string "poa_participant_id", comment: "Used to identify the power of attorney (POA) at the time the appeal was dispatched to BVA. Sometimes the POA changes in BGS after the fact, and BGS only returns the current representative."
  # t.date "receipt_date", comment: "Receipt date of the appeal form. Used to determine which issues are within the timeliness window to be appealed. Only issues decided prior to the receipt date will show up as contestable issues."
  # t.string "stream_docket_number", comment: "Multiple appeals with the same docket number indicate separate appeal streams, mimicking the structure of legacy appeals."
  # t.string "stream_type", default: "Original", comment: "When multiple appeals have the same docket number, they are differentiated by appeal stream type, depending on the work being done on each appeal."
  # t.date "target_decision_date", comment: "If the appeal docket is direct review, this sets the target decision date for the appeal, which is one year after the receipt date."
  # t.datetime "updated_at"
  # t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false, comment: "The universally unique identifier for the appeal, which can be used to navigate to appeals/appeal_uuid. This allows a single ID to determine an appeal whether it is a legacy appeal or an AMA appeal."
  # t.string "veteran_file_number", null: false, comment: "PII. The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."
  # t.boolean "veteran_is_not_claimant", comment: "Selected by the user during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else such as a dependent. Must be TRUE if Veteran is deceased."
  # t.index ["aod_based_on_age"], name: "index_appeals_on_aod_based_on_age"
  # t.index ["docket_type"], name: "index_appeals_on_docket_type"
  # t.index ["established_at"], name: "index_appeals_on_established_at"
  # t.index ["updated_at"], name: "index_appeals_on_updated_at"
  # t.index ["uuid"], name: "index_appeals_on_uuid"
  # t.index ["veteran_file_number"], name: "index_appeals_on_veteran_file_number"
  end
end
