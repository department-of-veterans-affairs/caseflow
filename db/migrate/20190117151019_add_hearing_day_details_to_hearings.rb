class AddHearingDayDetailsToHearings < ActiveRecord::Migration[5.1]
  create_table :transcriptions do |t|
    t.belongs_to :hearing, index: true
    t.string :task_number
    t.string :transcriber
    t.date :sent_to_transcriber_date
    t.date :expected_return_date
    t.date :uploaded_to_vbms_date
    t.string :problem_type
    t.date :problem_notice_sent_date
    t.string :requested_remedy
    t.boolean :copy_requested
    t.date :copy_sent_date
  end

  def change
    add_column :hearings, :bva_poc, :string
    add_column :hearings, :room, :string
  end
end
