class CreateCachedAppealAttributes < ActiveRecord::Migration[5.1]
  def change
    create_table :cached_appeal_attributes, id: false do |t|
      t.integer :appeal_id
      t.string :appeal_type
      t.string :docket_type
      t.integer :docket_number
    end
  end
end
