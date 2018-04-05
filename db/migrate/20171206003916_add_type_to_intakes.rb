class AddTypeToIntakes < ActiveRecord::Migration[5.1]
  def change
    add_column :intakes, :type, :string
  end
end
