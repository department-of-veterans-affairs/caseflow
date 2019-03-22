class AddCommentsToIntake < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:intakes, "Keeps track of the initial intake of all Decision Reviews and RAMP Reviews.")

    change_column_comment(:intakes, :cancel_other, "The additional notes a Claims Assistant can enter if they are canceling an intake for a reason other than the options presented.")

    change_column_comment(:intakes, :cancel_reason, "The reason a Claim Assistant is canceling the current intake. Intakes can also be canceled automatically when there is an uncaught error, with the reason 'system_error'.")

    change_column_comment(:intakes, :completed_at, "Timestamp for when the Intake was completed, whether it was successful or not.")

    change_column_comment(:intakes, :completion_started_at, "Timestamp for when the user submitted the Intake to be completed.")

    change_column_comment(:intakes, :completion_status, "Indicates whether the intake was successful, or was closed by being canceled, expired, or due to an error.")

    change_column_comment(:intakes, :detail_id, "The ID of the Decision Review or RAMP Review that the Intake is connected to.")

    change_column_comment(:intakes, :detail_type, "The type of Decision Review or RAMP Review that the Intake is connected to.")

    change_column_comment(:intakes, :error_code, "If the Intake was unsuccessful due to a set of known errors, the error code is stored here. An error is also stored here for RAMP Elections that are connected to a currently active End Product, even though the Intake is a success.")

    change_column_comment(:intakes, :started_at, "Timestamp for when the Intake was created, which happens when a Claims Assistant successfully searches for a Veteran in the Intake app.")

    change_column_comment(:intakes, :type, "The type of Intake this is, for example if the detail type is Appeal, the intake type is AppealIntake.")

    change_column_comment(:intakes, :user_id, "The CSS_ID of the user who created the intake.")

    change_column_comment(:intakes, :veteran_file_number, "The file number of the Veteran which the Intake is for.")
  end
end
