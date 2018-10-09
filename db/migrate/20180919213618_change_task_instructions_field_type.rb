class ChangeTaskInstructionsFieldType < ActiveRecord::Migration[5.1]
  def change
    change_column :tasks, :instructions, :text, array: true, default: [], using: "(string_to_array(instructions, ','))"
  end
end
