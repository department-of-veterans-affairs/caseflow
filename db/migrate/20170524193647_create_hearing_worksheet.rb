class CreateHearingWorksheet < ActiveRecord::Migration
  def change
    create_table :hearing_worksheets do |t|
      t.belongs_to :hearing
      t.string :witness
      t.string :contentions
      t.string :evidence
      t.string :comments
      t.string :military_service
    end

    create_table :hearing_worksheet_issues do |t|
      t.belongs_to :issue
      t.belongs_to :hearing_worksheet
      t.string :status
      t.string :reopen
      t.string :vha
    end

  end
end
