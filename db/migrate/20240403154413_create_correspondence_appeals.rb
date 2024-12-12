class CreateCorrespondenceAppeals < ActiveRecord::Migration[6.0]
  include Caseflow::Migrations::AddIndexConcurrently

  def change
    revert do
      reversible do |direction|
        direction.up do
          create_table :correspondences_appeals do |t|
            t.references :correspondence, foreign_key: true, index: false
            t.references :appeal, foreign_key: true, index: false

            t.timestamps
          end
          add_safe_index :correspondences_appeals, [:correspondence_id], name: "index on correspondence_id"
          add_safe_index :correspondences_appeals, [:appeal_id], name: "index on appeal_id"
        end
        direction.down do
         drop_table :correspondences_appeals
        end
      end
    end

    create_table :correspondence_appeals do |t|
      t.references :correspondence, foreign_key: true, index: false
      t.references :appeal, foreign_key: true, index: false

      t.timestamps
    end
  end
end
