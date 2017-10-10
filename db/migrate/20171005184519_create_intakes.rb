class CreateIntakes < ActiveRecord::Migration
  safety_assured # this is a new and unused table

  def change
    create_table :intakes do |t|
      t.belongs_to :detail, polymorphic: true, null: false
      t.belongs_to :user, null: false
      t.string     :veteran_file_number
      t.datetime   :started_at    
    end

    add_index(:intakes, :veteran_file_number)
  end
end
