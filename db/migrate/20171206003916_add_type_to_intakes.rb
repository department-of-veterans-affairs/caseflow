class AddTypeToIntakes < ActiveRecord::Migration
  def change
    add_column :intakes, :type, :string
  end
end
