class CreateVhaDecisionReviews < ActiveRecord::Migration[5.2]
  def change
    create_table :vha_decision_reviews, comment: "VHA-specific decision reviews" do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"
      t.index ["created_at"]
      t.index ["updated_at"]

      # attributes that Appeal, HLR, and SC all have in common

      # TODO verify LoB == benefit type, check on nonrating issues in particular
      t.string "benefit_type", null: false, limit: 15, comment: "The benefit type selected by the Veteran on their form, also known as a Line of Business."
      t.datetime "establishment_processed_at", comment: "Timestamp for when the End Product Establishments for the Decision Review successfully finished processing."
      t.datetime "establishment_submitted_at", comment: "Timestamp for when the Higher Level Review was submitted by a Claims Assistant. This adds the End Product Establishment to a job to finish processing asynchronously."

      t.bigint "decision_review_id", null: false, comment: "ID of the Decision Review -- may be used as FK to decision_issues"
      t.string "decision_review_type", null: false, comment: "The type of the Decision Review -- may be used as FK to decision_issues"
      t.index ["decision_review_id", "decision_review_type"], unique: true

      t.boolean "informal_conference", comment: "Indicates whether a Veteran selected on their Higher Level Review form to have an informal conference. This creates a claimant letter and a tracked item in BGS."
      t.index ["informal_conference"]

      t.boolean "legacy_opt_in_approved", comment: "Indicates whether a Veteran opted to withdraw matching issues from the legacy process. If there is a matching legacy issue and it is not withdrawn then it is ineligible for the decision review."
      t.index ["legacy_opt_in_approved"]

      t.date "receipt_date", comment: "The date that the Higher Level Review form was received by central mail. This is used to determine which issues are eligible to be appealed based on timeliness.  Only issues decided prior to the receipt date will show up as contestable issues.  It is also the claim date for any associated end products that are established."
      t.index ["receipt_date"]

      t.boolean "same_office", comment: "Whether the Veteran wants their issues to be reviewed by the same office where they were previously reviewed. This creates a special issue on all of the contentions created on this Higher Level Review."
      t.index ["same_office"]

      t.uuid "uuid", null: false, comment: "The universally unique identifier for the Decision Review"
      t.index ["uuid"]

    end
  end
end
