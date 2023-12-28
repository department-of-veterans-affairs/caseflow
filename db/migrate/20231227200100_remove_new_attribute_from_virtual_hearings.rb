class RemoveNewAttributeFromVirtualHearings < ActiveRecord::Migration[5.2]
  def change
    remove_column :virtual_hearings, :new_attribute, :string
  end
end
