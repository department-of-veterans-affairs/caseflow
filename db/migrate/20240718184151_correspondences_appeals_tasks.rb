class CorrespondencesAppealsTasks < Caseflow::Migration
  def change
    revert do
      reversible do |direction|
        self.up do
          safety_assured do
          create_table :correspondences_appeals_tasks do |t|
            t.references :correspondence_appeal, foreign_key: true, index: false
            t.belongs_to :task, null: false, foreign_key: true

            t.timestamps
          end
          end
        end
        self.down do
         safety_assured do
         drop_table :correspondences_appeals_tasks
        end
        end
      end
    end

    create_table :correspondences_appeals_tasks do |t|
      safety_assured do
      t.references :correspondence, foreign_key: true, index: false
      t.belongs_to :task, null: false, foreign_key: true

      t.timestamps
      end
  end
  end
end
