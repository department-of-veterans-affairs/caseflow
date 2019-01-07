class AddHlrscuuid < ActiveRecord::Migration[5.1]
  def change
    # safe because our tables are currently small enough to risk the LOCK wait time.
    safety_assured do
      add_column :higher_level_reviews, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
      add_column :supplemental_claims, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    end
  end
end
