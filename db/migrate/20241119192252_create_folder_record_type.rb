class CreateFolderRecordType < ActiveRecord::Migration[6.1]
  def change
    create_table :folder_record_types do |t|

      t.timestamps
    end
  end
end
