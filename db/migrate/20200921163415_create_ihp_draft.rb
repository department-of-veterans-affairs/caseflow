class CreateIhpDraft < ActiveRecord::Migration[5.2]
  def change
    create_table :ihp_drafts do |t|
      t.string :appeal_type, null: false, comment: "Type of appeal the IHP was written for"
      t.integer :appeal_id, null: false, comment: "Appeal id the IHP was written for"
      t.integer :organization_id, null: false, comment: "IHP-writing VSO that drafted the IHP"
      t.string :path, null: false, comment: "Path to the IHP in the VA V: drive"

      t.timestamps null: false, comment: "Default created_at/updated_at timestamps"
    end
  end
end
