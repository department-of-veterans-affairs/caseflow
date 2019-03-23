class AddCommentsToRampRefiling < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:ramp_refilings, "Intake data for RAMP Refilings, also known as RAMP Selection.")
    
    change_column_comment(:ramp_refilings, :appeal_docket, "When the RAMP Refiling option selected is Appeal, they can select hearing, direct review or evidence submission as the Appeal docket.")

    change_column_comment(:ramp_refilings, :established_at, "Timestamp for when the end product was successfully established in VBMS.")

    change_column_comment(:ramp_refilings, :establishment_processed_at, "Timestamp for when the End Product Establishments for the RAMP Review finished processing.")

    change_column_comment(:ramp_refilings, :establishment_submitted_at, "Timestamp for when an intake for a Decision Review finished being intaken by a Claim Assistant.")

    change_column_comment(:ramp_refilings, :has_ineligible_issue, "Selected by the Claims Assistant during intake, indicates whether the Veteran has ineligible issues.")

    change_column_comment(:ramp_refilings, :option_selected, "Which lane the RAMP refiling is for, between Appeal, Higher Level Review, and Supplemental Claim.")

    change_column_comment(:ramp_refilings, :receipt_date, "The date that the RAMP form was received by central mail.")

    change_column_comment(:ramp_refilings, :veteran_file_number, "The file number of the Veteran that the Higher Level Review is for.")
  end
end
