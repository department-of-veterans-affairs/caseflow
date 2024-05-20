class CreateCorrespondenceAppeals < ActiveRecord::Migration[6.0]
  def change
    revert do
      reversible do |direction|
        direction.up do
          create_table :correspondences_appeals do |t|
            t.references :correspondence, foreign_key: true, index: false
            t.references :appeal, foreign_key: true, index: false

            t.timestamps
          end
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
