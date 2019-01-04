class CreateAmaHearings < ActiveRecord::Migration[5.1]
  def change
    create_table :hearings do |t|
      t.uuid    :uuid, null: false, default: "uuid_generate_v4()"
      t.integer :hearing_day_id, null: false
      t.integer :appeal_id, null: false
      t.integer :judge_id
      t.boolean :evidence_window_waived
      t.boolean :transcript_requested
      t.string  :notes
      t.string  :disposition
      t.string  :witness
      t.string  :military_service
      t.boolean :prepped
      t.text    :summary
    end
  end
end
