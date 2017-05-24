class CreateIssue < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.string :vacols_sequence_id
      t.belongs_to :appeal
    end
  end
end
