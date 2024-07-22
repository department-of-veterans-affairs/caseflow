class CorrespondencesAppealsTasks < Caseflow::Migration
  def change
    revert do
      reversible do |direction|
        self.up do
          create_table :correspondences_appeals_tasks do |t|
            t.references :correspondence_appeal, foreign_key: true, index: false
            t.belongs_to :task, null: false, foreign_key: true

            t.timestamps
          end
        end
        self.down do
         drop_table :correspondences_appeals_tasks
        end
      end
    end

    create_table :correspondences_appeals_tasks do |t|
      t.references :correspondence, foreign_key: true, index: false
      t.belongs_to :task, null: false, foreign_key: true

      t.timestamps
    end
  end
end
