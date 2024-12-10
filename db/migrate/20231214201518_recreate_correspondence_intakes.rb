class RecreateCorrespondenceIntakes < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def change
    create_table :correspondence_intakes do |t|
      t.integer :current_step, null: false, comment: "Tracks users progress on intake workflow"
      t.jsonb :redux_store, null: false, comment: "JSON representation of the data for the current step"

      t.references :correspondence, foreign_key: true, index: false, comment: "Foreign key on correspondences table"
      t.references :user, foreign_key: true, index: false, comment: "Foreign key on users table"

      t.timestamps
    end

    add_safe_index :correspondence_intakes, [:user_id], name: "index_on_user_id"
    add_safe_index :correspondence_intakes, [:correspondence_id], name: "index_on_correspondence_id"
  end
end
