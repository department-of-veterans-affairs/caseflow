class CreateRepRecordType < ActiveRecord::Migration[6.1]
  def change
    create_table :rep_record_types do |t|

      t.timestamps
    end
  end
end
