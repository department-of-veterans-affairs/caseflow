class CreateIssuesRecordType < ActiveRecord::Migration[6.1]
  def change
    create_table :issues_record_types do |t|

      t.timestamps
    end
  end
end
