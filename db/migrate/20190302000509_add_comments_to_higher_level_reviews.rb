class AddCommentsToHigherLevelReviews < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:higher_level_reviews, "Intake data for Higher Level Reviews.")

    change_column_comment(:higher_level_reviews, :benefit_type, "The benefit type selected by the Veteran on their form, also known as a Line of Business.")

    change_column_comment(:higher_level_reviews, :establishment_attempted_at, "Timestamp for the most recent attempt at establishing a claim.")

    change_column_comment(:higher_level_reviews, :establishment_error, "The error captured for the most recent attempt at establishing a claim if it failed.  This is removed once establishing the claim succeeds.")

    change_column_comment(:higher_level_reviews, :establishment_last_submitted_at, "Timestamp for the latest attempt at establishing the End Products for the Decision Review.")

    change_column_comment(:higher_level_reviews, :establishment_processed_at, "Timestamp for when the End Product Establishments for the Decision Review successfully finished processing.")

    change_column_comment(:higher_level_reviews, :establishment_submitted_at, "Timestamp for when the Higher Level Review was submitted by a Claims Assistant. This adds the End Product Establishment to a job to finish processing asynchronously.")

    change_column_comment(:higher_level_reviews, :informal_conference, "Indicates whether a Veteran selected on their Higher Level Review form to have an informal conference. This creates a claimant letter and a tracked item in BGS.")

    change_column_comment(:higher_level_reviews, :legacy_opt_in_approved, "Indicates whether a Veteran opted to withdraw their Higher Level Review request issues from the legacy system if a matching issue is found. If there is a matching legacy issue and it is not withdrawn, then that issue is ineligible to be a new request issue and a contention will not be created for it.")

    change_column_comment(:higher_level_reviews, :receipt_date, "The date that the Higher Level Review form was received by central mail. This is used to determine which issues are eligible to be appealed based on timeliness.  Only issues decided prior to the receipt date will show up as contestable issues.  It is also the claim date for any associated end products that are established.")

    change_column_comment(:higher_level_reviews, :same_office, "Whether the Veteran wants their issues to be reviewed by the same office where they were previously reviewed. This creates a special issue on all of the contentions created on this Higher Level Review.")

    change_column_comment(:higher_level_reviews, :uuid, "The universally unique identifier for the Higher Level Review. Can be used to link to the claim after it is completed.")

    change_column_comment(:higher_level_reviews, :veteran_file_number, "The file number of the Veteran that the Higher Level Review is for.")

    change_column_comment(:higher_level_reviews, :veteran_is_not_claimant, "Indicates whether the Veteran is the claimant on the Higher Level Review form, or if the claimant is someone else like a spouse or a child. Must be TRUE if the Veteran is deceased.")
  end
end
