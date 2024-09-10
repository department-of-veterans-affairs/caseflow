class CreateCorrespondencesAppeals < Caseflow::Migration
  def change
    create_table :correspondences_appeals do |t|
      t.references :correspondence, foreign_key: true, index: false
      t.references :appeal, foreign_key: true, index: false

      t.timestamps
    end
  end
end
