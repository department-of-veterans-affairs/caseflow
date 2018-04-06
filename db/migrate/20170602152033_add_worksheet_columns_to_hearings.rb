class AddWorksheetColumnsToHearings < ActiveRecord::Migration[5.1]
  def change
    add_column :hearings, :worksheet_witness, :string
    add_column :hearings, :worksheet_contentions, :string
    add_column :hearings, :worksheet_evidence, :string
    add_column :hearings, :worksheet_military_service, :string
    add_column :hearings, :worksheet_comments_for_attorney, :string
  end
end
