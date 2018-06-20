class CreateTemporaryAppeals < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    create_table :temporary_appeals do |t|
      t.string     :veteran_file_number, null: false
      t.date       :receipt_date
      t.string     :docket_type
      t.datetime   :established_at
    end

    add_index(:temporary_appeals, :veteran_file_number)
  end
end
