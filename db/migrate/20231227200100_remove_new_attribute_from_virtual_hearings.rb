class RemoveNewAttributeFromVirtualHearings < ActiveRecord::Migration[5.2]
  def up
    VirtualHearing.ignored_columns = ["new_attribute"]
    safety_assured { remove_column :virtual_hearings, :new_attribute, :string }
  end

  def down
    add_column :virtual_hearings, :new_attribute, :string
    VirtualHearing.reset_ignored_columns
  end
end
