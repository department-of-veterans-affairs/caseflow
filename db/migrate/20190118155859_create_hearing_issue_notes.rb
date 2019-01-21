class CreateHearingIssueNotes < ActiveRecord::Migration[5.1]
  def change
    create_table :hearing_issue_notes do |t|
      t.belongs_to :request_issue, null: false
      t.belongs_to :hearing, null: false
      t.string     :notes
      t.boolean    :remand, default: false
      t.boolean    :reopen, default: false
      t.boolean    :dismiss, default: false
      t.boolean    :allow, default: false
      t.boolean    :deny, default: false
    end
  end
end
