class CreateCorrespondenceRelations < ActiveRecord::Migration[6.1]
  def change
    create_table :correspondence_relations do |t|
      t.references :correspondence, foreign_key: true, index: false
      t.references :related_correspondence, foreign_key: { to_table: :correspondences }, index:false

      t.timestamps
    end
  end
end
