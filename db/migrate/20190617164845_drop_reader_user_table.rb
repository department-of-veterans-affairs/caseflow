class DropReaderUserTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :reader_users
  end
end
