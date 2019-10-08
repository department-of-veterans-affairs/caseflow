class AddVeteranNameToCachedAppealAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_appeal_attributes, :veteran_name, :string, comment: "'LastName, FirstName' of the veteran"
  end
end
