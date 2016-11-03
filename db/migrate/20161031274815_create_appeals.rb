class CreateAppeals < ActiveRecord::Migration
  def change
    create_table :appeals do |t|
      t.string    :vacols_id, null: false
      t.string    :vbms_id
    end
    add_index(:appeals, :vacols_id, unique: true)
  end
end
