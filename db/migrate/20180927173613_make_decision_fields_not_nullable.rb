class MakeDecisionFieldsNotNullable < ActiveRecord::Migration[5.1]
  def change
    change_column :decisions, :appeal_id, :bigint, null: false
    change_column :decisions, :citation_number, :string, null: false
    change_column :decisions, :decision_date, :date, null: false
    change_column :decisions, :redacted_document_location, :string, null: false
  end
end
