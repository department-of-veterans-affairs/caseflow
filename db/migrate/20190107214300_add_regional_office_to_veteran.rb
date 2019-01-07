class AddRegionalOfficeToVeteran < ActiveRecord::Migration[5.1]
  def change
    add_column :veterans, :hearing_regional_office, :string
  end
end
