class CreateDecisions < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    create_table :decisions do |t|
      t.belongs_to :appeal
      t.string :citation_number
      t.date :decision_date
      t.string :redacted_document_location
      t.timestamps null: false
    end

    add_index(:decisions, :citation_number, unique: true)
  end
end
