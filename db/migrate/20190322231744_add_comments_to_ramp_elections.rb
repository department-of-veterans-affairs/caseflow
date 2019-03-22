class AddCommentsToRampElections < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:ramp_elections, "Intake data for RAMP Elections.")
    
    change_column_comment(:ramp_elections, :established_at, "Timestamp for when End Product Establishment finishes processing, indicating that the End Product was successfully established in VBMS.")

    change_column_comment(:ramp_elections, :notice_date, "The date that the Veteran was notified of their option to opt their legacy appeals into RAMP.")

    change_column_comment(:ramp_elections, :option_selected, "Indicates whether the Veteran selected for their RAMP election to be processed as a Higher Level Review (with or without a hearing), a Supplemental Claim, or a Board Appeal.")

    change_column_comment(:ramp_elections, :receipt_date, "The date that the RAMP form was received by central mail.")

    change_column_comment(:ramp_elections, :veteran_file_number, "The file number of the Veteran which the RAMP Election is for.")
  end
end
