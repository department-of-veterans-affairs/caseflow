class AddJudgeEmailAndJudgeEmailSentToVirtualHearings < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :virtual_hearings, :judge_email, :string,
                 comment: "Judge's email address"
      add_column :virtual_hearings, :judge_email_sent, :boolean, default: false, null: false,
                 comment: "Whether or not a notification email was sent to the judge"
    end
  end
end
