class AddCreatedAtAndUpdatedAtToHearings < ActiveRecord::Migration[5.1]
  def change
    add_timestamps :hearings, null: true
  end
end
