class UpdateLegacyHearingIncrement < ActiveRecord::Migration[5.1]
  def change
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE legacy_hearings_id_seq RESTART WITH 70000;")
  end
end
