class CreateHearingWorksheet < ActiveRecord::Migration
  def change
    create_table :hearing_worksheets do |t|
      t.belongs_to :hearing, null: false
      t.string :witness
      t.string :contentions
      t.string :evidence
      t.string :comments_for_attorney
      t.string :military_service
    end

    create_table :hearing_worksheet_issues do |t|
      t.belongs_to :issue, null: false
      t.belongs_to :hearing_worksheet, null: false
      t.integer :status
      t.boolean :reopen, default: false
      t.boolean :vha, default: false
    end

  end
end
