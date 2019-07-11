class AddCreatedAtAndUpdatedAtToLegacyHearings < ActiveRecord::Migration[5.1]
  def change
    add_timestamps :legacy_hearings, null: true
  end
end
