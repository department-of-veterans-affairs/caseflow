class AddJudgeEmailAndJudgeEmailSentToVirtualHearings < ActiveRecord::Migration[5.2]
  def maybe_add_judge_email
    unless column_exists? :virtual_hearings, :judge_email, :string
      add_column :virtual_hearings, :judge_email, :string,
                 comment: "Judge's email address"
    end
  end

  def maybe_add_judge_email_sent
    unless column_exists? :virtual_hearings, :judge_email_sent, :boolean
      add_column :virtual_hearings, :judge_email_sent, :boolean, default: false, null: false,
                 comment: "Whether or not a notification email was sent to the judge"
    end
  end

  def up
    safety_assured do
      maybe_add_judge_email
      maybe_add_judge_email_sent
    end
  end

  def down
    remove_column :virtual_hearings, :judge_email, :string
    remove_column :virtual_hearings, :judge_email_sent, :boolean
  end
end
