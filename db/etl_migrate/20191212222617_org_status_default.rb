class OrgStatusDefault < ActiveRecord::Migration[5.1]
  def up
    change_column_default :organizations, :status, "active"
  end

  def down
    change_column_default :organizations, :status, nil
  end
end
