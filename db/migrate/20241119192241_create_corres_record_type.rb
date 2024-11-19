class CreateCorresRecordType < ActiveRecord::Migration[6.1]
  def change
    create_table :corres_record_types do |t|

      t.timestamps
    end
  end
end
