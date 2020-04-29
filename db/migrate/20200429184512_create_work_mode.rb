class CreateWorkMode < ActiveRecord::Migration[5.2]
  def change
    create_table :work_modes, comment: "Captures user's current work mode for appeals being worked" do |t|
      t.integer "appeal_id", null: false, comment: "Appeal ID -- use as FK to AMA appeals and legacy appeals"
      t.string "appeal_type", null: false, comment: "Whether appeal_id is for AMA or legacy appeals"
      t.index ["appeal_type", "appeal_id"], name: "index_work_modes_on_appeal_type_and_appeal_id", unique: true

      t.boolean "overtime", default: false, comment: "Whether the appeal is currently marked as being worked as overtime"
    end
  end
end
