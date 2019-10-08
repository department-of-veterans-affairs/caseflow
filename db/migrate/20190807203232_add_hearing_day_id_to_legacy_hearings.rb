class AddHearingDayIdToLegacyHearings < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_reference(
      :legacy_hearings,
      :hearing_day,
      foreign_key: { to_table: :hearing_days },
      comment: "The hearing day the hearing will take place on",
      index: false
    )

    add_index :legacy_hearings, :hearing_day_id, algorithm: :concurrently
  end
end
