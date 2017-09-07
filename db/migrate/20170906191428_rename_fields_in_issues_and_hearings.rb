class RenameFieldsInIssuesAndHearings < ActiveRecord::Migration
  def change
    rename_column :issues, :hearing_worksheet_reopen, :reopen
    rename_column :issues, :hearing_worksheet_vha, :vha
    rename_column :hearings, :worksheet_witness, :witness
    rename_column :hearings, :worksheet_contentions, :contentions
    rename_column :hearings, :worksheet_evidence, :evidence
    rename_column :hearings, :worksheet_military_service, :military_service
    rename_column :hearings, :worksheet_comments_for_attorney, :comments_for_attorney
  end
end
