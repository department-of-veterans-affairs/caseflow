class CreateCachedAppealAttributes < ActiveRecord::Migration[5.1]
  def change
    create_table :cached_appeal_attributes, id: false do |t|
      t.integer :appeal_id
      t.string :appeal_type
      t.string :docket_type
      t.string :docket_number
      t.string :vacols_id
    end

     add_index :cached_appeal_attributes, [:appeal_id, :appeal_type], unique: true
     add_index :cached_appeal_attributes, [:vacols_id], unique: true
  end
end
