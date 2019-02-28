class AddCommentsForSupplementalClaims < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:supplemental_claims, "Intake data for Supplemental Claims.")

    change_column_comment(:supplemental_claims, :benefit_type, "The benefit type selected by the Veteran on their form, also known as a Line of Business.")

    change_column_comment(:supplemental_claims, :decision_review_remanded_id, "If an Appeal or Higher Level Review decision is remanded, including Duty to Assist errors, it automatically generates a new Supplemental Claim.  If this Supplemental Claim was generated, then the ID of the original Decision Review with the remanded decision is stored here.")

    change_column_comment(:supplemental_claims, :decision_review_remanded_type, "The type of the Decision Review remanded if applicable, used with decision_review_remanded_id to as a composite key to identify the remanded Decision Review.")

    change_column_comment(:supplemental_claims, :establishment_attempted_at, "Timestamp for the most recent attempt at establishing a claim.")

    change_column_comment(:supplemental_claims, :establishment_error, "The error captured for the most recent attempt at establishing a claim if it failed.  This is removed once establishing the claim succeeds.")

    change_column_comment(:supplemental_claims, :establishment_last_submitted_at, "Timestamp for the latest attempt at establishing the End Products for the Decision Review.")

    change_column_comment(:supplemental_claims, :establishment_processed_at, "Timestamp for when the End Product Establishments for the Decision Review successfully finished processing.")

    change_column_comment(:supplemental_claims, :establishment_submitted_at, "Timestamp for when the Supplemental Claim was submitted by a Claims Assistant. This adds the End Product Establishment to a job to finish processing asynchronously.")

    change_column_comment(:supplemental_claims, :legacy_opt_in_approved, "Indicates whether a Veteran opted to withdraw their Supplemental Claim request issues from the legacy system if a matching issue is found. If there is a matching legacy issue and it is not withdrawn, then that issue is ineligible to be a new request issue and a contention will not be created for it.")

    change_column_comment(:supplemental_claims, :receipt_date, "The date that the Supplemental Claim form was received by central mail. Only issues decided prior to the receipt date will show up as contestable issues.  It is also the claim date for any associated end products that are established. Supplemental Claims do not have the same timeliness restriction on contestable issues as Appeals and Higher Level Reviews.")

    change_column_comment(:supplemental_claims, :uuid, "The universally unique identifier for the Supplemental Claim. Can be used to link to the claim after it is completed.")

    change_column_comment(:supplemental_claims, :veteran_file_number, "The file number of the Veteran that the Supplemental Claim is for.")

    change_column_comment(:supplemental_claims, :veteran_is_not_claimant, "Indicates whether the Veteran is the claimant on the Supplemental Claim form, or if the claimant is someone else like a spouse or a child. Must be TRUE if the Veteran is deceased.")
  end
end
