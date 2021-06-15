class AddPiiCommentOnPiiColumns < Caseflow::Migration
  def up
    change_column_comment :veterans, :first_name, "PII. Veteran's first name"
    change_column_comment :veterans, :middle_name, "PII. Veteran's middle name"
    change_column_comment :veterans, :last_name, "PII. Veteran's last name"
    change_column_comment :veterans, :file_number, "PII. Veteran's file_number"
    change_column_comment :veterans, :ssn, "PII. The cached Social Security Number"

    change_column_comment :appeals, :veteran_file_number, "PII. The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."
    change_column_comment :available_hearing_locations, :veteran_file_number, "PII. The VBA corporate file number of the Veteran for the appeal"
    change_column_comment :end_product_establishments, :veteran_file_number, "PII. The file number of the Veteran submitted when establishing the end product."
    change_column_comment :higher_level_reviews, :veteran_file_number, "PII. The file number of the Veteran that the Higher Level Review is for."
    change_column_comment :supplemental_claims, :veteran_file_number, "PII. The file number of the Veteran that the Supplemental Claim is for."
    change_column_comment :intakes, :veteran_file_number, "PII. The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."
    change_column_comment :ramp_elections, :veteran_file_number, "PII. The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."
    change_column_comment :ramp_refilings, :veteran_file_number, "PII. The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."

    change_column_comment :bgs_power_of_attorneys, :file_number, "PII. Claimant file number"
    change_column_comment :documents, :file_number, "PII"
    change_column_comment :form8s, :file_number, "PII"
  end

  def down
    change_column_comment :veterans, :first_name, nil
    change_column_comment :veterans, :middle_name, nil
    change_column_comment :veterans, :last_name, nil
    change_column_comment :veterans, :file_number, nil
    change_column_comment :veterans, :ssn, "The cached Social Security Number"

    change_column_comment :appeals, :veteran_file_number, "The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."
    change_column_comment :available_hearing_locations, :veteran_file_number, "The VBA corporate file number of the Veteran for the appeal"
    change_column_comment :end_product_establishments, :veteran_file_number, "The file number of the Veteran submitted when establishing the end product."
    change_column_comment :higher_level_reviews, :veteran_file_number, "The file number of the Veteran that the Higher Level Review is for."
    change_column_comment :supplemental_claims, :veteran_file_number, "The file number of the Veteran that the Supplemental Claim is for."
    change_column_comment :intakes, :veteran_file_number, "The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."
    change_column_comment :ramp_elections, :veteran_file_number, "The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."
    change_column_comment :ramp_refilings, :veteran_file_number, "The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran."

    change_column_comment :bgs_power_of_attorneys, :file_number, "Claimant file number"
    change_column_comment :documents, :file_number, nil
    change_column_comment :form8s, :file_number, nil  
  end
end
