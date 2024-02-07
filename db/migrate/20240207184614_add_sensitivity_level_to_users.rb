class AddSensitivityLevelToUsers < Caseflow::Migration
  def change
    add_column :users, :sensitivity_level, :string
  end
end
