class CreateSupplementalClaims < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    create_table :supplemental_claims do |t|
      t.string     :veteran_file_number, null: false
      t.date       :receipt_date
      t.datetime   :established_at
      t.string     :end_product_reference_id
      t.string     :end_product_status
      t.datetime   :end_product_status_last_synced_at
    end

    add_index(:supplemental_claims, :veteran_file_number)
  end
end
