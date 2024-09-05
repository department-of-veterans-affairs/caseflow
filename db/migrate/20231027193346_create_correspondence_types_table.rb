class CreateCorrespondenceTypesTable < Caseflow::Migration
  def change
    create_table :correspondence_types do |t|

      t.string :name, null:false

      t.timestamps

      t.boolean :active, default: true, null:false

    end
  end
end
