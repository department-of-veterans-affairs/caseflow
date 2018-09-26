class CreateDecisions < ActiveRecord::Migration[5.1]
  def change
    create_table :decisions do |t|
      t.belongs_to :request_issue
      t.string :citation_number
      t.date :decision_date
      t.string :redacted_document_location
      t.timestamps null: false
    end
  end
end
