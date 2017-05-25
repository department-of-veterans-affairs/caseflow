class CreateIssue < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      # This column maps to the ISSUE table ISSSEQ column
      t.string :vacols_sequence_id
      t.belongs_to :appeal
    end
  end
end
