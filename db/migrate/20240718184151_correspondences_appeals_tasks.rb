class CorrespondencesAppealsTasks < Caseflow::Migration
  def change
    create_table :correspondences_appeals_tasks do |t|
      t.references :correspondence_appeal, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true

      t.timestamps
    end
  end
end
