class CreateEndProductEstablishments < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    create_table :end_product_establishments do |t|
      t.datetime :established_at
      t.string :synced_status
      t.belongs_to :source, polymorphic: true, null: false
      t.string :veteran_file_number, null: false
      t.string :reference_id
      t.date :claim_date
      t.string :code
      t.string :modifier
      t.string :station
      t.datetime :last_synced_at
    end

    add_index :end_product_establishments, [:veteran_file_number]
  end
end
