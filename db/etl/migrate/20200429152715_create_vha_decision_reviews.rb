class CreateVhaDecisionReviews < ActiveRecord::Migration[5.2]
  def change
    create_table :vha_decision_reviews, comment: "VHA-specific decision reviews" do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"
      t.index ["created_at"]
      t.index ["updated_at"]

      t.datetime "decision_review_created_at"
      t.datetime "decision_review_updated_at"
      t.index ["decision_review_created_at"]
      t.index ["decision_review_updated_at"]

      t.bigint "decision_review_id", null: false, comment: "ID of the Decision Review -- may be used as FK to decision_issues"
      t.string "decision_review_type", null: false, comment: "The type of the Decision Review -- may be used as FK to decision_issues"
      t.index ["decision_review_id", "decision_review_type"], unique: true, name: "idx_vha_decision_review_id_and_type"

      # attributes that Appeal, HLR, and SC all have in common
      t.string "benefit_type", null: false, comment: "The benefit type selected by the Veteran on their form, also known as a Line of Business."
      t.datetime "establishment_processed_at", comment: "Timestamp for when the End Product Establishments for the Decision Review successfully finished processing."
      t.datetime "establishment_submitted_at", comment: "Timestamp for when the Higher Level Review was submitted by a Claims Assistant. This adds the End Product Establishment to a job to finish processing asynchronously."

      t.boolean "legacy_opt_in_approved", comment: "Indicates whether a Veteran opted to withdraw matching issues from the legacy process. If there is a matching legacy issue and it is not withdrawn then it is ineligible for the decision review."
      t.index ["legacy_opt_in_approved"]

      t.date "receipt_date", comment: "The date that the Higher Level Review form was received by central mail. This is used to determine which issues are eligible to be appealed based on timeliness.  Only issues decided prior to the receipt date will show up as contestable issues.  It is also the claim date for any associated end products that are established."
      t.index ["receipt_date"]

      t.uuid "uuid", null: false, comment: "The universally unique identifier for the Decision Review"
      t.index ["uuid"]

      t.string "veteran_file_number", null: false, comment: "The file number of the Veteran that the Decision Review is for."
      t.index ["veteran_file_number"]

      t.boolean "veteran_is_not_claimant", comment: "Indicates whether the Veteran is the claimant on the Decision Review form, or if the claimant is someone else like a spouse or a child. Must be TRUE if the Veteran is deceased."
      t.index ["veteran_is_not_claimant"]

      # attributes unique to HLR
      t.boolean "informal_conference", comment: "Indicates whether a Veteran selected on their Higher Level Review form to have an informal conference. This creates a claimant letter and a tracked item in BGS."
      t.index ["informal_conference"]

      t.boolean "same_office", comment: "Whether the Veteran wants their issues to be reviewed by the same office where they were previously reviewed. This creates a special issue on all of the contentions created on this Higher Level Review."
      t.index ["same_office"]

      # attributes unique to SC
      t.bigint "decision_review_remanded_id", comment: "If an Appeal or Higher Level Review decision is remanded, including Duty to Assist errors, it automatically generates a new Supplemental Claim.  If this Supplemental Claim was generated, then the ID of the original Decision Review with the remanded decision is stored here."
      t.string "decision_review_remanded_type", comment: "The type of the Decision Review remanded if applicable, used with decision_review_remanded_id to as a composite key to identify the remanded Decision Review."
      t.index ["decision_review_remanded_id", "decision_review_remanded_type"], name: "idx_vha_decision_review_remanded_id_and_type"

      # attributes unique to Appeal
      t.string "closest_regional_office", comment: "The code for the regional office closest to the Veteran on the appeal."
      t.index ["closest_regional_office"]

      t.date "docket_range_date", comment: "Date that appeal was added to hearing docket range."
      t.index ["docket_range_date"]

      t.string "docket_type", comment: "The docket type selected by the Veteran on their appeal form, which can be hearing, evidence submission, or direct review."
      t.index ["docket_type"]

      t.datetime "established_at", comment: "Timestamp for when the appeal has successfully been intaken into Caseflow by the user."
      t.index ["established_at"]

      t.string "poa_participant_id", comment: "Used to identify the power of attorney (POA) at the time the appeal was dispatched to BVA. Sometimes the POA changes in BGS after the fact, and BGS only returns the current representative."
      t.index ["poa_participant_id"]

      t.string "stream_docket_number", comment: "Multiple appeals with the same docket number indicate separate appeal streams, mimicking the structure of legacy appeals."
      t.index ["stream_docket_number"]

      t.string "stream_type", comment: "When multiple appeals have the same docket number, they are differentiated by appeal stream type, depending on the work being done on each appeal."
      t.index ["stream_type"]

      t.date "target_decision_date", comment: "If the appeal docket is direct review, this sets the target decision date for the appeal, which is one year after the receipt date."
      t.index ["target_decision_date"]
    end
  end
end
