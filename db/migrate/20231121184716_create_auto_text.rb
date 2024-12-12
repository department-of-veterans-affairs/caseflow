class CreateAutoText < ActiveRecord::Migration[6.1]
  def change
    create_table :auto_texts do |t|
      t.string :name
    end
  end
end
