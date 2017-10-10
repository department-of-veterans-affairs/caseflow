class CreateIntakes < ActiveRecord::Migration
  def change
    create_table :intakes do |t|
      t.belongs_to :detail, polymorphic: true, null: false
      t.belongs_to :user, null: false
      t.string     :veteran_file_number
      t.datetime   :started_at
      t.datetime   :completed_at
      t.datetime   :cancelled_at
    end
  end
end
