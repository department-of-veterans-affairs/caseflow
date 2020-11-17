class UpdateCommentOnSentHearingEmailEvent < ActiveRecord::Migration[5.2]
  def change
    change_column_comment(:sent_hearing_email_events, :email_type, "The type of email sent: cancellation, confirmation, updated_time_confirmation")
  end
end
