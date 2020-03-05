class RemoveJudgeEmailAndJudgeEmailSentFromVirtualHearings < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :virtual_hearings, :judge_email, :string
      remove_column :virtual_hearings, :judge_email_sent, :boolean
    end
  end
end
