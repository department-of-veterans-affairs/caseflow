class AddRegionalOfficeToVeteran < ActiveRecord::Migration[5.1]
  def change
    add_column :veterans, :closest_regional_office, :string
  end
end
