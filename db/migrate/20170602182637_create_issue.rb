class CreateIssue < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.belongs_to :appeal
      # This column maps to the ISSUE table ISSSEQ column
      t.string :vacols_sequence_id
      t.integer :hearing_worksheet_status
      t.boolean :hearing_worksheet_reopen, default: false
      t.boolean :hearing_worksheet_vha, default: false
    end
  end
end
