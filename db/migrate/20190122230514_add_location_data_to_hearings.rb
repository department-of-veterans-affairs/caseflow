class AddLocationDataToHearings < ActiveRecord::Migration[5.1]
  def change
    add_column :hearings, :regional_offce, :string
    add_column :hearings, :location, :string
  end
end
