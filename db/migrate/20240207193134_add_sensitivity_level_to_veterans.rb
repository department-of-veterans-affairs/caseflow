class AddSensitivityLevelToVeterans < Caseflow::Migration
  def change
    add_column :veterans, :sensitivity_level, :string
  end
end
