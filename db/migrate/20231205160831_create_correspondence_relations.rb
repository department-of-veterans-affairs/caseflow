class CreateCorrespondenceRelations < Caseflow::Migration
  def change
    create_table :correspondence_relations do |t|
      t.references :correspondence, foreign_key: true, index: false
      t.references :related_correspondence, foreign_key: { to_table: :correspondences }, index:false

      t.timestamps
    end
  end
end
