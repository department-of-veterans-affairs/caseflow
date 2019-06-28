class AddVeteranSsnColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :veterans, :ssn, :string
  end
end
