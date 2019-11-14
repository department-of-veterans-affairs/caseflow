class CreateVirtualHearingEstablishments < ActiveRecord::Migration[5.1]
  def change
    create_table :virtual_hearing_establishments do |t|
      t.belongs_to :virtual_hearing, null: false, comment: "Virtual Hearing the conference is being established for."
      t.datetime :last_submitted_at, comment: "Async timestamp for most recent job start."
      t.datetime :submitted_at, comment: "Async timestamp for initial job start."
      t.datetime :attempted_at, comment: "Async timestamp for most recent attempt to run."
      t.datetime :processed_at, comment: "Timestamp for when the virtual hearing was successfully processed."
      t.datetime :canceled_at, comment: "Timestamp when job was abandoned."
      t.string :error, comment: "Async any error message from most recent failed attempt to run."
      t.datetime "created_at", null: false, comment: "Automatic timestamp when row was created."
      t.datetime "updated_at", null: false, comment: "Timestamp when record was last updated."
    end
  end
end
